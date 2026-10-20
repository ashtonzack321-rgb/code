--[[
	GameConfig  (ReplicatedStorage.Shared.GameConfig)

	Economy and tuning numbers for the gameplay services: treadmill tiers, Spurs, pen upgrades,
	the Speed -> WalkSpeed curve and the save settings. Map geometry lives in AreasConfig.

	Sources:
	  * Roblox Research/Games/Steal An Egg.md: treadmill tiers (+2 .. +3K per step, Free .. $15Qa)
	    and trails (1.5x .. 20x), which our treadmills and Spurs copy one for one
	  * Roblox Research/My Game/UI Mockup/Shop.dc.html: the names and prices of the first 6 tiers
	  * game/MAP_SPEC.md section 2: the WalkSpeed curve and the towing multipliers
	[assumed] marks a number the research does not give.

	Plain data plus Lua 5.3-compatible Luau, so the tests in game/tests can load it.
]]

local GameConfig = {}

GameConfig.Version = 1

----------------------------------------------------------------------------------------------
-- Speed -> WalkSpeed (MAP_SPEC section 2)
----------------------------------------------------------------------------------------------
GameConfig.Movement = {
	BaseWalkSpeed = 16,
	WalkSpeedPerDecade = 12,   -- WalkSpeed = 16 + 12 * log10(1 + Speed)
	MaxWalkSpeed = 160,
	-- Towing multipliers by weight class (kg below `below`), heaviest last
	TowClasses = {
		{ below = 100, multiplier = 0.9 },
		{ below = 1000, multiplier = 0.8 },
		{ below = 10000, multiplier = 0.7 },
		{ below = math.huge, multiplier = 0.55 },
	},
}

