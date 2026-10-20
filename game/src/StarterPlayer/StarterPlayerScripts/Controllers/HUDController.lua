--[[
	HUDController: the always-on HUD from the Town HUD mockup.
	  * top centre: cash and $/s
	  * bottom left: Speed, WalkSpeed and the next area's sign
	  * left rail: SHOP button
	  * treadmill step popups ("+30 x 3 SPUR") and toasts from Remotes.Notify
	Everything it shows comes from player attributes written by StatsService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared:WaitForChild("Economy"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = require(script.Parent:WaitForChild("UI"))

local HUDController = {}

local player = Players.LocalPlayer
local gui
local cashLabel, incomeLabel, speedLabel, nextLabel
local toastHolder, popHolder

local function build()
	gui = UI.new("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- Cash (top centre)
	local cash = UI.panel({
		Name = "Cash",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0, 260, 0, 74),
		Parent = gui,
	})
	cashLabel = UI.text("$0", {
		Size = UDim2.new(0.92, 0, 0.6, 0),
		Position = UDim2.new(0.04, 0, 0.04, 0),
		TextColor3 = UI.Colors.Cash,
		Parent = cash,
	})
	incomeLabel = UI.text("+$0/s", {
		Size = UDim2.new(0.92, 0, 0.32, 0),
		Position = UDim2.new(0.04, 0, 0.64, 0),
		Parent = cash,
	})

	-- Speed (bottom left)
	local speed = UI.panel({
		Name = "Speed",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.new(0, 270, 0, 96),
		BackgroundColor3 = UI.Colors.WoodDark,
		Parent = gui,
	})
	UI.text("SPEED", { Size = UDim2.new(0.4, 0, 0.3, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = speed })
	speedLabel = UI.text("0", { Size = UDim2.new(0.9, 0, 0.38, 0), Position = UDim2.new(0.05, 0, 0.3, 0),
		TextColor3 = UI.Colors.Speed, TextXAlignment = Enum.TextXAlignment.Left, Parent = speed })
	nextLabel = UI.text("", { Size = UDim2.new(0.9, 0, 0.22, 0), Position = UDim2.new(0.05, 0, 0.72, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = speed })

	-- Left rail
	local rail = UI.new("Frame", {
		Name = "Rail",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.45, 0),
		Size = UDim2.new(0, 80, 0, 260),
		Parent = gui,
	}, { UI.new("UIListLayout", { Padding = UDim.new(0, 10) }) })
	HUDController.shopButton = UI.button("SHOP", UI.Colors.Gold, { Name = "Shop", Size = UDim2.new(0, 76, 0, 76), Parent = rail })

	toastHolder = UI.new("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 96),
		Size = UDim2.new(0, 520, 0, 140),
		Parent = gui,
	}, { UI.new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })

	popHolder = UI.new("Frame", {
		Name = "Pops",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = gui,
	})
end

local function refresh()
	local cash = player:GetAttribute("Cash") or 0
	local income = player:GetAttribute("Income") or 0
	local speed = player:GetAttribute("Speed") or 0
	cashLabel.Text = NumberFormat.cash(cash)
	incomeLabel.Text = "+" .. NumberFormat.cash(income) .. "/s"
	speedLabel.Text = NumberFormat.short(math.floor(speed))
	local nextArea = Economy.nextArea(speed)
	if nextArea then
		nextLabel.Text = "NEXT: " .. string.upper(nextArea.name) .. " \u{00B7} " .. NumberFormat.short(nextArea.speedRequired)
	else
		nextLabel.Text = "EVERY AREA UNLOCKED!"
	end
end

function HUDController.toast(text, kind)
	if not text or text == "" then
		return
	end
	local color = kind == "good" and UI.Colors.Green or (kind == "bad" and UI.Colors.Red or UI.Colors.WoodDark)
	local toast = UI.panel({ BackgroundColor3 = color, Size = UDim2.new(0, 460, 0, 40), Parent = toastHolder })
	UI.text(text, { Size = UDim2.new(0.94, 0, 0.8, 0), Position = UDim2.new(0.03, 0, 0.1, 0), Parent = toast })
	task.delay(2.5, function()
		toast:Destroy()
	end)
end

local function stepPop(gain, multiplier)
	local text = "+" .. NumberFormat.short(gain) .. " SPEED"
	if multiplier and multiplier > 1 then
		text = text .. "  (x" .. tostring(multiplier) .. " SPUR)"
	end
	local x = 0.5 + (math.random() - 0.5) * 0.12
	local label = UI.text(text, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(x, 0, 0.62, 0),
		Size = UDim2.new(0, 260, 0, 40),
		TextColor3 = UI.Colors.Speed,
		Parent = popHolder,
	})
	local tween = TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(x, 0, 0.5, 0),
		TextTransparency = 1,
	})
	tween:Play()
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(0.9), { Transparency = 1 }):Play()
	end
	tween.Completed:Connect(function()
		label:Destroy()
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
end

return HUDController
