--[[
	ShopController: the General Store window (Shop mockup: Treadmills / Spurs / Ranch tabs).
	Opens from the HUD's SHOP button or by stepping onto the glowing ShopPad in Town.
	Buttons only ask the server (Remotes.Shop); the cards redraw from player attributes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Economy = require(Shared:WaitForChild("Economy"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local ShopRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop")

local UI = require(script.Parent:WaitForChild("UI"))

local ShopController = {}

local player = Players.LocalPlayer
local gui, window, grid
local tab = "Treadmills"
local tabButtons = {}
local busy = false

local function rarityColor(id)
	local rarity = Economy.Rarities[id]
	return rarity and UI.rgb(rarity.color) or UI.Colors.Grey
end

local function ask(action, arg)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		pcall(function()
			ShopRemote:InvokeServer(action, arg)
		end)
		busy = false
	end)
end

-- One card: title, stat line, note, and an action button (text, color, onClick or nil)
local function card(order, title, rarity, stat, note, buttonText, buttonColor, onClick)
	local frame = UI.panel({
		LayoutOrder = order,
		BackgroundColor3 = Color3.fromRGB(70, 44, 24),
		Parent = grid,
	})
	frame:FindFirstChildOfClass("UIStroke").Color = rarityColor(rarity)
	frame:FindFirstChildOfClass("UIStroke").Thickness = 5
	UI.text(title, { Size = UDim2.new(0.9, 0, 0.17, 0), Position = UDim2.new(0.05, 0, 0.05, 0), Parent = frame })
	UI.text(string.upper(rarity), { Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.23, 0),
		TextColor3 = rarityColor(rarity), Parent = frame })
	UI.text(stat, { Size = UDim2.new(0.9, 0, 0.2, 0), Position = UDim2.new(0.05, 0, 0.36, 0),
		TextColor3 = UI.Colors.Speed, Parent = frame })
	UI.text(note, { Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.58, 0), Parent = frame })
	local button = UI.button(buttonText, buttonColor, {
		Size = UDim2.new(0.84, 0, 0.2, 0),
		Position = UDim2.new(0.08, 0, 0.74, 0),
		AutoButtonColor = onClick ~= nil,
		Parent = frame,
	})
	if onClick then
		button.Activated:Connect(onClick)
	end
end

local function priceText(price)
	return price == 0 and "FREE" or NumberFormat.cash(price)
end

local function redraw()
	if not window or not window.Visible then
		return
	end
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for name, button in pairs(tabButtons) do
		button.BackgroundColor3 = name == tab and UI.Colors.Gold or UI.Colors.WoodDark
	end
	local cash = player:GetAttribute("Cash") or 0

	if tab == "Treadmills" then
		local current = player:GetAttribute("TreadmillTier") or 1
		for _, t in ipairs(GameConfig.Treadmill.Tiers) do
			local text, color, onClick = "LOCKED", UI.Colors.Grey, nil
			if t.tier <= current then
				text, color = (t.tier == current) and "EQUIPPED" or "OWNED", UI.Colors.WoodDark
			elseif t.tier == current + 1 then
				text = priceText(t.price)
				color = cash >= t.price and UI.Colors.Green or UI.Colors.Red
				onClick = function()
					ask("BuyTreadmill", t.tier)
				end
			end
			card(t.tier, t.name, t.rarity, "+" .. NumberFormat.short(t.speedPerStep) .. " / STEP",
				"Tier " .. t.tier .. (t.price > 0 and (" \u{00B7} " .. NumberFormat.cash(t.price)) or ""), text, color, onClick)
		end
	elseif tab == "Spurs" then
		local owned = {}
		for id in string.gmatch(player:GetAttribute("OwnedSpurs") or "", "[^,]+") do
			owned[id] = true
		end
		local equipped = player:GetAttribute("EquippedSpur") or ""
		for i, spur in ipairs(GameConfig.Spurs) do
			local text, color, onClick
			if spur.id == equipped then
				text, color = "EQUIPPED", UI.Colors.WoodDark
				onClick = function()
					ask("EquipSpur", "")
				end
			elseif owned[spur.id] then
				text, color = "EQUIP", UI.Colors.Speed
				onClick = function()
					ask("EquipSpur", spur.id)
				end
			else
				text = NumberFormat.cash(spur.price)
				color = cash >= spur.price and UI.Colors.Green or UI.Colors.Red
				onClick = function()
					ask("BuySpur", spur.id)
				end
			end
			local note = spur.robuxPrice and ("or R$ " .. spur.robuxPrice .. " (soon)") or "Multiplies treadmill gains"
			card(i, spur.name, spur.rarity, "x" .. tostring(spur.multiplier) .. " GAINS", note, text, color, onClick)
		end
	else
		local level = player:GetAttribute("PenLevel") or 1
		local slots = player:GetAttribute("PenSlots") or GameConfig.Pen.StartSlots
		local price = GameConfig.Pen.UpgradePrices[level]
		if slots >= GameConfig.Pen.MaxSlots or not price then
			card(1, "Pen Slot +1", "Legendary", slots .. " SLOTS", "Your pen is full size", "MAXED", UI.Colors.WoodDark, nil)
		else
			card(1, "Pen Slot +1", "Rare", slots .. " \u{2192} " .. (slots + 1) .. " SLOTS", "Room for one more beast",
				NumberFormat.cash(price), cash >= price and UI.Colors.Green or UI.Colors.Red, function()
					ask("BuyPenSlot")
				end)
		end
	end
end

-- Which prices the player can afford, as a string (it only changes when a button would)
local function affordKey(cash)
	local bits = {}
	for _, t in ipairs(GameConfig.Treadmill.Tiers) do
		table.insert(bits, cash >= t.price and "1" or "0")
	end
	for _, spur in ipairs(GameConfig.Spurs) do
		table.insert(bits, cash >= spur.price and "1" or "0")
	end
	for _, price in ipairs(GameConfig.Pen.UpgradePrices) do
		table.insert(bits, cash >= price and "1" or "0")
	end
	return table.concat(bits)
end

local function build()
	gui = UI.new("ScreenGui", {
		Name = "Shop",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	window = UI.panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.52, 0),
		Size = UDim2.new(0.8, 0, 0.74, 0),
		Visible = false,
		Parent = gui,
	}, nil)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(980, 600), Parent = window })
	UI.text("GENERAL STORE", { Size = UDim2.new(0.5, 0, 0.1, 0), Position = UDim2.new(0.25, 0, 0.02, 0),
		TextColor3 = UI.Colors.Gold, Parent = window })
	local close = UI.button("X", UI.Colors.Red, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.new(0, 48, 0, 48),
		Parent = window,
	})
	close.Activated:Connect(function()
		ShopController.close()
	end)

	local tabs = UI.new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.03, 0, 0.13, 0),
		Size = UDim2.new(0.94, 0, 0.09, 0),
		Parent = window,
	}, { UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })
	for i, name in ipairs({ "Treadmills", "Spurs", "Ranch" }) do
		local button = UI.button(string.upper(name), UI.Colors.WoodDark, { LayoutOrder = i, Size = UDim2.new(0.32, 0, 1, 0), Parent = tabs })
		button.Activated:Connect(function()
			tab = name
			redraw()
		end)
		tabButtons[name] = button
	end

	grid = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.03, 0, 0.25, 0),
		Size = UDim2.new(0.94, 0, 0.72, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		Parent = window,
	}, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0, 170, 0, 200), CellPadding = UDim2.new(0, 12, 0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6) }),
	})
