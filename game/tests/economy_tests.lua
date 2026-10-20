--[[
	economy_tests.lua: checks GameConfig, Economy and NumberFormat (the shared gameplay rules).
	Run by tests/run_tests.js under fengari (Lua 5.3), in a fresh state with no Roblox mock.

	Expects these globals: AREAS_CONFIG, GAME_CONFIG, ECONOMY (Economy, not yet initialised)
	and NUMBER_FORMAT. Prints one PASS/FAIL line per check and returns "passed failed".
]]

local passed, failed = 0, 0

local function test(name, fn)
	local ok, result, detail = pcall(fn)
	if ok and result == true then
		passed = passed + 1
		print("PASS  " .. name)
	else
		failed = failed + 1
		local why = detail
		if not ok then
			why = "error: " .. tostring(result)
		end
		print("FAIL  " .. name .. (why and ("\n        " .. tostring(why)) or ""))
	end
end

local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-9)
end

local Config = GAME_CONFIG
local Areas = AREAS_CONFIG
local Economy = ECONOMY.init(Config, Areas)
local Format = NUMBER_FORMAT

----------------------------------------------------------------------------------------------
-- Config
----------------------------------------------------------------------------------------------
test("11 treadmill tiers, numbered in order, Speed per step and price strictly rising, tier 1 free", function()
	local tiers = Config.Treadmill.Tiers
	if #tiers ~= 11 or #tiers ~= Areas.Plots.TreadmillTiers then
		return false, #tiers .. " tiers"
	end
	if tiers[1].price ~= 0 then
		return false, "tier 1 costs " .. tiers[1].price
	end
	for i = 2, #tiers do
		if tiers[i].tier ~= i or tiers[i].speedPerStep <= tiers[i - 1].speedPerStep or tiers[i].price <= tiers[i - 1].price then
			return false, "tier " .. i
		end
	end
	return true
end)

test("Spurs have unique ids, and multiplier and price both rise", function()
	local seen = {}
	for i, spur in ipairs(Config.Spurs) do
		if seen[spur.id] then
			return false, "duplicate " .. spur.id
		end
		seen[spur.id] = true
		if i > 1 and (spur.multiplier <= Config.Spurs[i - 1].multiplier or spur.price <= Config.Spurs[i - 1].price) then
			return false, spur.id
		end
	end
	return true
end)

test("every treadmill tier and Spur names a real rarity", function()
	for _, t in ipairs(Config.Treadmill.Tiers) do
		if not Economy.Rarities[t.rarity] then return false, t.name end
	end
	for _, s in ipairs(Config.Spurs) do
		if not Economy.Rarities[s.rarity] then return false, s.id end
	end
	return true
end)

test("pen: 7 slots to start, a rising price for each of the 12 upgrades to 19 slots", function()
	local prices = Config.Pen.UpgradePrices
	if Config.Pen.StartSlots ~= Areas.Plots.PenStartSlots or Config.Pen.MaxSlots ~= Areas.Plots.PenMaxSlots then
		return false, "slot counts differ from AreasConfig"
	end
	if #prices ~= Config.Pen.MaxSlots - Config.Pen.StartSlots then
		return false, #prices .. " prices"
	end
	for i = 2, #prices do
		if prices[i] <= prices[i - 1] then return false, "upgrade " .. i end
	end
	return true
end)

test("80 beasts indexed by id, each with income, weight and a tame time", function()
	local n = 0
	for id, b in pairs(Economy.Beasts) do
		n = n + 1
		if not (b.baseIncome > 0 and b.baseKg > 0 and b.tameSeconds > 0 and Economy.Rarities[b.rarity]) then
			return false, id
		end
	end
	return n == 80, n .. " beasts"
end)

test("starter beasts exist", function()
	for _, b in ipairs(Config.NewPlayer.StarterBeasts) do
		if not Economy.Beasts[b.id] or not Economy.Mutations[b.mutation] then return false, b.id end
	end
	return true
end)

----------------------------------------------------------------------------------------------
-- Movement (MAP_SPEC section 2 table)
----------------------------------------------------------------------------------------------
test("WalkSpeed curve matches the MAP_SPEC section 2 table", function()
	local rows = { { 0, 16.0 }, { 900, 51.5 }, { 10000, 64.0 }, { 40000, 71.2 }, { 170000, 78.8 }, { 700000, 86.1 },
		{ 2500000, 92.8 }, { 17000000, 102.8 }, { 150000000, 114.1 }, { 700000000, 122.1 }, { 50000000000, 144.4 } }
	for _, row in ipairs(rows) do
		local ws = Economy.walkSpeed(row[1])
		if not near(ws, row[2], 0.051) then
			return false, row[1] .. " -> " .. ws
		end
	end
	return Economy.walkSpeed(1e40) == 160 and Economy.walkSpeed(-5) == 16, "clamp"
end)

