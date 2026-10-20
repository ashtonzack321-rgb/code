--[[
	Economy  (ReplicatedStorage.Shared.Economy)

	The rules of the money and Speed loop, as pure functions on a player's save table.
	The server services call these and then save; the client uses the read-only ones
	(prices, gains) to draw the shop. Nothing here touches Roblox instances, so
	game/tests/economy_tests.lua runs every rule under plain Lua.

	Save table shape (DataService creates it with Economy.newData):
	  Cash, Speed           numbers
	  TreadmillTier         1..11
	  Spurs                 { [spurId] = true }   owned Spurs
	  EquippedSpur          spurId or ""         (one at a time)
	  PenLevel              1.. (slots = 6 + PenLevel)
	  Pen                   { [slotIndex] = { id, kg, mutation } }  tamed beasts in the pen
	  Stats                 { Steps, CashEarned }
]]

local Economy = {}

local GameConfig
local AreasConfig

-- Both config modules are passed in, so the same file works in Roblox and in the tests.
function Economy.init(gameConfig, areasConfig)
	GameConfig = gameConfig
	AreasConfig = areasConfig
	Economy.Beasts = {}
	Economy.Rarities = {}
	for _, rarity in ipairs(areasConfig.Rarities) do
		Economy.Rarities[rarity.id] = rarity
	end
	for _, area in ipairs(areasConfig.Areas) do
		for _, beast in ipairs(area.beasts) do
			Economy.Beasts[beast.id] = {
				id = beast.id,
				name = beast.name,
				rarity = beast.rarity,
				baseIncome = beast.baseIncome,
				baseKg = beast.baseKg,
				tameSeconds = beast.tameSeconds or Economy.Rarities[beast.rarity].tameSeconds,
				areaIndex = area.index,
			}
		end
	end
	Economy.Mutations = {}
	for _, mutation in ipairs(gameConfig.Mutations) do
		Economy.Mutations[mutation.id] = mutation
	end
	Economy.SpursById = {}
	for i, spur in ipairs(gameConfig.Spurs) do
		Economy.SpursById[spur.id] = spur
		spur.order = i
	end
	return Economy
end

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = copy(v)
	end
	return out
end

----------------------------------------------------------------------------------------------
-- Save data
----------------------------------------------------------------------------------------------
function Economy.newData()
	local start = GameConfig.NewPlayer
	local data = {
		Version = GameConfig.Version,
		Cash = start.Cash,
		Speed = start.Speed,
		TreadmillTier = 1,
		Spurs = {},
		EquippedSpur = "",
		PenLevel = 1,
		Pen = {},
		Stats = { Steps = 0, CashEarned = 0 },
		LastOnline = 0,          -- os.time() of the last save, for offline earnings
	}
	for i, beast in ipairs(start.StarterBeasts) do
		data.Pen[i] = copy(beast)
	end
	return data
end

