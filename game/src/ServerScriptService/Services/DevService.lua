--[[
	DevService: test helpers that exist ONLY in Studio (never in a live server).

	Creates ServerStorage.DevCommands (a BindableFunction). While playtesting, switch the
	Command Bar to the Server and run, for example:

	  game.ServerStorage.DevCommands:Invoke("cash", 1e6)                 -- +$1M for every player
	  game.ServerStorage.DevCommands:Invoke("speed", 10000)              -- +10K Speed
	  game.ServerStorage.DevCommands:Invoke("beast", "GoldenGoose", 12, "Golden")  -- id, kg, mutation
	  game.ServerStorage.DevCommands:Invoke("reset")                     -- fresh save (not written in Studio)

	An optional last argument picks one player by name; otherwise every player is changed.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Economy"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local DevService = {}

local function targets(name)
	if type(name) == "string" then
		local player = Players:FindFirstChild(name)
		return player and { player } or {}
	end
	return Players:GetPlayers()
end

local COMMANDS = {
	cash = function(data, amount)
		data.Cash = data.Cash + (tonumber(amount) or 0)
	end,
	speed = function(data, amount)
		data.Speed = data.Speed + (tonumber(amount) or 0)
	end,
	beast = function(data, id, kg, mutation)
		local slot, reason = Economy.addBeast(data, { id = id, kg = tonumber(kg), mutation = mutation })
		return slot ~= nil, reason
	end,
	reset = function(data)
		local fresh = Economy.newData()
		for key in pairs(data) do
			data[key] = nil
		end
		for key, value in pairs(fresh) do
			data[key] = value
		end
	end,
}

-- The player name is the argument after the command's own arguments.
local ARG_COUNT = { cash = 1, speed = 1, beast = 3, reset = 0 }

function DevService.start()
	if not RunService:IsStudio() then
		return
	end
	local fn = ServerStorage:FindFirstChild("DevCommands") or Instance.new("BindableFunction")
	fn.Name = "DevCommands"
	fn.OnInvoke = function(command, ...)
		local handler = COMMANDS[command]
		if not handler then
			return "unknown command; try cash, speed, beast, reset"
		end
		local args = table.pack(...)
		local changed = {}
		for _, player in ipairs(targets(args[ARG_COUNT[command] + 1])) do
			local ok, reason = DataService.update(player, function(data)
				return handler(data, table.unpack(args, 1, ARG_COUNT[command]))
			end)
			table.insert(changed, player.Name .. (ok == false and (" (" .. tostring(reason) .. ")") or ""))
		end
		return command .. ": " .. (#changed > 0 and table.concat(changed, ", ") or "no players")
	end
	fn.Parent = ServerStorage
end

return DevService