test("towing multipliers by weight class: x0.9 / x0.8 / x0.7 / x0.55", function()
	return Economy.towMultiplier(2) == 0.9 and Economy.towMultiplier(99.9) == 0.9 and Economy.towMultiplier(100) == 0.8
		and Economy.towMultiplier(999) == 0.8 and Economy.towMultiplier(5000) == 0.7 and Economy.towMultiplier(10000) == 0.55
		and Economy.towMultiplier(1e9) == 0.55
end)

test("escape test: 20% over the sign escapes with a light beast, not with a very heavy one", function()
	return Economy.escapes(12000, 50, 10000) and not Economy.escapes(12000, 20000, 10000)
		and not Economy.escapes(10000, 50, 10000) and Economy.escapes(0, 2, 0)
end)

test("areaForSpeed / nextArea follow the signs", function()
	return Economy.areaForSpeed(0).index == 1 and Economy.areaForSpeed(899).index == 1
		and Economy.areaForSpeed(900).index == 2 and Economy.areaForSpeed(1e12).index == 10
		and Economy.nextArea(0).index == 2 and Economy.nextArea(10000).index == 4 and Economy.nextArea(1e12) == nil
end)

----------------------------------------------------------------------------------------------
-- Treadmill and Spurs
----------------------------------------------------------------------------------------------
test("new data: starting cash, tier 1, no Spurs, the starter beast in slot 1", function()
	local d = Economy.newData()
	return d.Cash == Config.NewPlayer.Cash and d.TreadmillTier == 1 and d.EquippedSpur == "" and d.PenLevel == 1
		and d.Pen[1] and d.Pen[1].id == "PrairieChick" and Economy.penSlots(d) == 7
end)

test("a step adds Speed per step x Spur multiplier x boost", function()
	local d = Economy.newData()
	local g1 = Economy.applyStep(d)
	d.Spurs.Rusty = true
	d.EquippedSpur = "Rusty"
	local g2 = Economy.applyStep(d, 2)
	return g1 == 2 and g2 == 6 and d.Speed == 8 and d.Stats.Steps == 2, g1 .. " " .. g2 .. " " .. d.Speed
end)

test("treadmill tiers must be bought in order, with enough cash", function()
	local d = Economy.newData()
	d.Cash = 10 ^ 9
	local skip = Economy.buyTreadmill(d, 3)
	local okIron = Economy.buyTreadmill(d, 2)
	local again = Economy.buyTreadmill(d, 2)
	local okCopper = Economy.buyTreadmill(d, 3)
	local cashAfter = d.Cash
	d.Cash = 0
	local broke = Economy.buyTreadmill(d, 4)
	local bogus = Economy.buyTreadmill(d, 99)
	return not skip and okIron and not again and okCopper and not broke and not bogus and d.TreadmillTier == 3
		and cashAfter == 10 ^ 9 - 15000 - 250000, tostring(cashAfter)
end)

test("buying Spurs charges cash, auto-equips an upgrade, never a downgrade", function()
	local d = Economy.newData()
	d.Cash = 10000
	local a = Economy.buySpur(d, "Iron")
	local equippedAfterIron = d.EquippedSpur
	local b = Economy.buySpur(d, "Rusty")
	local c = Economy.buySpur(d, "Rusty")
	local e = Economy.buySpur(d, "Copper")
	return a and b and not c and not e and equippedAfterIron == "Iron" and d.EquippedSpur == "Iron"
		and d.Cash == 10000 - 5000 - 100 and Economy.spurMultiplier(d) == 2
end)

test("equipping: only owned Spurs, '' takes them off", function()
	local d = Economy.newData()
	d.Spurs.Iron = true
	local bad = Economy.equipSpur(d, "Gold")
	local fake = Economy.equipSpur(d, "Nope")
	local good = Economy.equipSpur(d, "Iron")
	local m = Economy.spurMultiplier(d)
	local off = Economy.equipSpur(d, "")
	return not bad and not fake and good and m == 2 and off and Economy.spurMultiplier(d) == 1
end)

----------------------------------------------------------------------------------------------
-- Pen and income
----------------------------------------------------------------------------------------------
test("beast income = base x mutation x (kg / baseKg) ^ 0.617", function()
	local base = Economy.beastIncome({ id = "PrairieChick", kg = 2, mutation = "None" })
	local heavy = Economy.beastIncome({ id = "Grizzly", kg = 700, mutation = "Golden" })
	local expected = 240 * 2 * 2 ^ 0.617
	return base == 1 and near(heavy, expected, 1e-6) and Economy.beastIncome({ id = "Nope" }) == 0, heavy
end)

test("pen income sums the pen and payIncome adds it to cash", function()
	local d = Economy.newData()
	Economy.addBeast(d, { id = "RedFox", kg = 8, mutation = "None" })
	local perSecond = Economy.penIncome(d)
	local paid = Economy.payIncome(d, 10, 2)
	return perSecond == 181 and paid == 3620 and d.Cash == Config.NewPlayer.Cash + 3620 and d.Stats.CashEarned == 3620
end)

