--[[
	RanchService: the 7 ranch plots (MAP_SPEC section 5) and the idle income.

	* Gives each joining player a random free plot (MAP_SPEC 5.1: random, so the first to join
	  doesn't always get the plot nearest the gate), writes their name on the OwnerSign and
	  spawns them on their PlotSpawn, facing the street.
	* Shows the pen: unlocks slot pads up to the player's pen size (creating Slot11..Slot19 on
	  upgrades) and puts a placeholder beast with a name tag on every filled slot.
	* Pays pen income every GameConfig.Pen.IncomeTickSeconds.
	* Frees the plot again when the player leaves.

	The beast models are simple placeholders (a body, a head and a tag) until the real
	beast models exist; HerdService will reuse makeBeastModel for herds and towing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local AreasConfig = require(Shared:WaitForChild("AreasConfig"))
local Economy = require(Shared:WaitForChild("Economy"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local MapUtil = require(Services:WaitForChild("MapUtil"))

local RanchService = {}

local plots = {}          -- [plotIndex] = Plot model
local owners = {}         -- [plotIndex] = player
local plotOf = {}         -- [player] = plotIndex
local shown = {}          -- [player] = { penSlots =, beasts = { [slot] = key }, tier = }

local MUTATION_COLORS = {
	Silver = Color3.fromRGB(215, 222, 230),
	Golden = Color3.fromRGB(255, 200, 40),
	Rainbow = Color3.fromRGB(255, 90, 200),
}

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

----------------------------------------------------------------------------------------------
-- Beast placeholder model
----------------------------------------------------------------------------------------------
-- Montserrat Black (Roblox's Gotham family), the font Steal An Egg uses everywhere
local TAG_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 160, 30)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 60)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 230, 90)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(60, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 80, 255)),
})

local function tagLabel(parent, name, text, color, y, h)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, h, 0)
	label.Position = UDim2.new(0, 0, y, 0)
	label.FontFace = TAG_FONT
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

-- beast = { id, kg, mutation }. Returns a Model whose pivot is at its feet.
function RanchService.makeBeastModel(beast)
	local info = Economy.Beasts[beast.id]
	local rarity = Economy.Rarities[info.rarity]
	-- Size grows slowly with weight: 2 studs for a 1 kg owl, about 9 for a 2,500 kg wyrm
	local size = math.clamp(2 + 2 * math.log(1 + beast.kg, 10), 2, 14)
	local coat = MUTATION_COLORS[beast.mutation] or rgb(rarity.color)

	local model = Instance.new("Model")
	model.Name = info.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(size, size, size)
	body.Color = coat
	body.Material = beast.mutation == "None" and Enum.Material.SmoothPlastic or Enum.Material.Foil
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CFrame = CFrame.new(0, size / 2, 0)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(size * 0.55, size * 0.55, size * 0.55)
	head.Color = coat
	head.Material = body.Material
	head.Anchored = true
	head.CanCollide = false
	head.CanTouch = false
	head.CFrame = CFrame.new(0, size * 0.85, -size * 0.45)
	head.Parent = model
	pcall(function()
		body.CollisionGroup = "Beasts"
		head.CollisionGroup = "Beasts"
	end)

	local tag = Instance.new("BillboardGui")
	tag.Name = "BeastTag"
	tag.Size = UDim2.new(8, 0, 4, 0)
	tag.StudsOffsetWorldSpace = Vector3.new(0, size + 3, 0)
	tag.MaxDistance = 90
	tag.LightInfluence = 0
	-- Steal a Brainrot / Steal An Egg overhead order: big green $/s, then the name, then the rarity
	tagLabel(tag, "Income", NumberFormat.cashLong(Economy.beastIncome(beast)) .. "/s", Color3.fromRGB(24, 255, 24), 0, 0.3)
	tagLabel(tag, "BeastName", info.name, Color3.fromRGB(255, 255, 255), 0.3, 0.26)
	local rarityText = string.upper(info.rarity)
	if beast.mutation ~= "None" then
		rarityText = string.upper(beast.mutation) .. " " .. rarityText
	end
	local rarityLabel = tagLabel(tag, "Rarity", rarityText, rgb(rarity.color), 0.56, 0.24)
	if rarity.rainbowText or beast.mutation == "Rainbow" then
		rarityLabel.TextColor3 = Color3.new(1, 1, 1)
		local gradient = Instance.new("UIGradient")
		gradient.Color = RAINBOW
		gradient.Parent = rarityLabel
	end
	tagLabel(tag, "Kg", NumberFormat.commas(beast.kg) .. " kg", Color3.fromRGB(230, 230, 230), 0.8, 0.18)
	tag.Parent = body

	model.PrimaryPart = body
	model.WorldPivot = CFrame.new()
	return model