-- Fills in fields a newer version added and drops values that no longer make sense,
-- so an old or hand-edited save can never break a service.
function Economy.reconcile(data)
	local fresh = Economy.newData()
	if type(data) ~= "table" then
		return fresh
	end
	for key, value in pairs(fresh) do
		if type(data[key]) ~= type(value) then
			data[key] = value
		end
	end
	for key, value in pairs(fresh.Stats) do
		if type(data.Stats[key]) ~= type(value) then
			data.Stats[key] = value
		end
	end
	data.TreadmillTier = math.max(1, math.min(#GameConfig.Treadmill.Tiers, math.floor(data.TreadmillTier)))
	data.PenLevel = math.max(1, math.min(Economy.maxPenLevel(), math.floor(data.PenLevel)))
	if data.EquippedSpur ~= "" and not (Economy.SpursById[data.EquippedSpur] and data.Spurs[data.EquippedSpur]) then
		data.EquippedSpur = ""
	end
	-- DataStores turn number keys into strings when the table has gaps; read both forms back
	local pen = {}
	for key, beast in pairs(data.Pen) do
		local slot = tonumber(key)
		if slot and type(beast) == "table" and Economy.Beasts[beast.id] and slot >= 1 and slot <= Economy.penSlots(data) then
			beast.kg = tonumber(beast.kg) or Economy.Beasts[beast.id].baseKg
			if not Economy.Mutations[beast.mutation] then
				beast.mutation = "None"
			end
			pen[math.floor(slot)] = beast
		end
	end
	data.Pen = pen
	if data.Cash ~= data.Cash or data.Cash < 0 then
		data.Cash = 0
	end
	if data.Speed ~= data.Speed or data.Speed < 0 then
		data.Speed = 0
	end
	return data
end

-- DataStores need string keys for a sparse pen; this is the table that actually gets saved.
function Economy.serialize(data)
	local out = copy(data)
	local pen = {}
	for slot, beast in pairs(data.Pen) do
		pen[tostring(slot)] = copy(beast)
	end
	out.Pen = pen
	return out
end

----------------------------------------------------------------------------------------------
-- Speed and movement
----------------------------------------------------------------------------------------------
function Economy.walkSpeed(speed)
	local m = GameConfig.Movement
	local ws = m.BaseWalkSpeed + m.WalkSpeedPerDecade * math.log(1 + math.max(0, speed), 10)
	return math.max(m.BaseWalkSpeed, math.min(m.MaxWalkSpeed, ws))
end

function Economy.towMultiplier(kg)
	for _, class in ipairs(GameConfig.Movement.TowClasses) do
		if kg < class.below then
			return class.multiplier
		end
	end
	return GameConfig.Movement.TowClasses[#GameConfig.Movement.TowClasses].multiplier
end

-- The stat test from MAP_SPEC section 2: a towing player outruns the Alpha when this is true.
function Economy.escapes(speed, kg, speedRequired)
	return speed * Economy.towMultiplier(kg) >= speedRequired
end

-- The furthest area this Speed can tow a beast home from (towing nothing heavy: x0.9)
function Economy.areaForSpeed(speed)
	local best = AreasConfig.Areas[1]
	for _, area in ipairs(AreasConfig.Areas) do
		if speed >= area.speedRequired then
			best = area
		end
	end
	return best
end

function Economy.nextArea(speed)
	for _, area in ipairs(AreasConfig.Areas) do
		if speed < area.speedRequired then
			return area
		end
	end
	return nil
end

----------------------------------------------------------------------------------------------
-- Treadmill and Spurs
----------------------------------------------------------------------------------------------
function Economy.treadmillTier(tier)
	return GameConfig.Treadmill.Tiers[tier]
end

function Economy.spurMultiplier(data)
	local spur = Economy.SpursById[data.EquippedSpur]
	return spur and spur.multiplier or 1
end

-- Speed for one treadmill step. boost is an extra multiplier (passes, events), default 1.
function Economy.stepGain(data, boost)
	return GameConfig.Treadmill.Tiers[data.TreadmillTier].speedPerStep * Economy.spurMultiplier(data) * (boost or 1)
end

function Economy.applyStep(data, boost)
	local gain = Economy.stepGain(data, boost)
	data.Speed = data.Speed + gain
	data.Stats.Steps = data.Stats.Steps + 1
	return gain
end

-- Returns ok, reason. Tiers unlock in order, so only the next one can be bought.
function Economy.buyTreadmill(data, tier)
	local info = GameConfig.Treadmill.Tiers[tier]
	if not info then
		return false, "No such treadmill"
	end
	if tier <= data.TreadmillTier then
		return false, "Already owned"
	end
	if tier ~= data.TreadmillTier + 1 then
		return false, "Buy " .. GameConfig.Treadmill.Tiers[data.TreadmillTier + 1].name .. " first"
	end
	if data.Cash < info.price then
		return false, "Not enough cash"
	end
	data.Cash = data.Cash - info.price
	data.TreadmillTier = tier
	return true
end

-- Buying a Spur equips it if it beats the one you wear.
function Economy.buySpur(data, spurId)
	local spur = Economy.SpursById[spurId]
	if not spur then
		return false, "No such Spurs"
	end
	if data.Spurs[spurId] then
		return false, "Already owned"
	end
	if data.Cash < spur.price then
		return false, "Not enough cash"
	end
	data.Cash = data.Cash - spur.price
	data.Spurs[spurId] = true
	if spur.multiplier > Economy.spurMultiplier(data) then
		data.EquippedSpur = spurId
	end
	return true
end

function Economy.equipSpur(data, spurId)
	if spurId == "" then
		data.EquippedSpur = ""
		return true
	end
	if not Economy.SpursById[spurId] then
		return false, "No such Spurs"
	end
	if not data.Spurs[spurId] then
		return false, "You don't own these Spurs"
	end
	data.EquippedSpur = spurId
	return true
end

----------------------------------------------------------------------------------------------
-- Pen and income
----------------------------------------------------------------------------------------------
function Economy.maxPenLevel()
	return GameConfig.Pen.MaxSlots - GameConfig.Pen.StartSlots + 1
end

function Economy.penSlots(data)
	return GameConfig.Pen.StartSlots + data.PenLevel - 1
end

-- nil when the pen is maxed
function Economy.penUpgradePrice(data)
	if data.PenLevel >= Economy.maxPenLevel() then
		return nil
	end
	return GameConfig.Pen.UpgradePrices[data.PenLevel]
end

function Economy.buyPenSlot(data)
	local price = Economy.penUpgradePrice(data)
	if not price then
		return false, "Pen is full size"
	end
	if data.Cash < price then
		return false, "Not enough cash"
	end
	data.Cash = data.Cash - price
	data.PenLevel = data.PenLevel + 1
	return true
end

-- Income = base x mutation x (kg / baseKg) ^ 0.617   (Systems and Scripts)
function Economy.beastIncome(beast)
	local info = Economy.Beasts[beast.id]
	if not info then
		return 0
	end
	local mutation = Economy.Mutations[beast.mutation or "None"] or Economy.Mutations.None
	local kg = math.max(0.01, beast.kg or info.baseKg)
	return info.baseIncome * mutation.multiplier * (kg / info.baseKg) ^ GameConfig.KgExponent
end

function Economy.penIncome(data)
	local total = 0
	for _, beast in pairs(data.Pen) do
		total = total + Economy.beastIncome(beast)
	end
	return total
end

-- Pays `seconds` of pen income (times an optional multiplier). Returns the amount paid.
function Economy.payIncome(data, seconds, multiplier)
	local amount = Economy.penIncome(data) * seconds * (multiplier or 1)
	data.Cash = data.Cash + amount
	data.Stats.CashEarned = data.Stats.CashEarned + amount
	return amount
end

-- Pays offline earnings for the time since LastOnline and resets it to now. Returns the amount.
function Economy.claimOffline(data, now)
	local cfg = GameConfig.Offline
	local away = (data.LastOnline > 0) and (now - data.LastOnline) or 0
	data.LastOnline = now
	if away < cfg.MinSeconds then
		return 0
	end
	return Economy.payIncome(data, math.min(away, cfg.MaxSeconds), cfg.Rate)
end

-- The lowest free active slot, or nil
function Economy.freeSlot(data)
	for slot = 1, Economy.penSlots(data) do
		if not data.Pen[slot] then
			return slot
		end
	end
	return nil
end

function Economy.addBeast(data, beast, slot)
	slot = slot or Economy.freeSlot(data)
	if not slot or data.Pen[slot] or slot > Economy.penSlots(data) then
		return nil, "No free pen slot"
	end
	if not Economy.Beasts[beast.id] then
		return nil, "No such beast"
	end
	data.Pen[slot] = { id = beast.id, kg = beast.kg or Economy.Beasts[beast.id].baseKg, mutation = beast.mutation or "None" }
	return slot
end

-- Inside Roblox the module sets itself up from its sibling modules; the tests call init().
if script ~= nil then
	Economy.init(require(script.Parent.GameConfig), require(script.Parent.AreasConfig))
end

return Economy
