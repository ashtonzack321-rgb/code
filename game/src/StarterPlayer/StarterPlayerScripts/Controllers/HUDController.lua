--[[
	HUDController: the always-on HUD, laid out like Steal An Egg's.
	  * left: money stack icon + big green italic cash ("$43,931"), "+$1/s" under it
	  * left rail: icon buttons with gradient labels (Featured, Speed, Money, Index)
	  * bottom left: shoe icon + Speed, and the next area's sign
	  * "+2 Speed" treadmill popups, text-only toasts, and the area-name banner
	    ("CACTUS CANYON" in yellow, like Steal An Egg's "HALLOWEEN EGG")
	Everything it shows comes from player attributes written by StatsService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Economy = require(Shared:WaitForChild("Economy"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = require(script.Parent:WaitForChild("UI"))

local HUDController = {}

local player = Players.LocalPlayer
local gui
local cashLabel, incomeLabel, speedLabel, nextLabel
local toastHolder, popHolder, banner

HUDController.railButtons = {}

-- name, icon key, label tint
local RAIL = {
	{ "Featured", "Featured", UI.Tints.Featured },
	{ "Speed", "Speed", UI.Tints.Blue },
	{ "Money", "Money", UI.Tints.Green },
	{ "Index", "Index", UI.Tints.Peach },
}

local function railButton(parent, order, name, icon, tint)
	local button = UI.new("TextButton", {
		Name = name,
		Text = "",
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Size = UDim2.new(0, 96, 0, 92),
		Parent = parent,
	})
	UI.icon(icon, { size = UDim2.new(0, 66, 0, 66), position = UDim2.new(0.5, 0, 0, 0), anchor = Vector2.new(0.5, 0), parent = button })
	local label = UI.text(name, {
		name = "Label",
		anchor = Vector2.new(0.5, 0),
		size = UDim2.new(0, 120, 0, 26),
		position = UDim2.new(0.5, 0, 0, 58),
		maxSize = 21,
		stroke = 2.8,
		z = 3,
		parent = button,
	})
	UI.tint(label, tint)
	UI.pressable(button)
	return button
end

local function build()
	gui = UI.screen("HUD", 1)
	UI.autoScale(gui)

	-- Cash: money stack + green italic number (top of the left column)
	local cash = UI.new("Frame", {
		Name = "Cash",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 96),
		Size = UDim2.new(0, 360, 0, 52),
		Parent = gui,
	})
	UI.icon(GameConfig.Icons.Money, { size = UDim2.new(0, 76, 0, 52), parent = cash })
	cashLabel = UI.text("$0", {
		name = "Amount",
		italic = true,
		color = UI.Colors.CashGreen,
		align = "Left",
		size = UDim2.new(1, -86, 1, 0),
		position = UDim2.new(0, 86, 0, 0),
		stroke = 4,
		parent = cash,
	})
	incomeLabel = UI.text("+$0/s", {
		name = "Income",
		italic = true,
		align = "Left",
		size = UDim2.new(0, 200, 0, 24),
		position = UDim2.new(0, 78, 0, 148),
		stroke = 2.5,
		parent = gui,
	})

	-- Left rail
	local rail = UI.new("Frame", {
		Name = "Rail",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 186),
		Size = UDim2.new(0, 96, 0, 4 * 98),
		Parent = gui,
	}, { UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	for i, entry in ipairs(RAIL) do
		HUDController.railButtons[entry[1]] = railButton(rail, i, entry[1], GameConfig.Icons[entry[2]], entry[3])
	end

	-- Speed (bottom left)
	local speed = UI.new("Frame", {
		Name = "Speed",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.new(0, 380, 0, 76),
		Parent = gui,
	})
	nextLabel = UI.text("", {
		name = "Next",
		align = "Left",
		size = UDim2.new(1, 0, 0, 22),
		stroke = 2.5,
		parent = speed,
	})
	UI.icon(GameConfig.Icons.Speed, { size = UDim2.new(0, 48, 0, 48), position = UDim2.new(0, 0, 0, 26), parent = speed })
	speedLabel = UI.text("0", {
		name = "Amount",
		italic = true,
		color = UI.Colors.SpeedBlue,
		align = "Left",
		size = UDim2.new(1, -58, 0, 48),
		position = UDim2.new(0, 58, 0, 26),
		stroke = 4,
		parent = speed,
	})

	toastHolder = UI.new("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.new(0, 700, 0, 160),
		Parent = gui,
	}, { UI.new("UIListLayout", { Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder }) })

	popHolder = UI.new("Frame", {
		Name = "Pops",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = gui,
	})

	banner = UI.text("", {
		name = "AreaBanner",
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, -110),
		size = UDim2.new(0, 640, 0, 56),
		stroke = 4,
		parent = gui,
	})
	UI.tint(banner, UI.Tints.Gold)
	banner.Visible = false
end

local function refresh()
	local cash = player:GetAttribute("Cash") or 0
	local income = player:GetAttribute("Income") or 0
	local speed = player:GetAttribute("Speed") or 0
	cashLabel.Text = NumberFormat.cashLong(math.floor(cash))
	incomeLabel.Text = "+" .. NumberFormat.cash(income) .. "/s"
	speedLabel.Text = NumberFormat.commasShort(math.floor(speed))
	local nextArea = Economy.nextArea(speed)
	if nextArea then
		nextLabel.Text = "Next: " .. nextArea.name .. " (" .. NumberFormat.short(nextArea.speedRequired) .. " Speed)"
	else
		nextLabel.Text = "Every area unlocked!"
	end
end

local TOAST_COLORS = {
	good = Color3.fromRGB(90, 255, 90),
	bad = Color3.fromRGB(255, 80, 70),
	info = Color3.fromRGB(255, 255, 255),
}

local toastCount = 0

function HUDController.toast(text, kind)
	if not text or text == "" then
		return
	end
	toastCount = toastCount + 1
	local label = UI.text(text, { size = UDim2.new(1, 0, 0, 36), color = TOAST_COLORS[kind] or TOAST_COLORS.info, stroke = 3, parent = toastHolder })
	label.LayoutOrder = toastCount
	task.delay(2.2, function()
		local fade = TweenInfo.new(0.3)
		TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(label.Outline, fade, { Transparency = 1 }):Play()
		task.wait(0.3)
		label:Destroy()
	end)
end

-- Big yellow area name at the bottom centre, like Steal An Egg's "HALLOWEEN EGG".
local bannerTweens = {}

function HUDController.banner(text)
	for _, tween in ipairs(bannerTweens) do
		tween:Cancel()
	end
	bannerTweens = {}
	banner.Text = string.upper(text)
	banner.Visible = true
	banner.TextTransparency = 0
	banner.Outline.Transparency = 0
	local token = {}
	HUDController.bannerToken = token
	task.delay(2.5, function()
		if HUDController.bannerToken ~= token then
			return
		end
		local fade = TweenInfo.new(0.4)
		bannerTweens = {
			TweenService:Create(banner, fade, { TextTransparency = 1 }),
			TweenService:Create(banner.Outline, fade, { Transparency = 1 }),
		}
		for _, tween in ipairs(bannerTweens) do
			tween:Play()
		end
	end)
end

local function stepPop(gain, multiplier)
	local text = "+" .. NumberFormat.commasShort(math.floor(gain + 0.5)) .. " Speed"
	if multiplier and multiplier > 1 then
		text = text .. " (x" .. tostring(multiplier) .. ")"
	end
	local x = 0.5 + (math.random() - 0.5) * 0.14
	local label = UI.text(text, {
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.new(x, 0, 0.6, 0),
		size = UDim2.new(0, 300, 0, 40),
		stroke = 3,
		parent = popHolder,
	})
	UI.tint(label, UI.Tints.Cyan)
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, { Position = UDim2.new(x, 0, 0.48, 0), TextTransparency = 1 }):Play()
	local fade = TweenService:Create(label.Outline, info, { Transparency = 1 })
	fade:Play()
	fade.Completed:Connect(function()
		label:Destroy()
	end)
end

-- Shows the area banner when you walk into a new area (or back into Town).
local function watchAreas()
	local current = nil
	task.spawn(function()
		while true do
			task.wait(0.3)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local found = "Town"
				for _, bounds in ipairs(CollectionService:GetTagged("AreaBounds")) do
					if bounds:IsA("BasePart") then
						local p = bounds.CFrame:PointToObjectSpace(root.Position)
						local h = bounds.Size / 2
						if math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z then
							found = bounds:GetAttribute("AreaName") or found
						end
					end
				end
				if found ~= current then
					if current ~= nil then
						HUDController.banner(found)
					end
					current = found
				end
			end
		end
	end)
end

function HUDController.start()
	build()
	for _, name in ipairs({ "Cash", "Income", "Speed" }) do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
	Remotes:WaitForChild("Notify").OnClientEvent:Connect(HUDController.toast)
	Remotes:WaitForChild("TreadmillStep").OnClientEvent:Connect(stepPop)
	watchAreas()
end

return HUDController