end

function ShopController.open(whichTab)
	tab = whichTab or tab
	window.Visible = true
	redraw()
end

function ShopController.close()
	window.Visible = false
end

function ShopController.toggle()
	if window.Visible then
		ShopController.close()
	else
		ShopController.open()
	end
end

-- Opens the shop once each time you step onto a ShopPad (not every frame you stand on it).
local function watchPads()
	local wasOn = false
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local on = false
		for _, pad in ipairs(CollectionService:GetTagged("ShopPad")) do
			if pad:IsA("BasePart") then
				local offset = root.Position - pad.Position
				local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flat <= pad.Size.Y / 2 and math.abs(offset.Y) < 8 then
					on = true
				end
			end
		end
		if on and not wasOn then
			ShopController.open()
		end
		wasOn = on
	end)
end

function ShopController.start(hud)
	build()
	if hud and hud.shopButton then
		hud.shopButton.Activated:Connect(ShopController.toggle)
	end
	for _, name in ipairs({ "TreadmillTier", "OwnedSpurs", "EquippedSpur", "PenLevel" }) do
		player:GetAttributeChangedSignal(name):Connect(redraw)
	end
	-- Cash changes every second; only redraw when a price button would change colour.
	local lastKey = nil
	player:GetAttributeChangedSignal("Cash"):Connect(function()
		local key = affordKey(player:GetAttribute("Cash") or 0)
		if key ~= lastKey then
			lastKey = key
			redraw()
		end
	end)
	watchPads()
end

return ShopController
