--[[
	Main: starts the gameplay services in order. Each service lives in ./Services and has a
	start() function. DataService starts last, so every other service is already listening
	when the first save loads.
]]

local Services = script.Parent:WaitForChild("Services")

local ORDER = { "RanchService", "SpeedService", "ShopService", "StatsService", "DevService", "DataService" }

for _, name in ipairs(ORDER) do
	local ok, err = pcall(function()
		require(Services:WaitForChild(name)).start()
	end)
	if not ok then
		warn("[Main] " .. name .. " failed to start: " .. tostring(err))
	end
end

print("[Main] Steal a Beast server started")
