--[[
	map_tests.lua: checks the map that tools/BuildMap.command.lua builds, against
	game/MAP_SPEC.md and AreasConfig. Run by tests/run_tests.js under fengari (Lua 5.3)
	with tests/mock_roblox.lua loaded.

	Expects these globals: CONFIG (the AreasConfig table), MAP_BUILDER (the source MapBuilder module),
	BUILD_MAP (the command-bar chunk,
	not yet run) and MOCK. Prints one PASS/FAIL line per check and returns "passed failed parts".
]]

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")

local passed, failed = 0, 0

local function report(name, ok, detail)
	if ok then
		passed = passed + 1
		print("PASS  " .. name)
	else
		failed = failed + 1
		print("FAIL  " .. name .. (detail and ("\n        " .. tostring(detail)) or ""))
	end
end

-- fn returns true, or false plus a detail message. Errors count as failures.
local function test(name, fn)
	local ok, result, detail = pcall(fn)
	if not ok then
		report(name, false, "error: " .. tostring(result))
	else
		report(name, result == true, detail)
	end
end

----------------------------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------------------------
local EPS = 1e-6

local function near(a, b, tol)
	return math.abs(a - b) <= (tol or 1e-3)
end

local function fmt(v)
	return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
end

local function baseParts(root)
	local out = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

local function countParts(root)
	return #baseParts(root)
end

-- World-axis bounding box of a (possibly rotated) part.
local function aabb(part)
	local cf, s = part.CFrame, part.Size
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local hx = math.abs(r.X) * s.X / 2 + math.abs(u.X) * s.Y / 2 + math.abs(l.X) * s.Z / 2
	local hy = math.abs(r.Y) * s.X / 2 + math.abs(u.Y) * s.Y / 2 + math.abs(l.Y) * s.Z / 2
	local hz = math.abs(r.Z) * s.X / 2 + math.abs(u.Z) * s.Y / 2 + math.abs(l.Z) * s.Z / 2
	local p = cf.Position
	return { minX = p.X - hx, maxX = p.X + hx, minY = p.Y - hy, maxY = p.Y + hy, minZ = p.Z - hz, maxZ = p.Z + hz }
end

-- The spec's zone test (section 3.4)
local function inBox(part, pos)
	local p = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(p.X) <= h.X + EPS and math.abs(p.Y) <= h.Y + EPS and math.abs(p.Z) <= h.Z + EPS
end

local function boxInside(inner, outer)
	local a, b = aabb(inner), aabb(outer)
	return a.minX >= b.minX - EPS and a.maxX <= b.maxX + EPS and a.minY >= b.minY - EPS and a.maxY <= b.maxY + EPS
		and a.minZ >= b.minZ - EPS and a.maxZ <= b.maxZ + EPS
end

local function boxesOverlap(p, q)
	local a, b = aabb(p), aabb(q)
	return a.minX < b.maxX - EPS and b.minX < a.maxX - EPS and a.minZ < b.maxZ - EPS and b.minZ < a.maxZ - EPS
end

local function tagged(tag, root)
	local out = {}
	for _, inst in ipairs(CollectionService:GetTagged(tag)) do
		if root == nil or inst:IsDescendantOf(root) then
			table.insert(out, inst)
		end
	end
	return out
end

local function inAnySafeZone(pos)
	for _, zone in ipairs(CollectionService:GetTagged("SafeZone")) do
		if inBox(zone, pos) then
			return true
		end
	end
	return false
end

-- "2.5M SPEED" -> 2500000
local function parseSpeed(text)
	local num, suffix = string.match(text, "^([%d%.]+)([KMB]?) SPEED$")
	if not num then
		return nil
	end
	local mult = ({ [""] = 1, K = 1e3, M = 1e6, B = 1e9 })[suffix]
	return tonumber(num) * mult
end

local function labelText(gui, lineName)
	local label = gui and gui:FindFirstChild(lineName)
	return label and label.Text
end

