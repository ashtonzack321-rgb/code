--[[
	IncomePops: Steal An Egg's "+$11" that floats up off every beast in YOUR pen each time
	the pen pays (GameConfig.Pen.IncomeTickSeconds). The amount is the beast model's "Income"
	attribute, set by RanchService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))

local UI = require(script.Parent:WaitForChild("UI"))

local IncomePops = {}

local player = Players.LocalPlayer
local RISE = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function pop(model)
	local body = model.PrimaryPart or model:FindFirstChild("Body")
	local income = model:GetAttribute("Income")
	if not body or not income or income <= 0 then
		return
	end
	local height = body.Size.Y
	local gui = Instance.new("BillboardGui")
	gui.Name = "IncomePop"
	gui.Size = UDim2.new(5, 0, 1.4, 0)
	gui.StudsOffsetWorldSpace = Vector3.new((math.random() - 0.5) * 1.5, height * 0.4, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Adornee = body
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.FontFace = UI.Font
	label.TextScaled = true
	label.Text = "+" .. NumberFormat.cashLong(income)
	label.TextColor3 = UI.Colors.CashGreen
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = body
	local start = gui.StudsOffsetWorldSpace
	TweenService:Create(gui, RISE, { StudsOffsetWorldSpace = start + Vector3.new(0, 3, 0) }):Play()
	local fade = TweenService:Create(label, RISE, { TextTransparency = 1, TextStrokeTransparency = 1 })
	fade:Play()
	fade.Completed:Connect(function()
		gui:Destroy()
	end)
end

function IncomePops.start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.Pen.IncomeTickSeconds)
			local index = player:GetAttribute("PlotIndex")
			local runtime = workspace:FindFirstChild("Runtime")
			local pens = runtime and runtime:FindFirstChild("PenBeasts")
			local mine = index and pens and pens:FindFirstChild("Plot" .. index)
			if mine then
				for _, model in ipairs(mine:GetChildren()) do
					if model:IsA("Model") then
						pop(model)
					end
				end
			end
		end
	end)
end

return IncomePops
