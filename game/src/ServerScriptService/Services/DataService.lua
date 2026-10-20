--[[
	DataService: loads, holds and saves every player's save table.

	* One DataStore key per player ("u_<UserId>"), written only with UpdateAsync.
	* Session lock: the save records which server owns it (JobId + time). Another server that
	  joins while the lock is fresh waits and retries; a lock older than
	  GameConfig.Data.SessionLockSeconds is treated as abandoned (that server crashed).
	* Autosave every GameConfig.Data.AutosaveSeconds, a save on leave and on shutdown.
	* In Studio without "Enable Studio Access to API Services", the DataStore calls fail;
	  the player then plays on a fresh in-memory save that is never written (a warning says so).

	Other services read and change data through DataService.get(player) and then call
	DataService.changed(player) so the HUD attributes refresh.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Economy = require(Shared:WaitForChild("Economy"))

local DataService = {}

local sessions = {}       -- [player] = { data =, saveable =, dirty = }
local loadedCallbacks = {}
local changedCallbacks = {}
local store = nil
local jobId = game.JobId ~= "" and game.JobId or ("studio-" .. tostring(math.random(1, 1e9)))

local function keyFor(player)
	return "u_" .. player.UserId
end

local function tryStore()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.Data.StoreName)
	end)
	if ok then
		return result
	end
	warn("[DataService] DataStores unavailable, progress will NOT be saved: " .. tostring(result))
	return nil
end

-- Returns data, saveable. Takes the session lock.
local function load(player)
	if not store then
		return Economy.newData(), false
	end
	local key = keyFor(player)
	for attempt = 1, GameConfig.Data.LoadRetries do
		local lockedByOther = false
		local ok, result = pcall(function()
			return store:UpdateAsync(key, function(saved)
				saved = type(saved) == "table" and saved or { Data = nil }
				local lock = saved.Lock
				-- Studio is a single session, so a lock there is always left over from the last playtest
				if lock and lock.JobId ~= jobId and os.time() - (lock.Time or 0) < GameConfig.Data.SessionLockSeconds
					and attempt < GameConfig.Data.LoadRetries and not RunService:IsStudio() then
					lockedByOther = true
					return nil -- leave the save untouched
				end
				saved.Lock = { JobId = jobId, Time = os.time() }
				return saved
			end)
		end)
		if ok and not lockedByOther then
			local data = Economy.reconcile(result and result.Data)
			return data, true
		end
		if not ok then
			warn(string.format("[DataService] load %s failed (try %d): %s", player.Name, attempt, tostring(result)))
			if string.find(tostring(result), "API", 1, true) or string.find(tostring(result), "Studio", 1, true) then
				warn("[DataService] Studio has no API access: playing on an unsaved session. "
					.. "Turn on Game Settings > Security > Enable Studio Access to API Services to test saving.")
				return Economy.newData(), false
			end
		end
		task.wait(attempt * 2)
		if not player.Parent then
			return nil, false
		end
	end
	warn("[DataService] could not load " .. player.Name .. "; using an unsaved session")
	return Economy.newData(), false
end

local function save(player, release)
	local session = sessions[player]
	if not session or not session.saveable or not store then
		return true
	end
	session.data.LastOnline = os.time()
	local snapshot = Economy.serialize(session.data)
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function(saved)
			saved = type(saved) == "table" and saved or {}
			if saved.Lock and saved.Lock.JobId ~= jobId then
				return nil -- another server took over; never overwrite its newer data
			end
			saved.Data = snapshot
			saved.Lock = (not release) and { JobId = jobId, Time = os.time() } or nil
			return saved
		end)
	end)
	if not ok then
		warn("[DataService] save " .. player.Name .. " failed: " .. tostring(err))
	end
	return ok
end

function DataService.get(player)
	local session = sessions[player]
	return session and session.data or nil
end

function DataService.isLoaded(player)
	return sessions[player] ~= nil
end

-- fn(player, data) runs once a player's data is loaded (now, if it already is).
function DataService.onLoaded(fn)
	table.insert(loadedCallbacks, fn)
	for player, session in pairs(sessions) do
		task.spawn(fn, player, session.data)
	end
end

-- fn(player, data) runs after any service changes a player's data.
function DataService.onChanged(fn)
	table.insert(changedCallbacks, fn)
end

function DataService.changed(player)
	local session = sessions[player]
	if not session then
		return
	end
	for _, fn in ipairs(changedCallbacks) do
		fn(player, session.data)
	end
end

-- Runs fn(data) for a loaded player, then fires changed. Returns what fn returns.
function DataService.update(player, fn)
	local data = DataService.get(player)
	if not data then
		return false, "Still loading"
	end
	local a, b = fn(data)
	DataService.changed(player)
	return a, b
end

local function onPlayerAdded(player)
	local data, saveable = load(player)
	if not data or not player.Parent then
		return
	end
	sessions[player] = { data = data, saveable = saveable }
	-- "OFFLINE CLAIM!": pay for the time away; the HUD shows it from this attribute
	local offline = Economy.claimOffline(data, os.time())
	if offline > 0 then
		player:SetAttribute("OfflineClaim", offline)
	end
	for _, fn in ipairs(loadedCallbacks) do
		task.spawn(fn, player, data)
	end
	DataService.changed(player)
end

local function onPlayerRemoving(player)
	if sessions[player] then
		save(player, true)
		sessions[player] = nil
	end
end

function DataService.start()
	store = tryStore()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(GameConfig.Data.AutosaveSeconds)
			for player in pairs(sessions) do
				task.spawn(save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local pending = 0
		for player in pairs(sessions) do
			pending = pending + 1
			task.spawn(function()
				save(player, true)
				pending = pending - 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