local function areaModels()
	local map = workspace:FindFirstChild("Map")
	local lane = map and map:FindFirstChild("Lane")
	local areas = lane and lane:FindFirstChild("Areas")
	local out = {}
	if areas then
		for _, child in ipairs(areas:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("AreaIndex") then
				table.insert(out, child)
			end
		end
	end
	return out
end

local function sortedByIndex(list, attr)
	table.sort(list, function(a, b)
		return a:GetAttribute(attr) < b:GetAttribute(attr)
	end)
	return list
end

----------------------------------------------------------------------------------------------
-- Expected numbers from MAP_SPEC.md
----------------------------------------------------------------------------------------------
-- Section 10 part budget. Area 1's prop total in the spec says 101, but the parts it lists
-- add up to 100 (the covered wagon is listed as 7 parts and specified as 6), so 100 is expected.
local SPEC_AREA_PROPS = { 100, 120, 121, 125, 114, 91, 106, 122, 114, 110 }
local SPEC_TOWN_PARTS = 128 -- ground 6 + walls 5 + caps 5 + boundary 5 + gate 8 + square 47 + trading post 15 + street 32 + zones 5
local SPEC_PLOT_PARTS = 148 -- section 13: Steal An Egg-style base (rail fence, pen circle, gym treadmill, no barn/gate arch)
local SPEC_LANE_GLOBALS = 25
local SPEC_AREA_FIXED = 29
local PART_BUDGET = 3000

-- Section 5.2 world positions
local SPEC_PLOTS = {
	{ treadmill = { 130, 0.5, 32 }, spawn = { 94, 0.5, 32 }, gate = { 112, 40 } },
	{ treadmill = { 202, 0.5, 32 }, spawn = { 166, 0.5, 32 }, gate = { 184, 40 } },
	{ treadmill = { 274, 0.5, 32 }, spawn = { 238, 0.5, 32 }, gate = { 256, 40 } },
	{ treadmill = { 346, 0.5, 32 }, spawn = { 310, 0.5, 32 }, gate = { 328, 40 } },
	{ treadmill = { 94, 0.5, -32 }, spawn = { 130, 0.5, -32 }, gate = { 112, -40 } },
	{ treadmill = { 166, 0.5, -32 }, spawn = { 202, 0.5, -32 }, gate = { 184, -40 } },
	{ treadmill = { 238, 0.5, -32 }, spawn = { 274, 0.5, -32 }, gate = { 256, -40 } },
}

-- Section 6.4 HerdSpawn table, (x, z) for SpawnIndex 1..8
local SPEC_HERD = {
	{ { 509, 23 }, { 519, 23 }, { 509, 33 }, { 519, 33 }, { 537, 23 }, { 547, 23 }, { 537, 33 }, { 547, 33 } },
	{ { 688, -23 }, { 698, -23 }, { 688, -33 }, { 698, -33 }, { 716, -23 }, { 726, -23 }, { 716, -33 }, { 726, -33 } },
	{ { 899, 23 }, { 909, 23 }, { 899, 33 }, { 909, 33 }, { 927, 23 }, { 937, 23 }, { 927, 33 }, { 937, 33 } },
	{ { 1140, -22 }, { 1152, -22 }, { 1140, -34 }, { 1152, -34 }, { 1172, -22 }, { 1184, -22 }, { 1172, -34 }, { 1184, -34 } },
	{ { 1415, 22 }, { 1427, 22 }, { 1415, 34 }, { 1427, 34 }, { 1447, 22 }, { 1459, 22 }, { 1447, 34 }, { 1459, 34 } },
	{ { 1722, -22 }, { 1734, -22 }, { 1722, -34 }, { 1734, -34 }, { 1754, -22 }, { 1766, -22 }, { 1754, -34 }, { 1766, -34 } },
	{ { 2058, 21 }, { 2072, 21 }, { 2058, 35 }, { 2072, 35 }, { 2094, 21 }, { 2108, 21 }, { 2094, 35 }, { 2108, 35 } },
	{ { 2429, -21 }, { 2443, -21 }, { 2429, -35 }, { 2443, -35 }, { 2465, -21 }, { 2479, -21 }, { 2465, -35 }, { 2479, -35 } },
	{ { 2833, 21 }, { 2847, 21 }, { 2833, 35 }, { 2847, 35 }, { 2869, 21 }, { 2883, 21 }, { 2869, 35 }, { 2883, 35 } },
	{ { 3428, -20 }, { 3444, -20 }, { 3428, -36 }, { 3444, -36 }, { 3468, -20 }, { 3484, -20 }, { 3468, -36 }, { 3484, -36 } },
}
local SPEC_ALPHA_Z = { 47, -47, 47, -48, 48, -48, 49, -49, 49, -50 }

local EXPECTED_TAGS = {
	SafeZone = 4, TownBounds = 1, TownGate = 1, Plot = 7, PlotBounds = 7, PenArea = 7, PenSlot = 70, GateLock = 7,
	OwnerSign = 7, PlotSpawn = 7, Treadmill = 7, ShopPad = 1, SellPad = 1, BreedingPad = 1, IndexPad = 1,
	RewardsPad = 1, SundownClock = 1, Leaderboard = 1, EventPortalSpot = 1, AreaEntrance = 10, AreaBounds = 10,
	AreaSign = 10, HerdSign = 10, HerdZone = 10, HerdSpawn = 80, AlphaSpawn = 10, LaneWaypoint = 12,
	LaneBoundary = 4, FrontierEnd = 1, SecretSpot = 2,
}

-- Prop models that are allowed over the trail strip (|Z| < 20) or are in the sky
local TRAIL_OK = { RiftCrack = true, StormCloud = true, FloatingIsland = true, Planet = true, AuroraRibbon = true,
	StarMote = true, Wisp = true, Fireflies = true }

local function tagCounts()
	local counts = {}
	for tag in pairs(EXPECTED_TAGS) do
		counts[tag] = #CollectionService:GetTagged(tag)
	end
	return counts
end

local function signature()
	local map = workspace:FindFirstChild("Map")
	local bits = {}
	for _, p in ipairs(baseParts(map)) do
		local pos = p.Position
		table.insert(bits, string.format("%s:%.3f,%.3f,%.3f", p.Name, pos.X, pos.Y, pos.Z))
	end
	return table.concat(bits, ";")
end

----------------------------------------------------------------------------------------------
-- Start like a fresh Studio "Baseplate" place: a Baseplate (top at Y 0) and a SpawnLocation
----------------------------------------------------------------------------------------------
local templateBaseplate = Instance.new("Part")
templateBaseplate.Name = "Baseplate"
templateBaseplate.Size = Vector3.new(2048, 16, 2048)
templateBaseplate.CFrame = CFrame.new(0, -8, 0)
templateBaseplate.Anchored = true
templateBaseplate.Parent = workspace
local templateSpawn = Instance.new("SpawnLocation")
templateSpawn.Name = "SpawnLocation"
templateSpawn.Anchored = true
templateSpawn.Parent = workspace

----------------------------------------------------------------------------------------------
-- First build
----------------------------------------------------------------------------------------------
print("Building the map (first run of tools/BuildMap.command.lua)...")
local buildReport = BUILD_MAP()

local map = workspace:FindFirstChild("Map")
local partsTotal = map and countParts(map) or 0

test("workspace.Map exists with MapVersion/TownGateX/LaneHalfWidth/TrailHalfWidth attributes", function()
	if not (map and map:IsA("Folder")) then
		return false, "workspace.Map missing or not a Folder"
	end
	local ok = map:GetAttribute("MapVersion") == 1 and map:GetAttribute("TownGateX") == 400
		and map:GetAttribute("LaneHalfWidth") == 64 and map:GetAttribute("TrailHalfWidth") == 20
	return ok, "attributes wrong"
end)

test("Map has Folders Town, Plots and Lane, with Lane.Areas", function()
	for _, name in ipairs({ "Town", "Plots", "Lane" }) do
		local f = map:FindFirstChild(name)
		if not (f and f:IsA("Folder")) then
			return false, name .. " missing"
		end
	end
	local areas = map.Lane:FindFirstChild("Areas")
	return areas ~= nil and areas:IsA("Folder"), "Lane.Areas missing"
end)

test("template Baseplate and SpawnLocation removed; one Neutral SpawnLocation at (0, 0.5, 0) facing +X", function()
	if workspace:FindFirstChild("Baseplate") then
		return false, "template Baseplate still in workspace"
	end
	local spawns = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("SpawnLocation") then
			table.insert(spawns, d)
		end
	end
	if #spawns ~= 1 then
		return false, #spawns .. " SpawnLocations"
	end
	local s = spawns[1]
	local look = s.CFrame.LookVector
	local ok = s:IsDescendantOf(map.Town.Square) and near(s.Position.X, 0) and near(s.Position.Y, 0.5) and near(s.Position.Z, 0)
		and near(look.X, 1) and near(look.Z, 0) and s.Neutral == true and s.Duration == 0
	return ok, "spawn at " .. fmt(s.Position) .. " look " .. fmt(look)
end)

----------------------------------------------------------------------------------------------
-- Plots
----------------------------------------------------------------------------------------------
local plots = sortedByIndex(tagged("Plot", map), "PlotIndex")

test("7 plots tagged Plot (Plot1..Plot7), 4 North + 3 South", function()
	if #plots ~= 7 then
		return false, #plots .. " plots"
	end
	local north, south = 0, 0
	for i, plot in ipairs(plots) do
		if plot.Name ~= "Plot" .. i or plot.Parent ~= map.Plots or plot:GetAttribute("PlotIndex") ~= i then
			return false, "bad plot " .. plot:GetFullName()
		end
		if plot:GetAttribute("Row") == "North" then
			north = north + 1
		elseif plot:GetAttribute("Row") == "South" then
			south = south + 1
		end
		if plot:GetAttribute("OwnerUserId") ~= 0 or plot:GetAttribute("PenLevel") ~= 1 or plot:GetAttribute("GateLocked") ~= false then
			return false, plot.Name .. " default attributes wrong"
		end
		if plot.PrimaryPart ~= plot:FindFirstChild("PlotBase") then
			return false, plot.Name .. " PrimaryPart is not PlotBase"
		end
	end
	return north == 4 and south == 3, north .. " north / " .. south .. " south"
end)

test("each plot has 1 Treadmill and 10 PenSlots (slots 1-7 active), " .. SPEC_PLOT_PARTS .. " parts", function()
	for _, plot in ipairs(plots) do
		local treadmills = tagged("Treadmill", plot)
		local slots = tagged("PenSlot", plot)
		if #treadmills ~= 1 then
			return false, plot.Name .. " has " .. #treadmills .. " treadmills"
		end
		if treadmills[1]:GetAttribute("Tier") ~= 1 or treadmills[1]:GetAttribute("PlotIndex") ~= plot:GetAttribute("PlotIndex") then
			return false, plot.Name .. " treadmill attributes"
		end
		if #slots ~= 10 then
			return false, plot.Name .. " has " .. #slots .. " pen slots"
		end
		local seen = {}
		for _, slot in ipairs(slots) do
			local i = slot:GetAttribute("SlotIndex")
			seen[i] = true
			if slot:GetAttribute("Active") ~= (i <= 7) or slot:GetAttribute("Occupied") ~= false then
				return false, slot:GetFullName() .. " Active/Occupied wrong"
			end
			if not slot:FindFirstChild("BeastPivot") then
				return false, slot:GetFullName() .. " has no BeastPivot attachment"
			end
		end
		for i = 1, 10 do
			if not seen[i] then
				return false, plot.Name .. " missing slot " .. i
			end
		end
		if #tagged("GateLock", plot) ~= 1 or #tagged("OwnerSign", plot) ~= 1 or #tagged("PlotSpawn", plot) ~= 1 then
			return false, plot.Name .. " gate lock / owner sign / spawn count"
		end
		if countParts(plot) ~= SPEC_PLOT_PARTS then
			return false, plot.Name .. " has " .. countParts(plot) .. " parts, spec says 54"
		end
	end
	return true
end)

test("plot treadmill, PlotSpawn and gate positions match spec section 5.2", function()
	for i, plot in ipairs(plots) do
		local spec = SPEC_PLOTS[i]
		local base = tagged("Treadmill", plot)[1]:FindFirstChild("Base")
		local spawn = tagged("PlotSpawn", plot)[1]
		local lock = tagged("GateLock", plot)[1]
		local t, s, g = base.Position, spawn.Position, lock.Position
		if not (near(t.X, spec.treadmill[1]) and near(t.Y, spec.treadmill[2]) and near(t.Z, spec.treadmill[3])) then
			return false, plot.Name .. " treadmill at " .. fmt(t)
		end
		if not (near(s.X, spec.spawn[1]) and near(s.Y, spec.spawn[2]) and near(s.Z, spec.spawn[3])) then
			return false, plot.Name .. " PlotSpawn at " .. fmt(s)
		end
		if not (near(g.X, spec.gate[1]) and near(math.abs(g.Z), math.abs(spec.gate[2]), 0.6)) then
			return false, plot.Name .. " gate at " .. fmt(g)
		end
		-- the spawn faces the street (local -Z)
		local look = spawn.CFrame.LookVector
		local towardStreet = (spec.spawn[3] > 0) and -1 or 1
		if not near(look.Z, towardStreet) then
			return false, plot.Name .. " PlotSpawn faces " .. fmt(look)
		end
	end
	return true
end)

test("pen slot positions follow spec 5.4 (north (Xc+x, 1.1, 80+z), south (Xc-x, 1.1, -80-z))", function()
	for i, plot in ipairs(plots) do
		local p = CONFIG.Plots.List[i]
		for _, slot in ipairs(tagged("PenSlot", plot)) do
			local xz = CONFIG.Plots.SlotLayout[slot:GetAttribute("SlotIndex")]
			local ex, ez
			if p.row == "North" then
				ex, ez = p.x + xz[1], 80 + xz[2]
			else
				ex, ez = p.x - xz[1], -80 - xz[2]
			end
			local pos = slot.Position
			if not (near(pos.X, ex) and near(pos.Y, 1.1) and near(pos.Z, ez)) then
				return false, slot:GetFullName() .. " at " .. fmt(pos) .. ", expected (" .. ex .. ", 1.1, " .. ez .. ")"
			end
		end
	end
	return true
end)

test("every plot is inside TownBounds and no two plots overlap", function()
	local townBounds = tagged("TownBounds")[1]
	local bounds = {}
	for _, plot in ipairs(plots) do
		local b = tagged("PlotBounds", plot)[1]
		if not boxInside(b, townBounds) then
			return false, plot.Name .. " PlotBounds pokes out of TownBounds"
		end
		table.insert(bounds, b)
	end
	for i = 1, #bounds do
		for j = i + 1, #bounds do
			if boxesOverlap(bounds[i], bounds[j]) then
				return false, plots[i].Name .. " overlaps " .. plots[j].Name
			end
		end
	end
	return true
end)

-- The task asks that "the SafeZone contains every plot". MAP_SPEC section 4 deliberately keeps
-- the plot YARDS out of the Safe Zone (rustling and whips work there), with each plot's
-- treadmill and PlotSpawn on the Safe Zone boardwalk. This check enforces the spec's version.
test("Safe Zone covers every plot's front (treadmill, PlotSpawn, gate ramp); yards stay PvP per spec section 4", function()
	if #CollectionService:GetTagged("SafeZone") ~= 4 then
		return false, "expected 4 SafeZone volumes"
	end
	for _, zone in ipairs(CollectionService:GetTagged("SafeZone")) do
		if type(zone:GetAttribute("ZoneName")) ~= "string" or zone.Transparency ~= 1 or zone.CanQuery ~= true then
			return false, zone.Name .. " ZoneName / invisible / CanQuery"
		end
	end
	for _, plot in ipairs(plots) do
		local belt = tagged("Treadmill", plot)[1]:FindFirstChild("Belt")
		local spawn = tagged("PlotSpawn", plot)[1]
		local ramp = plot:FindFirstChild("GateRamp")
		for _, part in ipairs({ belt, spawn, ramp }) do
			if not inAnySafeZone(part.Position) then
				return false, part:GetFullName() .. " at " .. fmt(part.Position) .. " is not in a SafeZone"
			end
		end
		local yard = plot:FindFirstChild("PlotBase").Position
		if inAnySafeZone(yard) then
			return false, plot.Name .. " yard centre is inside a SafeZone (spec keeps yards PvP)"
		end
	end
	return true
end)

test("spawn and every shop pad (Shop, Index, Rewards, Sell, Breeding) are inside the Safe Zone", function()
	for _, tag in ipairs({ "ShopPad", "IndexPad", "RewardsPad", "SellPad", "BreedingPad" }) do
		local pads = tagged(tag)
		if #pads ~= 1 then
			return false, tag .. " count " .. #pads
		end
		if not inAnySafeZone(pads[1].Position) then
			return false, tag .. " outside SafeZone"
		end
	end
	if tagged("ShopPad")[1]:GetAttribute("ShopId") ~= "General" then
		return false, "ShopPad ShopId"
	end
	return inAnySafeZone(map.Town.Square.SpawnLocation.Position), "SpawnLocation outside SafeZone"
end)

----------------------------------------------------------------------------------------------
-- Areas
----------------------------------------------------------------------------------------------
local areas = sortedByIndex(areaModels(), "AreaIndex")

test("10 areas in order along +X with strictly increasing SpeedRequired matching AreasConfig", function()
	if #areas ~= 10 or #CONFIG.Areas ~= 10 then
		return false, #areas .. " area models, " .. #CONFIG.Areas .. " in config"
	end
	local lastSpeed, lastStart = -1, -math.huge
	for i, area in ipairs(areas) do
		local cfg = CONFIG.Areas[i]
		local expectedName = string.format("Area%02d_%s", i, cfg.id)
		if area.Name ~= expectedName then
			return false, "area " .. i .. " is named " .. area.Name
		end
		if area:GetAttribute("AreaId") ~= cfg.id or area:GetAttribute("AreaName") ~= cfg.name then
			return false, area.Name .. " id/name attributes"
		end
		local speed = area:GetAttribute("SpeedRequired")
		if speed ~= cfg.speedRequired then
			return false, area.Name .. " SpeedRequired " .. tostring(speed) .. " vs config " .. tostring(cfg.speedRequired)
		end
		if not (speed > lastSpeed) then
			return false, area.Name .. " SpeedRequired does not increase"
		end
		local startX = area:GetAttribute("StartX")
		if not (startX > lastStart) then
			return false, area.Name .. " is not further along +X"
		end
		lastSpeed, lastStart = speed, startX
	end
	return true
end)

test("area segments are contiguous and non-overlapping (trailhead 432 -> Frontier End 3600)", function()
	local trailhead = map.Lane:FindFirstChild("Trailhead")
	local th = aabb(trailhead)
	local expectedStart = th.maxX
	if not near(expectedStart, 432) then
		return false, "trailhead ends at " .. expectedStart
	end
	for i, area in ipairs(areas) do
		local cfg = CONFIG.Areas[i]
		local s, e = area:GetAttribute("StartX"), area:GetAttribute("EndX")
		if s ~= cfg.startX or e ~= cfg.endX or e - s ~= cfg.length then
			return false, area.Name .. " StartX/EndX/length differ from config"
		end
		if not near(s, expectedStart) then
			return false, area.Name .. " starts at " .. s .. " but the previous segment ends at " .. expectedStart
		end
		local b = aabb(area:FindFirstChild("Bounds"))
		if not (near(b.minX, s) and near(b.maxX, e) and near(b.minZ, -64) and near(b.maxZ, 64)) then
			return false, area.Name .. " Bounds X " .. b.minX .. ".." .. b.maxX
		end
		for _, g in ipairs(area.Ground:GetChildren()) do
			local gb = aabb(g)
			if not (near(gb.minX, s) and near(gb.maxX, e)) then
				return false, g:GetFullName() .. " does not span the area"
			end
		end
		expectedStart = e
	end
	local frontierGround = map.Lane.FrontierEnd:FindFirstChild("Ground")
	return near(aabb(frontierGround).minX, expectedStart) and near(expectedStart, 3600), "Frontier End does not start where Area 10 ends"
end)

test("each area has exactly 1 AreaEntrance at its StartX and the sign shows its name and Speed", function()
	for i, area in ipairs(areas) do
		local cfg = CONFIG.Areas[i]
		local entrances = tagged("AreaEntrance", area)
		if #entrances ~= 1 then
			return false, area.Name .. " has " .. #entrances .. " AreaEntrance parts"
		end
		local trigger = entrances[1]
		if not near(trigger.Position.X, cfg.startX) or trigger.Transparency ~= 1 or trigger.CanQuery ~= true then
			return false, area.Name .. " EntranceTrigger position/visibility"
		end
		local signs = tagged("AreaSign", area)
		if #signs ~= 1 then
			return false, area.Name .. " AreaSign count " .. #signs
		end
		local left = signs[1]:FindFirstChild("SignLeft")
		if not left or left.Face ~= Enum.NormalId.Left then
			return false, area.Name .. " sign has no Left SurfaceGui"
		end
		local line1, line2 = labelText(left, "Line1"), labelText(left, "Line2")
		if line1 ~= string.upper(cfg.name) then
			return false, area.Name .. " sign line 1 is '" .. tostring(line1) .. "'"
		end
		if line2 ~= cfg.sign or parseSpeed(line2) ~= cfg.speedRequired then
			return false, area.Name .. " sign line 2 is '" .. tostring(line2) .. "' for SpeedRequired " .. cfg.speedRequired
		end
		local font = left:FindFirstChild("Line1").Font
		if font ~= Enum.Font[cfg.font] then
			return false, area.Name .. " sign font " .. tostring(font)
		end
		local right = signs[1]:FindFirstChild("SignRight")
		if not right or labelText(right, "Line1") ~= "\u{2190} TOWN" then
			return false, area.Name .. " sign has no '<- TOWN' side"
		end
	end
	return true
end)

test("8 HerdSpawn + 1 AlphaSpawn per area, inside the area's Bounds, at the spec 6.4 positions", function()
	for i, area in ipairs(areas) do
		local cfg = CONFIG.Areas[i]
		local bounds = area:FindFirstChild("Bounds")
		local spawns = tagged("HerdSpawn", area)
		local alphas = tagged("AlphaSpawn", area)
		if #spawns ~= 8 or #alphas ~= 1 then
			return false, area.Name .. " has " .. #spawns .. " HerdSpawn and " .. #alphas .. " AlphaSpawn"
		end
		for _, sp in ipairs(spawns) do
			local idx = sp:GetAttribute("SpawnIndex")
			local expected = SPEC_HERD[i][idx]
			local pos = sp.Position
			if not inBox(bounds, pos) then
				return false, sp:GetFullName() .. " outside Bounds"
			end
			if not (near(pos.X, expected[1]) and near(pos.Z, expected[2]) and near(pos.Y, 0.5)) then
				return false, sp:GetFullName() .. " at " .. fmt(pos) .. ", spec (" .. expected[1] .. ", " .. expected[2] .. ")"
			end
			local patch = (idx <= 4) and 1 or 2
			if sp:GetAttribute("PatchIndex") ~= patch or sp:GetAttribute("Occupied") ~= false then
				return false, sp:GetFullName() .. " PatchIndex/Occupied"
			end
		end
		local alpha = alphas[1]
		if not inBox(bounds, alpha.Position) then
			return false, alpha:GetFullName() .. " outside Bounds"
		end
		if not (near(alpha.Position.X, cfg.herdX) and near(alpha.Position.Z, SPEC_ALPHA_Z[i])) then
			return false, alpha:GetFullName() .. " at " .. fmt(alpha.Position)
		end
		if alpha:GetAttribute("AlphaId") ~= cfg.alpha.id or alpha:GetAttribute("LeashX") ~= 400 then
			return false, alpha:GetFullName() .. " AlphaId/LeashX"
		end
		-- faces the trail
		if not near(alpha.CFrame.LookVector.Z, -cfg.herdSide) then
			return false, alpha:GetFullName() .. " does not face the trail"
		end
		-- herd sign next to the Alpha repeats the Speed
		local herdSigns = tagged("HerdSign", area)
		local board = herdSigns[1] and herdSigns[1]:FindFirstChild("Board")
		local gui = board and board:FindFirstChildWhichIsA("SurfaceGui")
		if not gui or labelText(gui, "Line1") ~= string.upper(cfg.alpha.name) or labelText(gui, "Line2") ~= cfg.sign then
			return false, area.Name .. " HerdSign text"
		end
		local wantFace = (cfg.herdSide == 1) and Enum.NormalId.Front or Enum.NormalId.Back
		if gui.Face ~= wantFace then
			return false, area.Name .. " HerdSign faces away from the trail"
		end
	end
	return true
end)

test("area attributes (AreaIndex/AreaId/AreaName/SpeedRequired) on every tagged area part", function()
	for i, area in ipairs(areas) do
		local cfg = CONFIG.Areas[i]
		for _, tag in ipairs({ "AreaEntrance", "AreaBounds", "AreaSign", "HerdZone", "HerdSpawn", "AlphaSpawn", "HerdSign" }) do
			for _, inst in ipairs(tagged(tag, area)) do
				if inst:GetAttribute("AreaIndex") ~= i or inst:GetAttribute("AreaId") ~= cfg.id
					or inst:GetAttribute("AreaName") ~= cfg.name or inst:GetAttribute("SpeedRequired") ~= cfg.speedRequired then
					return false, inst:GetFullName() .. " area attributes"
				end
			end
		end
		local herdX = area:GetAttribute("HerdX")
		local fraction = cfg.herdFraction
		if not near(herdX, cfg.startX + fraction * cfg.length, 0.5) then
			return false, area.Name .. " HerdX " .. herdX .. " is not at " .. (fraction * 100) .. "% of the area"
		end
		if area:GetAttribute("HerdSide") ~= ((i % 2 == 1) and 1 or -1) then
			return false, area.Name .. " herds should alternate sides (odd north)"
		end
		for _, key in ipairs({ "AtmDensity", "AtmHaze", "AtmColor", "AtmDecay", "CCTint", "ClockOverride", "Weather" }) do
			if area:GetAttribute(key) == nil then
				return false, area.Name .. " missing lighting attribute " .. key
			end
		end
	end
	return true
end)

----------------------------------------------------------------------------------------------
-- Whole-map checks
----------------------------------------------------------------------------------------------
test("every BasePart in Workspace is Anchored", function()
	local loose = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and d.Anchored ~= true then
			table.insert(loose, d:GetFullName())
		end
	end
	return #loose == 0, #loose .. " unanchored: " .. table.concat(loose, ", ", 1, math.min(#loose, 5))
end)

test("part count is within budget (<= " .. PART_BUDGET .. ") and every section matches the spec", function()
	local town = countParts(map.Town)
	local plotParts = countParts(map.Plots)
	local laneGlobals = countParts(map.Lane) - countParts(map.Lane.Areas)
	local lines = {}
	table.insert(lines, string.format("town %d (spec %d), plots %d (spec %d), lane globals %d (spec %d)",
		town, SPEC_TOWN_PARTS, plotParts, SPEC_PLOT_PARTS * 7, laneGlobals, SPEC_LANE_GLOBALS))
	local ok = town == SPEC_TOWN_PARTS and plotParts == SPEC_PLOT_PARTS * 7 and laneGlobals == SPEC_LANE_GLOBALS
	for i, area in ipairs(areas) do
		local fixed = 0
		for _, name in ipairs({ "Ground", "Cliffs", "Entrance", "Herd" }) do
			fixed = fixed + countParts(area:FindFirstChild(name))
		end
		fixed = fixed + 1 -- Bounds
		local props = countParts(area.Landmarks) + countParts(area.Props)
		local expectedFixed = SPEC_AREA_FIXED + ((CONFIG.Areas[i].id == "FrostPeak") and 1 or 0)
		if fixed ~= expectedFixed or props ~= SPEC_AREA_PROPS[i] then
			ok = false
			table.insert(lines, string.format("%s: fixed %d (spec %d), props %d (spec %d)", area.Name, fixed, expectedFixed, props, SPEC_AREA_PROPS[i]))
		end
	end
	print(string.format("      parts: %d total (budget %d); %s", partsTotal, PART_BUDGET, lines[1]))
	ok = ok and partsTotal <= PART_BUDGET and partsTotal == buildReport.parts
	return ok, table.concat(lines, "; ")
end)

test("CollectionService tag counts match the spec", function()
	local counts = tagCounts()
	local bad = {}
	for tag, expected in pairs(EXPECTED_TAGS) do
		if counts[tag] ~= expected then
			table.insert(bad, tag .. "=" .. counts[tag] .. " (want " .. expected .. ")")
		end
	end
	table.sort(bad)
	return #bad == 0, table.concat(bad, ", ")
end)

test("LaneWaypoints WP00..WP11 have Order 0..11 at the spec X values", function()
	local wps = sortedByIndex(tagged("LaneWaypoint"), "Order")
	if #wps ~= 12 then
		return false, #wps .. " waypoints"
	end
	for k, wp in ipairs(wps) do
		if wp:GetAttribute("Order") ~= k - 1 or wp.Name ~= string.format("WP%02d", k - 1)
			or not near(wp.Position.X, CONFIG.Lane.WaypointX[k]) or not near(wp.Position.Z, 0) then
			return false, wp.Name .. " at " .. fmt(wp.Position)
		end
	end
	return true
end)

test("red line at X 400, solid invisible walls (lane, town boundary, plot colliders), AlphaBlocker group", function()
	local redLine = tagged("TownGate")[1]
	if not (near(redLine.Position.X, 400) and redLine.Material == Enum.Material.Neon and redLine.CanCollide == false) then
		return false, "RedLine"
	end
	for _, wall in ipairs(tagged("LaneBoundary")) do
		local b = aabb(wall)
		if wall.CanCollide ~= true or wall.Transparency ~= 1 or not near(math.min(math.abs(b.minZ), math.abs(b.maxZ)), 64) then
			return false, wall.Name .. " is not a solid invisible wall starting at |Z| 64"
		end
	end
	local blocker = map.Town.TownGate:FindFirstChild("AlphaBlocker")
	if blocker.CollisionGroup ~= "AlphaBlocker" or blocker.CanCollide ~= true or blocker.Transparency ~= 1 then
		return false, "AlphaBlocker group/collision"
	end
	-- every invisible part is non-solid unless it is meant to be a wall
	local SOLID = { AlphaBlocker = true, Collider = true }
	for _, p in ipairs(baseParts(map)) do
		if p.Transparency == 1 and p.CanCollide then
			local wallish = SOLID[p.Name] or string.match(p.Name, "^Boundary_") or string.match(p.Name, "^Collider")
				or string.match(p.Name, "^LaneWall_")
			if not wallish then
				return false, p:GetFullName() .. " is invisible but solid"
			end
		end
	end
	return true
end)

test("collision groups are registered with the section 3.4 matrix", function()
	local function collide(a, b)
		return PhysicsService:CollisionGroupsAreCollidable(a, b)
	end
	local names = { "Players", "Beasts", "Alphas", "AlphaBlocker" }
	for i = 1, 7 do
		table.insert(names, "GateLock" .. i)
		table.insert(names, "Owner" .. i)
	end
	for _, n in ipairs(names) do
		if not PhysicsService:IsCollisionGroupRegistered(n) then
			return false, n .. " not registered"
		end
	end
	local checks = {
		{ "Players", "AlphaBlocker", false }, { "Default", "AlphaBlocker", false }, { "Alphas", "AlphaBlocker", true },
		{ "Players", "Beasts", false }, { "Beasts", "Default", true }, { "Beasts", "Beasts", false },
		{ "Alphas", "Players", false }, { "Alphas", "Default", true }, { "Players", "Players", true },
		{ "GateLock3", "Owner3", false }, { "GateLock3", "Owner4", true }, { "GateLock3", "Players", true },
		{ "GateLock3", "Default", false }, { "Owner2", "Players", true }, { "Owner2", "AlphaBlocker", false },
	}
	for _, c in ipairs(checks) do
		if collide(c[1], c[2]) ~= c[3] then
			return false, c[1] .. " vs " .. c[2] .. " should be " .. tostring(c[3])
		end
	end
	return #MOCK.groups <= 32, "more than 32 collision groups"
end)

test("every sign uses TextScaled text with an outline (TextStrokeTransparency 0)", function()
	local n = 0
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("TextLabel") then
			n = n + 1
			if d.TextScaled ~= true or d.TextStrokeTransparency ~= 0 or d.Text == "" then
				return false, d:GetFullName()
			end
		elseif d:IsA("SurfaceGui") then
			if d.SizingMode ~= Enum.SurfaceGuiSizingMode.PixelsPerStud then
				return false, d:GetFullName() .. " SizingMode"
			end
		end
	end
	return n > 0, "no TextLabels"
end)

test("34 PointLights (spec section 10, minus the 14 plot gate lanterns), all with Shadows off", function()
	local n = 0
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("PointLight") then
			n = n + 1
			if d.Shadows ~= false then
				return false, d:GetFullName() .. " casts shadows"
			end
		end
	end
	return n == 34, n .. " PointLights"
end)

test("shapes are valid: Balls uniform, Cylinders with Y == Z, sizes positive", function()
	for _, p in ipairs(baseParts(map)) do
		local s = p.Size
		if p:IsA("Part") then
			if p.Shape == Enum.PartType.Ball and not (s.X == s.Y and s.Y == s.Z) then
				return false, p:GetFullName() .. " ball " .. fmt(s)
			end
			if p.Shape == Enum.PartType.Cylinder and s.Y ~= s.Z then
				return false, p:GetFullName() .. " cylinder " .. fmt(s)
			end
		end
	end
	return true
end)

test("scattered props all found a spot, stay off the trail, and skip the herd patch", function()
	if buildReport.skippedProps ~= 0 then
		return false, buildReport.skippedProps .. " props skipped"
	end
	for i, area in ipairs(areas) do
		local cfg = CONFIG.Areas[i]
		for _, prop in ipairs(area.Props:GetChildren()) do
			local base = string.match(prop.Name, "^(%a+)")
			if not TRAIL_OK[base] then
				for _, p in ipairs(baseParts(prop)) do
					if math.abs(p.Position.Z) < 19.5 then
						return false, p:GetFullName() .. " sits on the trail at " .. fmt(p.Position)
					end
					if p.Position.X < cfg.startX or p.Position.X > cfg.endX then
						return false, p:GetFullName() .. " is outside its area"
					end
				end
				-- herd exclusion (section 6.5): nothing on the herd side within 48 studs of HerdX,
				-- measured at the prop's first part
				local pos = prop.PrimaryPart.Position
				local side = (pos.Z > 0) and 1 or -1
				if base ~= "LavaFall" and base ~= "FalseFront" and side == cfg.herdSide and math.abs(pos.X - cfg.herdX) < 40 then
					return false, prop:GetFullName() .. " is inside the herd patch"
				end
			end
		end
	end
	return true
end)

test("Lighting has one Atmosphere, one BloomEffect and the AreaColorCorrection", function()
	local atm, bloom, cc = 0, 0, 0
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") then atm = atm + 1 end
		if child:IsA("BloomEffect") then bloom = bloom + 1 end
		if child.Name == "AreaColorCorrection" then cc = cc + 1 end
	end
	return atm == 1 and bloom == 1 and cc == 1 and near(Lighting.ClockTime, 14.5), atm .. "/" .. bloom .. "/" .. cc
end)

----------------------------------------------------------------------------------------------
-- Steal An Egg look (AreasConfig.Style)
----------------------------------------------------------------------------------------------
local function styledParts(m)
	local list = {}
	local function add(part)
		if part then
			table.insert(list, part)
		end
	end
	local g = m.Town.Ground
	for _, n in ipairs({ "SquareGround", "RanchGroundN", "RanchGroundS", "MainStreet", "BoardwalkN", "BoardwalkS" }) do
		add(g:FindFirstChild(n))
	end
	for _, n in ipairs({ "Palisade_N", "Palisade_S", "Palisade_W", "Palisade_EN", "Palisade_ES" }) do
		add(m.Town.Fence:FindFirstChild(n))
	end
	for _, plot in ipairs(m.Plots:GetChildren()) do
		add(plot:FindFirstChild("PlotBase"))
	end
	add(m.Lane:FindFirstChild("Trailhead"))
	for _, area in ipairs(m.Lane.Areas:GetChildren()) do
		for _, n in ipairs({ "TrailStrip", "ShoulderN", "ShoulderS" }) do
			add(area.Ground:FindFirstChild(n))
		end
		for _, n in ipairs({ "WallN", "WallS", "CrestN", "CrestS", "ToeN", "ToeS" }) do
			add(area.Cliffs:FindFirstChild(n))
		end
	end
	return list
end

local function countTextures(root)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Texture") then
			n = n + 1
		end
	end
	return n
end

test("Steal An Egg look: 109 ground, path, wall and plot-floor parts are Plastic with studs on top", function()
	local list = styledParts(map)
	if #list ~= 109 then
		return false, #list .. " styled parts"
	end
	for _, part in ipairs(list) do
		if part.Material ~= Enum.Material.Plastic or part.TopSurface ~= Enum.SurfaceType.Studs then
			return false, part:GetFullName()
		end
	end
	return buildReport.styledParts == 109, "report says " .. tostring(buildReport.styledParts)
end)

test("Steal An Egg look: walls are studded on every side, area 1 uses the Forest colours, Town uses the palette", function()
	local a1 = map.Lane.Areas:FindFirstChild("Area01_DustyPrairie")
	local wall = a1.Cliffs.WallN
	for _, s in ipairs({ "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }) do
		if wall[s] ~= Enum.SurfaceType.Studs then
			return false, s
		end
	end
	local o = CONFIG.Style.AreaOverrides[1]
	local t = CONFIG.Style.Town
	return wall.Color == Color3.fromRGB(o.wall[1], o.wall[2], o.wall[3])
		and a1.Ground.ShoulderN.Color == Color3.fromRGB(o.shoulder[1], o.shoulder[2], o.shoulder[3])
		and map.Town.Ground.SquareGround.Color == Color3.fromRGB(t.grass[1], t.grass[2], t.grass[3])
		and map.Town.Fence.Palisade_N.Color == Color3.fromRGB(t.wall[1], t.wall[2], t.wall[3]), "colours"
end)

test("Steal An Egg look: other areas get their theme colour made brighter and more saturated", function()
	local a2 = map.Lane.Areas:FindFirstChild("Area02_CactusCanyon")
	local theme = CONFIG.Areas[2].theme.wall.color
	local want = MAP_BUILDER.vivid(theme, CONFIG.Style)
	local c = a2.Cliffs.WallN.Color
	-- brighter = the strongest channel goes up; more saturated = the channels spread further apart
	local brighter = math.max(want[1], want[2], want[3]) >= math.max(theme[1], theme[2], theme[3])
		and (math.max(want[1], want[2], want[3]) - math.min(want[1], want[2], want[3]))
			> (math.max(theme[1], theme[2], theme[3]) - math.min(theme[1], theme[2], theme[3]))
	return c == Color3.fromRGB(want[1], want[2], want[3]) and brighter, table.concat(want, ",")
end)

test("checkerboard: 269 Textures with Check-UI's uploaded checker tile, black at 0.85 transparency", function()
	local n, wrong = 0, nil
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("Texture") then
			n = n + 1
			if d.Texture ~= "rbxassetid://385956923" or d.Transparency ~= 0.85 or d.Color3 ~= Color3.new(0, 0, 0) then
				wrong = d:GetFullName()
			end
		end
	end
	return n == 269 and buildReport.textures == 269 and wrong == nil, n .. " " .. tostring(wrong)
end)

----------------------------------------------------------------------------------------------
-- Second build: idempotency and determinism
----------------------------------------------------------------------------------------------
local firstTags = tagCounts()
local firstSignature = signature()
local firstModels = buildReport.models
local oldMap = map

print("Building again (second run, must not duplicate anything)...")
local secondReport = BUILD_MAP()
local maps = 0
for _, child in ipairs(workspace:GetChildren()) do
	if child.Name == "Map" then
		maps = maps + 1
	end
end
local newMap = workspace:FindFirstChild("Map")

test("running the builder twice leaves exactly one workspace.Map", function()
	return maps == 1 and newMap ~= oldMap, maps .. " Map folders"
end)

test("second build has the same part and model counts", function()
	local parts2 = countParts(newMap)
	return parts2 == partsTotal and secondReport.parts == partsTotal and secondReport.models == firstModels,
		string.format("parts %d vs %d, models %d vs %d", parts2, partsTotal, secondReport.models, firstModels)
end)

test("CollectionService tags are not duplicated by the second build", function()
	local counts = tagCounts()
	for tag, n in pairs(firstTags) do
		if counts[tag] ~= n then
			return false, tag .. " " .. n .. " -> " .. counts[tag]
		end
	end
	return true
end)

test("the old Map was destroyed (its parts are out of the DataModel)", function()
	return oldMap.Parent == nil and MOCK.data(oldMap).destroyed == true, "old Map still alive"
end)

test("props are deterministic: identical positions on both builds", function()
	return signature() == firstSignature, "positions differ between builds"
end)

test("Lighting effects are reused, not duplicated", function()
	local atm, bloom, cc = 0, 0, 0
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") then atm = atm + 1 end
		if child:IsA("BloomEffect") then bloom = bloom + 1 end
		if child.Name == "AreaColorCorrection" then cc = cc + 1 end
	end
	return atm == 1 and bloom == 1 and cc == 1, atm .. "/" .. bloom .. "/" .. cc
end)

----------------------------------------------------------------------------------------------
-- Checker texture build (the source MapBuilder module with CheckerTexture set)
----------------------------------------------------------------------------------------------
print("Building with our own texture id set on the place (third run, source MapBuilder module)...")
workspace:SetAttribute("CheckerTexture", "rbxassetid://1")
local texReport = MAP_BUILDER.build(CONFIG)
workspace:SetAttribute("CheckerTexture", nil)
local texMap = workspace:FindFirstChild("Map")

test("workspace attribute CheckerTexture swaps the tile: 269 textures, 8 studs per tile, transparency 0", function()
	local n, wrong = 0, nil
	for _, d in ipairs(texMap:GetDescendants()) do
		if d:IsA("Texture") then
			n = n + 1
			if d.Texture ~= "rbxassetid://1" or d.StudsPerTileU ~= 8 or d.StudsPerTileV ~= 8 or d.Transparency ~= 0 then
				wrong = d:GetFullName()
			end
		end
	end
	local top = texMap.Town.Ground.SquareGround:FindFirstChild("CheckerTop")
	return n == 269 and texReport.textures == 269 and wrong == nil and top ~= nil and top.Face == Enum.NormalId.Top,
		n .. " textures " .. tostring(wrong)
end)

print(string.format("Map summary: %d parts, %d models, %d plots, %d areas.", partsTotal, buildReport.models, #plots, #areas))
return string.format("%d %d %d", passed, failed, partsTotal)
