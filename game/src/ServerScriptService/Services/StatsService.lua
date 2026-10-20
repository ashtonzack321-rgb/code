--[[
	StatsService: mirrors the save data into things the client and the player list can read.

	* Player attributes (the HUD and shop read these; clients can't change them on the server):
	    Cash, Speed, Income ($/s), TreadmillTier, EquippedSpur, OwnedSpurs ("Rusty,Iron"),
	    PenLevel, PenSlots, PenCount, Loaded
	* leaderstats: Cash and Speed, for the Roblox player list
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Economy = require(Shared:WaitForChild("Economy"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RanchService = require(Services:WaitForChild("RanchService"))

local StatsService = {}

local function leaderstat(player, name)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end
	local value = folder:FindFirstChild(name)
	if not value then
		value = Instance.new("NumberValue")
		value.Name = name
		value.Parent = folder
	end
	return value
end

local function sync(player, data)
	local owned = {}
	for _, spur in ipairs(GameConfig.Spurs) do
		if data.Spurs[spur.id] then
			table.insert(owned, spur.id)
		end
	end
	local count = 0
	for _ in pairs(data.Pen) do
		count = count + 1
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Speed", data.Speed)
	player:SetAttribute("Income", Economy.penIncome(data) * RanchService.incomeMultiplier(player))
	player:SetAttribute("TreadmillTier", data.TreadmillTier)
	player:SetAttribute("EquippedSpur", data.EquippedSpur)
	player:SetAttribute("OwnedSpurs", table.concat(owned, ","))
	player:SetAttribute("PenLevel", data.PenLevel)
	player:SetAttribute("PenSlots", Economy.penSlots(data))
	player:SetAttribute("PenCount", count)
	player:SetAttribute("Loaded", true)
	leaderstat(player, "Cash").Value = math.floor(data.Cash)
	leaderstat(player, "Speed").Value = math.floor(data.Speed)
end

function StatsService.start()
	DataService.onChanged(sync)
	Players.PlayerAdded:Connect(function(player)
		leaderstat(player, "Cash")
		leaderstat(player, "Speed")
	end)
end

return StatsService