end

----------------------------------------------------------------------------------------------
-- Plot helpers
----------------------------------------------------------------------------------------------
local function ownerSign(plot)
	local gate = plot:FindFirstChild("Gate")
	local sign = gate and gate:FindFirstChild("OwnerSign")
	return sign and sign:FindFirstChild("SignFront")
end

local function setOwnerSign(plot, player)
	local gui = ownerSign(plot)
	if not gui then
		return
	end
	local line = gui:FindFirstChild("Line1")
	local headshot = gui:FindFirstChild("Headshot")
	if player then
		if line then
			line.Text = player.DisplayName .. "'s Ranch"
			line.Position = UDim2.new(0.2, 0, line.Position.Y.Scale, 0)
			line.Size = UDim2.new(0.78, 0, line.Size.Y.Scale, 0)
		end
		if headshot then
			local ok, image = pcall(function()
				return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			headshot.Image = ok and image or ""
			headshot.Visible = ok
		end
	else
		if line then
			line.Text = "FREE RANCH"
			line.Position = UDim2.new(0.03, 0, line.Position.Y.Scale, 0)
			line.Size = UDim2.new(0.94, 0, line.Size.Y.Scale, 0)
		end
		if headshot then
			headshot.Visible = false
			headshot.Image = ""
		end
	end
end

local function slotPad(plot, slot)
	local pen = plot:FindFirstChild("Pen")
	return pen and pen:FindFirstChild(string.format("Slot%02d", slot))
end

-- Pads 11..19 are not built with the map; clone Slot01 and move it to its layout spot.
local function ensurePad(plot, slot)
	local pad = slotPad(plot, slot)
	if pad then
		return pad
	end
	local first = slotPad(plot, 1)
	local layout = AreasConfig.Plots.SlotLayout
	if not first or not layout[slot] then
		return nil
	end
	pad = first:Clone()
	pad.Name = string.format("Slot%02d", slot)
	local dx = layout[slot][1] - layout[1][1]
	local dz = layout[slot][2] - layout[1][2]
	pad.CFrame = first.CFrame * CFrame.new(dx, 0, dz)
	pad:SetAttribute("SlotIndex", slot)
	pad.Parent = first.Parent
	return pad
end

local function styleSlot(pad, active)
	pad:SetAttribute("Active", active)
	pad.Material = active and Enum.Material.Sand or Enum.Material.SmoothPlastic
	pad.Color = active and Color3.fromRGB(222, 196, 120) or Color3.fromRGB(120, 120, 120)
	pad.Transparency = active and 0 or 0.5
	local label = pad:FindFirstChild("Label")
	if active and label then
		label:Destroy()
	elseif not active and not label then
		local gui = Instance.new("BillboardGui")
		gui.Name = "Label"
		gui.Size = UDim2.new(6, 0, 1.6, 0)
		gui.StudsOffset = Vector3.new(0, 2, 0)
		gui.MaxDistance = 80
		gui.LightInfluence = 0
		tagLabel(gui, "Line1", "LOCKED", Color3.fromRGB(255, 255, 255), 0, 1)
		gui.Parent = pad
	end
end

local function updateTreadmillSign(plot, tier)
	local treadmill = plot:FindFirstChild("Treadmill")
	local base = treadmill and treadmill:FindFirstChild("Base")
	if not base then
		return
	end
	treadmill:SetAttribute("Tier", tier)
	local info = GameConfig.Treadmill.Tiers[tier]
	MapUtil.setLines(base:FindFirstChild("TierDisplay"), {
		string.upper(info.name) .. " \u{00B7} TIER " .. tier,
		"+" .. NumberFormat.short(info.speedPerStep) .. " / step",
	})
end

local function beastFolder(player)
	local name = "Plot" .. tostring(plotOf[player])
	local root = MapUtil.runtimeFolder("PenBeasts")
	local folder = root:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = root
	end
	return folder
end

-- Brings the plot's pads, beasts and treadmill sign in line with the save data.
local function refreshPlot(player, data)
	local index = plotOf[player]
	local plot = index and plots[index]
	if not plot then
		return
	end
	local state = shown[player]
	local slots = Economy.penSlots(data)

	if state.penSlots ~= slots then
		local count = math.max(slots, AreasConfig.Plots.PenBuiltSlots)
		for slot = 1, count do
			local pad = ensurePad(plot, slot)
			if pad then
				styleSlot(pad, slot <= slots)
			end
		end
		plot:SetAttribute("PenLevel", data.PenLevel)
		state.penSlots = slots
	end

	local folder = beastFolder(player)
	for slot = 1, AreasConfig.Plots.PenMaxSlots do
		local beast = data.Pen[slot]
		local key = beast and (beast.id .. "|" .. beast.kg .. "|" .. beast.mutation) or nil
		if state.beasts[slot] ~= key then
			local old = folder:FindFirstChild("Slot" .. slot)
			if old then
				old:Destroy()
			end
			local pad = slotPad(plot, slot)
			if beast and pad then
				local model = RanchService.makeBeastModel(beast)
				model.Name = "Slot" .. slot
				local pivot = pad:FindFirstChild("BeastPivot")
				local at = pivot and pivot.WorldCFrame or pad.CFrame
				model:PivotTo(at)
				model.Parent = folder
			end
			if pad then
				pad:SetAttribute("Occupied", beast ~= nil)
			end
			state.beasts[slot] = key
		end
	end

	if state.tier ~= data.TreadmillTier then
		updateTreadmillSign(plot, data.TreadmillTier)
		state.tier = data.TreadmillTier
	end
end

local function spawnAtPlot(player, character)
	local index = plotOf[player]
	local plot = index and plots[index]
	local spawnPart = plot and plot:FindFirstChild("PlotSpawn")
	if not spawnPart then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	task.wait() -- let the default spawn finish, or it overrides us
	character:PivotTo(spawnPart.CFrame * CFrame.new(0, 3.5, 0))
end

local function assignPlot(player)
	local free = {}
	for index in pairs(plots) do
		if not owners[index] then
			table.insert(free, index)
		end
	end
	if #free == 0 then
		warn("[RanchService] no free plot for " .. player.Name)
		return nil
	end
	local index = free[math.random(1, #free)]
	owners[index] = player
	plotOf[player] = index
	shown[player] = { beasts = {} }
	local plot = plots[index]
	plot:SetAttribute("OwnerUserId", player.UserId)
	player:SetAttribute("PlotIndex", index)
	task.spawn(setOwnerSign, plot, player)
	return index
end

local function releasePlot(player)
	local index = plotOf[player]
	if not index then
		return
	end
	local plot = plots[index]
	local folder = MapUtil.runtimeFolder("PenBeasts"):FindFirstChild("Plot" .. index)
	if folder then
		folder:Destroy()
	end
	for slot = 1, AreasConfig.Plots.PenMaxSlots do
		local pad = slotPad(plot, slot)
		if pad then
			if slot > AreasConfig.Plots.PenBuiltSlots then
				pad:Destroy()
			else
				pad:SetAttribute("Occupied", false)
				styleSlot(pad, slot <= AreasConfig.Plots.PenStartSlots)
			end
		end
	end
	plot:SetAttribute("OwnerUserId", 0)
	plot:SetAttribute("PenLevel", 1)
	updateTreadmillSign(plot, 1)
	setOwnerSign(plot, nil)
	owners[index] = nil
	plotOf[player] = nil
	shown[player] = nil
end

----------------------------------------------------------------------------------------------
-- Public
----------------------------------------------------------------------------------------------
function RanchService.plotIndex(player)
	return plotOf[player]
end

function RanchService.plot(player)
	local index = plotOf[player]
	return index and plots[index] or nil
end

function RanchService.start()
	local map = MapUtil.waitForMap()
	for _, plot in ipairs(map:WaitForChild("Plots"):GetChildren()) do
		local index = plot:GetAttribute("PlotIndex")
		if index then
			plots[index] = plot
		end
	end

	local function onPlayer(player)
		if not assignPlot(player) then
			return
		end
		local data = DataService.get(player)
		if data then
			refreshPlot(player, data)
		end
		player.CharacterAdded:Connect(function(character)
			spawnAtPlot(player, character)
		end)
		if player.Character then
			task.spawn(spawnAtPlot, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(releasePlot)

	DataService.onChanged(function(player, data)
		if shown[player] then
			refreshPlot(player, data)
		end
	end)

	-- Income tick
	task.spawn(function()
		local interval = GameConfig.Pen.IncomeTickSeconds
		while true do
			task.wait(interval)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.get(player)
				if data and next(data.Pen) then
					Economy.payIncome(data, interval, RanchService.incomeMultiplier(player))
					DataService.changed(player)
				end
			end
		end
	end)
end

-- 2x Money pass and events plug in here later (MarketService, EventService).
function RanchService.incomeMultiplier(player)
	return 1
end

return RanchService
