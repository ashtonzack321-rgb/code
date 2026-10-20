--[[
	SpeedService: treadmill training and the Speed -> WalkSpeed curve.

	* Standing on the belt of YOUR OWN treadmill gives one step every
	  GameConfig.Treadmill.StepSeconds: + tier Speed x Spur multiplier (AFK works, as in SAE).
	  The server checks the position itself, so there is no remote a cheater could spam.
	* WalkSpeed follows Economy.walkSpeed (MAP_SPEC section 2) and updates whenever Speed changes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Economy = require(Shared:WaitForChild("Economy"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RanchService = require(Services:WaitForChild("RanchService"))
local MapUtil = require(Services:WaitForChild("MapUtil"))
local Remotes = require(Services:WaitForChild("Remotes"))

local SpeedService = {}

-- Extra multipliers a player can have on top of the walk curve (Fast Horse pass, towing ...)
local walkMultipliers = {}  -- [player] = { [reason] = multiplier }

local function belt(player)
	local plot = RanchService.plot(player)
	local treadmill = plot and plot:FindFirstChild("Treadmill")
	return treadmill and treadmill:FindFirstChild("Belt")
end

-- On the belt: inside its footprint (with a little slack) and no more than 7 studs above it.
local function isOnBelt(beltPart, root)
	local p = beltPart.CFrame:PointToObjectSpace(root.Position)
	local half = beltPart.Size / 2
	return math.abs(p.X) <= half.X + 0.5 and math.abs(p.Z) <= half.Z + 0.5 and p.Y >= 0 and p.Y <= 7
end

function SpeedService.applyWalkSpeed(player)
	local data = DataService.get(player)
	local humanoid = MapUtil.humanoid(player)
	if not data or not humanoid then
		return
	end
	local ws = Economy.walkSpeed(data.Speed)
	for _, multiplier in pairs(walkMultipliers[player] or {}) do
		ws = ws * multiplier
	end
	humanoid.WalkSpeed = ws
	player:SetAttribute("WalkSpeed", math.floor(ws * 10 + 0.5) / 10)
end

-- reason = "Tow", "FastHorse" ...; multiplier nil removes it.
function SpeedService.setWalkMultiplier(player, reason, multiplier)
	walkMultipliers[player] = walkMultipliers[player] or {}
	walkMultipliers[player][reason] = multiplier
	SpeedService.applyWalkSpeed(player)
end

-- Treadmill boosts (2x Treadmill events, passes) plug in here later.
function SpeedService.stepBoost(player)
	return 1
end

-- Players who may not train right now (towing a beast: Core Loop section 3.4)
local blocked = {}  -- [player] = { [reason] = true }

function SpeedService.blockTraining(player, reason, isBlocked)
	blocked[player] = blocked[player] or {}
	blocked[player][reason] = isBlocked or nil
end

local function canTrain(player)
	return next(blocked[player] or {}) == nil
end

function SpeedService.start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			SpeedService.applyWalkSpeed(player)
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			SpeedService.applyWalkSpeed(player)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		walkMultipliers[player] = nil
		blocked[player] = nil
	end)

	local lastSpeed = {}
	DataService.onChanged(function(player, data)
		if lastSpeed[player] ~= data.Speed then
			lastSpeed[player] = data.Speed
			SpeedService.applyWalkSpeed(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSpeed[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(GameConfig.Treadmill.StepSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.get(player)
				local root = MapUtil.rootPart(player)
				local humanoid = MapUtil.humanoid(player)
				local beltPart = belt(player)
				if data and root and humanoid and humanoid.Health > 0 and beltPart and canTrain(player)
					and isOnBelt(beltPart, root) then
					local gain = Economy.applyStep(data, SpeedService.stepBoost(player))
					DataService.changed(player)
					Remotes.TreadmillStep:FireClient(player, gain, Economy.spurMultiplier(data))
				end
			end
		end
	end)
end

return SpeedService