test("addBeast fills the lowest free slot and refuses a full pen", function()
	local d = Economy.newData()
	local slots = {}
	for i = 1, 6 do
		slots[i] = Economy.addBeast(d, { id = "Jackrabbit" })
	end
	local full, reason = Economy.addBeast(d, { id = "Jackrabbit" })
	return slots[1] == 2 and slots[6] == 7 and full == nil and reason ~= nil and d.Pen[7].kg == 3
end)

test("pen upgrades: one slot per level up to 19, then refused", function()
	local d = Economy.newData()
	d.Cash = 1e30
	local bought = 0
	while Economy.buyPenSlot(d) do
		bought = bought + 1
	end
	return bought == 12 and Economy.penSlots(d) == 19 and Economy.penUpgradePrice(d) == nil
end)

test("reconcile repairs a broken save and keeps the good parts", function()
	local d = Economy.reconcile({
		Cash = 500, Speed = -4, TreadmillTier = 40, Spurs = { Iron = true }, EquippedSpur = "Gold",
		PenLevel = 2, Stats = { Steps = 5 }, Pen = { ["1"] = { id = "RedFox", kg = 8, mutation = "Weird" }, ["8"] = { id = "Jackrabbit", kg = 3 },
			["9"] = { id = "Jackrabbit" }, ["3"] = { id = "NotABeast" } },
	})
	return d.Cash == 500 and d.Speed == 0 and d.TreadmillTier == 11 and d.EquippedSpur == "" and d.Stats.Steps == 5 and d.Stats.CashEarned == 0
		and d.Pen[1].mutation == "None" and d.Pen[8] and d.Pen[9] == nil and d.Pen[3] == nil
end)

test("reconcile turns garbage into a new save", function()
	local d = Economy.reconcile("garbage")
	return d.Cash == Config.NewPlayer.Cash and d.Pen[1] ~= nil
end)

test("serialize + reconcile round-trips a sparse pen", function()
	local d = Economy.newData()
	d.PenLevel = 3
	Economy.addBeast(d, { id = "RedFox", kg = 9 }, 9)
	local saved = Economy.serialize(d)
	local stringKeys = type(next(saved.Pen)) == "string"
	local back = Economy.reconcile(saved)
	return stringKeys and d.Pen[9] ~= nil and back.Pen[9].kg == 9 and back.Pen[1].id == "PrairieChick"
end)

----------------------------------------------------------------------------------------------
-- NumberFormat
----------------------------------------------------------------------------------------------
test("NumberFormat.short", function()
	local cases = { { 0, "0" }, { 7, "7" }, { 12.5, "12.5" }, { 999, "999" }, { 1000, "1K" }, { 1234, "1.2K" },
		{ 999400, "999K" }, { 999949, "1M" }, { 99960, "100K" }, { 999999, "1M" }, { 4500000, "4.5M" }, { 125000000, "125M" }, { 3.1e9, "3.1B" },
		{ 7e12, "7T" }, { 2.2e15, "2.2Qa" }, { -1500, "-1.5K" } }
	for _, c in ipairs(cases) do
		local got = Format.short(c[1])
		if got ~= c[2] then
			return false, c[1] .. " -> " .. got .. " (want " .. c[2] .. ")"
		end
	end
	return true
end)

test("NumberFormat.cash, commas and clock", function()
	return Format.cash(4.2e9) == "$4.2B" and Format.commas(1234567) == "1,234,567" and Format.commas(100) == "100"
		and Format.commas(-1234) == "-1,234" and Format.clock(75) == "1:15" and Format.clock(3725) == "1:02:05"
		and Format.clock(-3) == "0:00"
end)

test("NumberFormat.commasShort / cashLong (Steal An Egg counter style)", function()
	local cases = { { 0, "0" }, { 43931, "43,931" }, { 999999, "999,999" }, { 1000000, "1,000K" },
		{ 89121000000, "89,121M" }, { 1234567890123, "1,234B" }, { 8.9121e28, "89,121Sp" }, { 12.7, "12" } }
	for _, c in ipairs(cases) do
		local got = Format.commasShort(c[1])
		if got ~= c[2] then
			return false, c[1] .. " -> " .. got .. " (want " .. c[2] .. ")"
		end
	end
	return Format.cashLong(43931) == "$43,931"
end)

test("inside Roblox (script set) the module sets itself up once, without recursing", function()
	local savedScript, savedRequire = script, require
	script = { Parent = { GameConfig = GAME_CONFIG, AreasConfig = AREAS_CONFIG } }
	local calls = 0
	require = function(module)
		calls = calls + 1
		return module
	end
	local ok, module = pcall(LOAD_ECONOMY)
	script, require = savedScript, savedRequire
	if not ok then
		return false, tostring(module)
	end
	return calls == 2 and module.Beasts and module.Beasts.PrairieChick ~= nil, calls .. " requires"
end)

return string.format("%d %d", passed, failed)
