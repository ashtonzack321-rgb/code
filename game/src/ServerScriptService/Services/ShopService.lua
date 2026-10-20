--[[
	ShopService: the General Store (treadmill tiers, Spurs, pen slots).

	The client calls Remotes.Shop:InvokeServer(action, arg) and gets back ok, message.
	  "BuyTreadmill" tier    "BuySpur" spurId    "EquipSpur" spurId ("" = none)    "BuyPenSlot"
	All rules live in Economy; this file only checks the arguments, rate-limits and saves.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Economy = require(Shared:WaitForChild("Economy"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local Remotes = require(Services:WaitForChild("Remotes"))

local ShopService = {}

local MIN_SECONDS_BETWEEN_REQUESTS = 0.15
local lastRequest = {}

local ACTIONS = {
	BuyTreadmill = function(data, arg)
		if type(arg) ~= "number" then
			return false, "Bad request"
		end
		local ok, reason = Economy.buyTreadmill(data, math.floor(arg))
		if ok then
			local tier = GameConfig.Treadmill.Tiers[data.TreadmillTier]
			return true, string.format("%s treadmill! +%s Speed per step", tier.name, NumberFormat.short(tier.speedPerStep))
		end
		return false, reason
	end,
	BuySpur = function(data, arg)
		if type(arg) ~= "string" then
			return false, "Bad request"
		end
		local ok, reason = Economy.buySpur(data, arg)
		if ok then
			local spur = Economy.SpursById[arg]
			return true, string.format("%s! Treadmill gains x%s", spur.name, tostring(spur.multiplier))
		end
		return false, reason
	end,
	EquipSpur = function(data, arg)
		if type(arg) ~= "string" then
			return false, "Bad request"
		end
		local ok, reason = Economy.equipSpur(data, arg)
		if ok then
			local spur = Economy.SpursById[arg]
			return true, spur and (spur.name .. " equipped") or "Spurs taken off"
		end
		return false, reason
	end,
	BuyPenSlot = function(data)
		local ok, reason = Economy.buyPenSlot(data)
		if ok then
			return true, string.format("Pen upgraded: %d slots", Economy.penSlots(data))
		end
		return false, reason
	end,
}

function ShopService.start()
	Remotes.Shop.OnServerInvoke = function(player, action, arg)
		local now = os.clock()
		if lastRequest[player] and now - lastRequest[player] < MIN_SECONDS_BETWEEN_REQUESTS then
			return false, "Slow down"
		end
		lastRequest[player] = now
		local handler = type(action) == "string" and ACTIONS[action]
		if not handler then
			return false, "Bad request"
		end
		local ok, message = DataService.update(player, function(data)
			return handler(data, arg)
		end)
		Remotes.notify(player, message or "", ok and "good" or "bad")
		return ok == true, message
	end
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return ShopService