----------------------------------------------------------------------------------------------
-- Treadmill (Steal An Egg's 11 tiers, re-themed as wagon wheels). Tiers unlock in order.
----------------------------------------------------------------------------------------------
GameConfig.Treadmill = {
	StepSeconds = 0.5,         -- one step every 0.5 s while you stand on your own belt [assumed]
	Tiers = {
		{ tier = 1,  name = "Wooden",      rarity = "Common",    speedPerStep = 2,    price = 0 },
		{ tier = 2,  name = "Iron",        rarity = "Uncommon",  speedPerStep = 5,    price = 15000 },
		{ tier = 3,  name = "Copper",      rarity = "Rare",      speedPerStep = 12,   price = 250000 },
		{ tier = 4,  name = "Silver Spur", rarity = "Epic",      speedPerStep = 30,   price = 5000000 },
		{ tier = 5,  name = "Gold Rush",   rarity = "Legendary", speedPerStep = 80,   price = 120000000 },
		{ tier = 6,  name = "Frostbite",   rarity = "Mythic",    speedPerStep = 100,  price = 3000000000 },
		{ tier = 7,  name = "Comet",       rarity = "Cosmic",    speedPerStep = 200,  price = 75000000000 },
		{ tier = 8,  name = "Outlaw",      rarity = "Secret",    speedPerStep = 500,  price = 2000000000000 },
		{ tier = 9,  name = "Hellfire",    rarity = "Eternal",   speedPerStep = 1000, price = 50000000000000 },
		{ tier = 10, name = "Halo",        rarity = "Divine",    speedPerStep = 2000, price = 1000000000000000 },
		{ tier = 11, name = "Astral",      rarity = "Divine",    speedPerStep = 3000, price = 15000000000000000 },
	},
}

----------------------------------------------------------------------------------------------
-- Spurs (Steal An Egg's trails): multiply treadmill gains only. Own many, equip one.
-- robuxPrice is shown in the shop; the developer products are wired up in MarketService later.
----------------------------------------------------------------------------------------------
GameConfig.Spurs = {
	{ id = "Rusty",    name = "Rusty Spurs",    rarity = "Common",    multiplier = 1.5, price = 100 },
	{ id = "Iron",     name = "Iron Spurs",     rarity = "Uncommon",  multiplier = 2,   price = 5000,             robuxPrice = 8 },
	{ id = "Copper",   name = "Copper Spurs",   rarity = "Rare",      multiplier = 2.5, price = 75000,            robuxPrice = 12 },
	{ id = "Silver",   name = "Silver Spurs",   rarity = "Epic",      multiplier = 3,   price = 1500000,          robuxPrice = 19 },
	{ id = "Gold",     name = "Gold Spurs",     rarity = "Legendary", multiplier = 4,   price = 90000000 },
	{ id = "Diamond",  name = "Diamond Spurs",  rarity = "Cosmic",    multiplier = 5,   price = 2000000000 },
	{ id = "Shadow",   name = "Shadow Spurs",   rarity = "Secret",    multiplier = 7,   price = 400000000000 },      -- [assumed] price
	{ id = "Eternal",  name = "Eternal Spurs",  rarity = "Eternal",   multiplier = 10,  price = 12500000000000 },
	{ id = "Divine",   name = "Divine Spurs",   rarity = "Divine",    multiplier = 14,  price = 300000000000000 },
	{ id = "Moonbeam", name = "Moonbeam Spurs", rarity = "Divine",    multiplier = 20,  price = 20000000000000000 }, -- [assumed] price
}

----------------------------------------------------------------------------------------------
-- Ranch pen: 7 slots at level 1, +1 slot per level up to 19 (Core Loop section 5).
-- The shop mockup shows Lv5 at $75M and Lv6 at $50B; the rest are [assumed] on a similar curve.
----------------------------------------------------------------------------------------------
GameConfig.Pen = {
	StartSlots = 7,
	MaxSlots = 19,
	-- UpgradePrices[n] buys pen level n + 1 (slot 7 + n)
	UpgradePrices = {
		50000, 2000000, 25000000, 75000000, 50000000000, 500000000000, 5000000000000,
		50000000000000, 500000000000000, 5000000000000000, 50000000000000000, 500000000000000000,
	},
	IncomeTickSeconds = 1,
}

----------------------------------------------------------------------------------------------
-- New players
----------------------------------------------------------------------------------------------
GameConfig.NewPlayer = {
	Cash = 100,
	Speed = 0,
	-- A tamed Prairie Chick in slot 1, so the pen earns from the first second [assumed]
	StarterBeasts = {
		{ id = "PrairieChick", kg = 2, mutation = "None" },
	},
}

-- Mutations multiply income (Systems and Scripts: Income = base x mutation x (kg/baseKg)^0.617)
GameConfig.Mutations = {
	{ id = "None",    multiplier = 1 },
	{ id = "Silver",  multiplier = 1.5 },   -- [assumed]
	{ id = "Golden",  multiplier = 2 },     -- [assumed]
	{ id = "Rainbow", multiplier = 5 },     -- [assumed]
}
GameConfig.KgExponent = 0.617

----------------------------------------------------------------------------------------------
-- Gamepasses shown in the shop (Monetization and Launch.md). gamePassId stays 0 until the pass
-- is created on the Creator Dashboard; the shop then says "Coming soon!" instead of prompting.
-- In descriptions, <green>...</green> marks the green highlight (as in "Eggs Grow x2 faster!").
----------------------------------------------------------------------------------------------
GameConfig.Passes = {
	{ id = "TwoXTaming", name = "x2 Taming", description = "Beasts Tame <green>x2</green> faster!", robux = 467,
		gamePassId = 0, icon = "TwoXTaming", card = "Rainbow" },
	{ id = "TwoXMoney", name = "x2 Money", description = "Get <green>x2</green> Money!", robux = 399,
		gamePassId = 0, icon = "TwoXMoney", card = "Gold" },
	{ id = "VipRanch", name = "VIP Ranch", description = "<green>+2</green> pen slots and a gold gate!", robux = 299,
		gamePassId = 0, icon = "Vip", card = "Purple" },
	{ id = "FastHorse", name = "Fast Horse", description = "Run <green>+25%</green> faster!", robux = 199,
		gamePassId = 0, icon = "FastHorse", card = "Blue" },
}

-- Icons: images already uploaded to Roblox by the Check-UI kit (MIT, game/vendor/CheckUI; the
-- names in comments are their CheckUIIcons paths), with an emoji to show if an image fails to load.
-- To change one, find another id in game/vendor/CheckUI/CheckUIIcons.luau.
GameConfig.Icons = {
	Featured = { image = "rbxassetid://112112253357068", emoji = "\u{1F3F7}\u{FE0F}" }, -- Main/Shopping_Bag/Red_Shopping_Bag_1st_Outline
	Speed = { image = "rbxassetid://98292714980053", emoji = "\u{1F45F}" },        -- Item/Shoe/Blue_Shoe_1st_Outline
	Money = { image = "rbxassetid://88694661500877", emoji = "\u{1F4B5}" },        -- Currency/Cash/Green_Cash_1st_Outline
	Index = { image = "rbxassetid://116366045684496", emoji = "\u{1F4D6}" },       -- Item/Book/Blue_Book_1st_Outline
	Gift = { image = "rbxassetid://88859793149024", emoji = "\u{1F381}" },         -- Item/Gift/Gift_White
	Treadmill = { image = "rbxassetid://135086426027210", emoji = "\u{1F3C3}" },   -- Item/Shoe/Red_Shoe_1st_Outline
	Spurs = { image = "rbxassetid://105103627769338", emoji = "\u{2B50}" },        -- Main/Star/Golden_Star_1st_Outline
	Pen = { image = "rbxassetid://113557408634141", emoji = "\u{1F3E0}" },         -- Main/House/Green_House_1st_Outline
	Robux = { image = "rbxassetid://132185731364109", emoji = "R$" },              -- Currency/Robux/Robux_White
	TwoXTaming = { image = "rbxassetid://138525712797372", emoji = "\u{23F1}\u{FE0F}" }, -- Item/Clock/Golden_Clock_1st_Outline
	TwoXMoney = { image = "rbxassetid://89267825858001", emoji = "\u{1F4B0}" },    -- Currency/Cash/Golden_Cash_1st_Outline
	Vip = { image = "rbxassetid://87880162965828", emoji = "\u{1F451}" },          -- Exclusive/VIP/VIP_1st_Outline
	FastHorse = { image = "rbxassetid://117522200604233", emoji = "\u{26A1}" },    -- Main/Lighting/Blue_Lighting_1st_Outline
}

-- Check-UI's shared UI textures (also uploaded already)
GameConfig.UIAssets = {
	Checker = "rbxassetid://385956923",   -- 2 x 2 checker squares per tile (damier overlays)
	Sunburst = "rbxassetid://130563114903838",
}

----------------------------------------------------------------------------------------------
-- Saving
----------------------------------------------------------------------------------------------
GameConfig.Data = {
	StoreName = "PlayerData_v1",
	AutosaveSeconds = 120,
	SessionLockSeconds = 600,  -- a lock older than this is treated as abandoned (server crash)
	LoadRetries = 5,
}

return GameConfig
