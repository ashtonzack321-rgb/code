--[[
	AreasConfig  (ReplicatedStorage.Shared.AreasConfig)

	The single source of truth for Steal a Beast's 10 areas, the Town and the 7 ranch plots.
	MapBuilder builds the map from this table, and the gameplay services will read it later.

	It is plain data (numbers, strings and tables, no Roblox types), so the server, the
	client and the Lua test harness in game/tests can all load it.

	Sources:
	  * game/MAP_SPEC.md: coordinates, lengths, Speed signs, themes and lighting (sections 2, 4-8 and 11)
	  * Roblox Research/My Game/Areas and Beasts.md: Alphas, beasts, rarities, base $/s and tame times
	[assumed] marks a number the design notes do not give yet:
	  * every baseKg is [assumed]; the notes do not list base weights yet
	  * a baseIncome or tameSeconds with an [assumed] comment was picked inside that rarity's range
	Colours are {r, g, b} (0-255). Materials are Enum.Material names.

	Written in the Luau subset that is also valid Lua 5.3, so the tests can run it.
]]

local AreasConfig = {}

AreasConfig.Version = 1

----------------------------------------------------------------------------------------------
-- Rarities (Areas and Beasts.md "Rarity ladder"). tameSeconds is the default for that rarity;
-- a beast's own tameSeconds overrides it.
----------------------------------------------------------------------------------------------
AreasConfig.Rarities = {
	{ id = "Common",    order = 1,  color = { 154, 160, 166 }, incomeMin = 1,          incomeMax = 6,          tameSeconds = 10 },
	{ id = "Uncommon",  order = 2,  color = { 60, 207, 90 },   incomeMin = 8,          incomeMax = 18,         tameSeconds = 30 },    -- [assumed] tame time
	{ id = "Rare",      order = 3,  color = { 47, 155, 255 },  incomeMin = 35,         incomeMax = 280,        tameSeconds = 60 },    -- [assumed] tame time
	{ id = "Epic",      order = 4,  color = { 164, 77, 255 },  incomeMin = 180,        incomeMax = 4000,       tameSeconds = 120 },
	{ id = "Legendary", order = 5,  color = { 255, 198, 26 },  incomeMin = 1800,       incomeMax = 225000,     tameSeconds = 240 },
	{ id = "Mythic",    order = 6,  color = { 255, 59, 59 },   incomeMin = 16000,      incomeMax = 1250000,    tameSeconds = 360 },   -- [assumed] tame time
	{ id = "Cosmic",    order = 7,  color = { 46, 230, 214 },  incomeMin = 220000,     incomeMax = 25000000,   tameSeconds = 900 },   -- [assumed] tame time
	{ id = "Secret",    order = 8,  color = { 17, 17, 17 },    incomeMin = 3500000,    incomeMax = 350000000,  tameSeconds = 7200,  rainbowText = true },
	{ id = "Eternal",   order = 9,  color = { 255, 79, 216 },  incomeMin = 65000000,   incomeMax = 1800000000, tameSeconds = 25200 },
	{ id = "Divine",    order = 10, color = { 255, 246, 194 }, incomeMin = 1000000000, incomeMax = nil,        tameSeconds = 57600 },
}

----------------------------------------------------------------------------------------------
-- Town (MAP_SPEC sections 0, 4 and 8)
----------------------------------------------------------------------------------------------
AreasConfig.Town = {
	MapVersion = 1,
	GateX = 400,            -- the red line; crossing it toward -X ends a chase
	LaneHalfWidth = 64,
	TrailHalfWidth = 20,
	SpawnPosition = { 0, 0.5, 0 },
	-- TownBounds covers X -96..400, Z -128..128 (Alphas give up, Sundown leaves you alone, no traps)
	Bounds = { minX = -96, maxX = 400, minZ = -128, maxZ = 128 },
	-- Lighting profile stored as attributes on the Town folder (section 8)
	Lighting = {
		AtmDensity = 0.25, AtmHaze = 0.6, AtmColor = { 210, 180, 140 }, AtmDecay = { 120, 110, 100 }, AtmGlare = 0,
		CCTint = { 255, 246, 232 }, CCSaturation = 0.05, CCContrast = 0, CCBrightness = 0,
		ClockOverride = -1, Weather = "none",
	},
	-- Base Lighting for the whole place (section 8)
	BaseLighting = {
		ClockTime = 14.5,
		Brightness = 2.5,
		Ambient = { 90, 80, 70 },
		OutdoorAmbient = { 140, 130, 120 },
		BloomIntensity = 0.4,
		BloomIntensityCosmic = 1.2,
	},
	-- Workspace streaming (section 9)
	Streaming = { MinRadius = 256, TargetRadius = 1024 },
}

----------------------------------------------------------------------------------------------
-- Ranch plots (MAP_SPEC section 5)
----------------------------------------------------------------------------------------------
AreasConfig.Plots = {
	Count = 7,
	Pitch = 72,              -- 64-wide plot + 8-wide alley
	Width = 64,
	Depth = 80,
	PenStartSlots = 7,       -- slots 1-7 are active at PenLevel 1
	PenBuiltSlots = 10,      -- pads built with the map
	PenMaxSlots = 19,        -- 11-19 are created by RanchService on pen upgrades
	TreadmillTiers = 11,
	-- x, z = pivot (gate faces the street). rotated = true means CFrame.Angles(0, math.pi, 0).
	List = {
		{ index = 1, row = "North", x = 112, z = 80,  rotated = false },
		{ index = 2, row = "North", x = 184, z = 80,  rotated = false },
		{ index = 3, row = "North", x = 256, z = 80,  rotated = false },
		{ index = 4, row = "North", x = 328, z = 80,  rotated = false },
		{ index = 5, row = "South", x = 112, z = -80, rotated = true },
		{ index = 6, row = "South", x = 184, z = -80, rotated = true },
		{ index = 7, row = "South", x = 256, z = -80, rotated = true },
	},
	-- Pen slot pad centres in plot-local {x, z} (section 5.4). Local -Z is the street side.
	SlotLayout = {
		{ -24, -20 }, { -12, -20 }, { 0, -20 }, { 12, -20 }, { 24, -20 },
		{ -24, -7 },  { -12, -7 },  { 0, -7 },  { 12, -7 },  { 24, -7 },
		{ -24, 6 },   { -12, 6 },   { 0, 6 },   { 12, 6 },   { 24, 6 },
		{ -24, 19 },  { -12, 19 },  { 12, 19 },  { 24, 19 },
	},
}

----------------------------------------------------------------------------------------------
-- Lane (MAP_SPEC section 6.1)
----------------------------------------------------------------------------------------------
AreasConfig.Lane = {
	TrailheadStartX = 400,
	TrailheadEndX = 432,     -- Area 1 starts here
	AreasEndX = 3600,        -- Area 10 ends here; FrontierEnd runs 3600..3632
	FrontierEndX = 3632,
	WaypointX = { 400, 432, 592, 784, 1008, 1264, 1552, 1872, 2224, 2608, 3024, 3600 },
	StampedeStartX = 2608,   -- start of Ghost Town
	StampedeEndX = 440,      -- just past the red line
	StampedeSeconds = 60,
}

----------------------------------------------------------------------------------------------
-- The 10 areas (MAP_SPEC 6.2-6.4, 7, 8 and Areas and Beasts.md)
-- herdSide: +1 = north (+Z, the runner's right), -1 = south.
----------------------------------------------------------------------------------------------
AreasConfig.Areas = {
	{
		index = 1, id = "DustyPrairie", name = "Dusty Prairie", saeSlot = "Forest",
		sign = "0 SPEED", speedRequired = 0,
		startX = 432, endX = 592, length = 160,
		herdX = 528, herdSide = 1, herdSpacing = 10, herdFraction = 0.6,
		cliffHeight = 18, alphaBedDiameter = 16,
		font = "LuckiestGuy",
		alpha = { id = "OlStompy", name = "Ol' Stompy", species = "Bull" },
		indexWeapon = nil,
		theme = {
			trail     = { material = "Ground",     color = { 170, 132, 90 } },
			shoulder  = { material = "Grass",      color = { 150, 172, 88 } },
			wall      = { material = "Ground",     color = { 182, 146, 100 } },
			crest     = { material = "Grass",      color = { 120, 150, 70 } },
			toe       = { material = "Ground",     color = { 170, 134, 92 } },
			archPost  = { material = "Wood",       color = { 122, 84, 50 } },
			archCap   = { material = "Wood",       color = { 122, 84, 50 } },
			archBoard = { material = "WoodPlanks", color = { 176, 128, 78 } },
			signText  = { 60, 36, 20 },
			herdZone  = { material = "Grass",      color = { 176, 196, 104 } },
			alphaBed  = { material = "Grass",      color = { 220, 190, 100 } },
		},
		lighting = {
			AtmDensity = 0.25, AtmHaze = 0.5, AtmColor = { 199, 170, 135 }, AtmDecay = { 106, 112, 125 }, AtmGlare = 0,
			CCTint = { 255, 248, 235 }, CCSaturation = 0.10, CCContrast = 0, CCBrightness = 0,
			ClockOverride = -1, Weather = "none",
		},
		beasts = {
			{ id = "PrairieChick", name = "Prairie Chick", rarity = "Common",    baseIncome = 1,    baseKg = 2,   tameSeconds = 10 },
			{ id = "Jackrabbit",   name = "Jackrabbit",    rarity = "Common",    baseIncome = 2,    baseKg = 3,   tameSeconds = 15 },
			{ id = "BillyGoat",    name = "Billy Goat",    rarity = "Uncommon",  baseIncome = 8,    baseKg = 45 },
			{ id = "BarnOwl",      name = "Barn Owl",      rarity = "Rare",      baseIncome = 35,   baseKg = 1 },
			{ id = "Armadillo",    name = "Armadillo",     rarity = "Rare",      baseIncome = 45,   baseKg = 6 },
			{ id = "RedFox",       name = "Red Fox",       rarity = "Epic",      baseIncome = 180,  baseKg = 8 },
			{ id = "Grizzly",      name = "Grizzly",       rarity = "Epic",      baseIncome = 240,  baseKg = 350 },
			{ id = "GoldenGoose",  name = "Golden Goose",  rarity = "Legendary", baseIncome = 1800, baseKg = 5,   tameSeconds = 300, top = true },
		},
	},
	{
		index = 2, id = "CactusCanyon", name = "Cactus Canyon", saeSlot = "Lake",
		sign = "900 SPEED", speedRequired = 900,
		startX = 592, endX = 784, length = 192,
		herdX = 707, herdSide = -1, herdSpacing = 10, herdFraction = 0.6,
		cliffHeight = 32, alphaBedDiameter = 16,
		font = "LuckiestGuy",
		alpha = { id = "RattlesnakeKing", name = "Rattlesnake King", species = "Rattlesnake" },
		indexWeapon = "Cactus Club",
		theme = {
			trail     = { material = "Ground",     color = { 196, 138, 92 } },
			shoulder  = { material = "Sand",       color = { 226, 170, 112 } },
			wall      = { material = "Sandstone",  color = { 196, 104, 64 } },
			crest     = { material = "Sandstone",  color = { 222, 142, 92 } },
			toe       = { material = "Sandstone",  color = { 170, 90, 56 } },
			archPost  = { material = "Sandstone",  color = { 186, 104, 70 } },
			archCap   = { material = "Marble",     color = { 240, 232, 214 } },
			archBoard = { material = "WoodPlanks", color = { 160, 110, 70 } },
			signText  = nil,
			herdZone  = { material = "Sand",       color = { 232, 196, 140 } },
			alphaBed  = { material = "Slate",      color = { 150, 120, 96 } },
		},
		lighting = {
			AtmDensity = 0.30, AtmHaze = 1.6, AtmColor = { 230, 180, 130 }, AtmDecay = { 150, 100, 70 }, AtmGlare = 0.4,
			CCTint = { 255, 236, 214 }, CCSaturation = 0.15, CCContrast = 0.05, CCBrightness = 0,
			ClockOverride = -1, Weather = "dust",
		},
		beasts = {
			{ id = "HornedToad",   name = "Horned Toad",   rarity = "Common",    baseIncome = 3,      baseKg = 1 },
			{ id = "Roadrunner",   name = "Roadrunner",    rarity = "Common",    baseIncome = 4,      baseKg = 2 },
			{ id = "GilaMonster",  name = "Gila Monster",  rarity = "Uncommon",  baseIncome = 12,     baseKg = 3 },
			{ id = "Coyote",       name = "Coyote",        rarity = "Rare",      baseIncome = 60,     baseKg = 15 },
			{ id = "Vulture",      name = "Vulture",       rarity = "Epic",      baseIncome = 320,    baseKg = 10,   tameSeconds = 120 }, -- [assumed] income
			{ id = "CactusCamel",  name = "Cactus Camel",  rarity = "Epic",      baseIncome = 450,    baseKg = 600 },                      -- [assumed] income
			{ id = "ThunderBison", name = "Thunder Bison", rarity = "Legendary", baseIncome = 2800,   baseKg = 900 },
			{ id = "CanyonWyrm",   name = "Canyon Wyrm",   rarity = "Cosmic",    baseIncome = 220000, baseKg = 2500, tameSeconds = 1500, top = true },
		},
	},
	{
		index = 3, id = "GoldRushMine", name = "Gold Rush Mine", saeSlot = "Desert",
		sign = "10K SPEED", speedRequired = 10000,
		startX = 784, endX = 1008, length = 224,
		herdX = 918, herdSide = 1, herdSpacing = 10, herdFraction = 0.6,
		cliffHeight = 36, alphaBedDiameter = 16,
		font = "LuckiestGuy",
		alpha = { id = "BigDigger", name = "Big Digger", species = "Giant Mole" },
		indexWeapon = "Miner's Pickaxe",
		theme = {
			trail     = { material = "Ground",     color = { 120, 98, 78 } },
			shoulder  = { material = "Pebble",     color = { 128, 112, 96 } },
			wall      = { material = "Slate",      color = { 92, 84, 80 } },
			crest     = { material = "Rock",       color = { 110, 100, 92 } },
			toe       = { material = "Pebble",     color = { 110, 98, 86 } },
			archPost  = { material = "Wood",       color = { 110, 78, 46 } },
			archCap   = { material = "Neon",       color = { 255, 190, 90 } },
			archBoard = { material = "WoodPlanks", color = { 130, 92, 56 } },
			signText  = nil,
			herdZone  = { material = "Ground",     color = { 150, 120, 90 } },
			alphaBed  = { material = "Mud",        color = { 110, 84, 60 } },
		},
		lighting = {
			AtmDensity = 0.35, AtmHaze = 1.0, AtmColor = { 170, 150, 120 }, AtmDecay = { 90, 80, 70 }, AtmGlare = 0,
			CCTint = { 255, 236, 200 }, CCSaturation = 0, CCContrast = 0.10, CCBrightness = -0.03,
			ClockOverride = -1, Weather = "dust",
		},
		beasts = {
			{ id = "MineRat",          name = "Mine Rat",          rarity = "Common",    baseIncome = 6,      baseKg = 1,   tameSeconds = 20 },
			{ id = "CaveBat",          name = "Cave Bat",          rarity = "Uncommon",  baseIncome = 15,     baseKg = 1 },   -- [assumed] income
			{ id = "RockMole",         name = "Rock Mole",         rarity = "Rare",      baseIncome = 120,    baseKg = 12 },  -- [assumed] income
			{ id = "CrystalArmadillo", name = "Crystal Armadillo", rarity = "Legendary", baseIncome = 3600,   baseKg = 40 },
			{ id = "OreGolemPup",      name = "Ore Golem Pup",     rarity = "Mythic",    baseIncome = 16000,  baseKg = 800 },
			{ id = "NuggetMule",       name = "Nugget Mule",       rarity = "Mythic",    baseIncome = 18500,  baseKg = 450 },
			{ id = "LanternBat",       name = "Lantern Bat",       rarity = "Epic",      baseIncome = 650,    baseKg = 4 },   -- [assumed] income
			{ id = "GoldenStallion",   name = "Golden Stallion",   rarity = "Cosmic",    baseIncome = 280000, baseKg = 700, top = true },
		},
	},
	{
		index = 4, id = "BayouSwamp", name = "Bayou Swamp", saeSlot = "Jungle",
		sign = "40K SPEED", speedRequired = 40000,
		startX = 1008, endX = 1264, length = 256,
		herdX = 1162, herdSide = -1, herdSpacing = 12, herdFraction = 0.6,
		cliffHeight = 28, alphaBedDiameter = 16,
		font = "LuckiestGuy",
		alpha = { id = "CrocKing", name = "Croc King", species = "Crocodile" },
		indexWeapon = "Gator Tail Whip",
		theme = {
			trail     = { material = "WoodPlanks", color = { 116, 90, 60 } },
			shoulder  = { material = "Mud",        color = { 84, 74, 50 } },
			wall      = { material = "LeafyGrass", color = { 52, 78, 44 } },
			crest     = { material = "LeafyGrass", color = { 40, 64, 36 } },
			toe       = { material = "Mud",        color = { 70, 62, 44 } },
			archPost  = { material = "Wood",       color = { 90, 70, 50 } },
			archCap   = { material = "LeafyGrass", color = { 70, 100, 50 } },
			archBoard = { material = "WoodPlanks", color = { 100, 80, 56 } },
			signText  = nil,
			herdZone  = { material = "Grass",      color = { 70, 100, 56 } },
			alphaBed  = { material = "Mud",        color = { 70, 60, 44 } },
		},
		lighting = {
			AtmDensity = 0.45, AtmHaze = 2.0, AtmColor = { 120, 150, 110 }, AtmDecay = { 60, 80, 60 }, AtmGlare = 0,
			CCTint = { 225, 255, 225 }, CCSaturation = -0.05, CCContrast = 0, CCBrightness = -0.02,
			ClockOverride = -1, Weather = "fireflies",
		},
		beasts = {
			{ id = "Bullfrog",       name = "Bullfrog",        rarity = "Common",    baseIncome = 6,       baseKg = 1 },     -- [assumed] income
			{ id = "SwampHog",       name = "Swamp Hog",       rarity = "Uncommon",  baseIncome = 18,      baseKg = 120 },   -- [assumed] income
			{ id = "Heron",          name = "Heron",           rarity = "Rare",      baseIncome = 280,     baseKg = 4 },     -- [assumed] income
			{ id = "SnappingTurtle", name = "Snapping Turtle", rarity = "Epic",      baseIncome = 1200,    baseKg = 60 },    -- [assumed] income
			{ id = "Gator",          name = "Gator",           rarity = "Mythic",    baseIncome = 28000,   baseKg = 500 },
			{ id = "FireflyMoth",    name = "Firefly Moth",    rarity = "Legendary", baseIncome = 9000,    baseKg = 1 },     -- [assumed] income
			{ id = "MudBuffalo",     name = "Mud Buffalo",     rarity = "Epic",      baseIncome = 2200,    baseKg = 900 },   -- [assumed] income
			{ id = "BayouHydra",     name = "Bayou Hydra",     rarity = "Secret",    baseIncome = 3500000, baseKg = 8000, tameSeconds = 5400, top = true },
		},
	},
	{
		index = 5, id = "FrostPeak", name = "Frost Peak", saeSlot = "Snow",
		sign = "170K SPEED", speedRequired = 170000,
		startX = 1264, endX = 1552, length = 288,
		herdX = 1437, herdSide = 1, herdSpacing = 12, herdFraction = 0.6,
		cliffHeight = 40, alphaBedDiameter = 16,
		font = "LuckiestGuy",
		alpha = { id = "YetiMoose", name = "Yeti Moose", species = "Moose" },
		indexWeapon = "Ice Whip",
		theme = {
			trail     = { material = "Snow",       color = { 204, 212, 222 } },
			shoulder  = { material = "Snow",       color = { 236, 240, 246 } },
			wall      = { material = "Rock",       color = { 150, 160, 175 } },
			crest     = { material = "Snow",       color = { 240, 244, 250 } },
			toe       = { material = "Snow",       color = { 225, 232, 240 } },
			archPost  = { material = "Ice",        color = { 170, 210, 240 }, transparency = 0.1 },
			archCap   = { material = "Ice",        color = { 170, 210, 240 }, transparency = 0.1 },
			archBoard = { material = "WoodPlanks", color = { 120, 86, 56 } },
			signText  = nil,
			herdZone  = { material = "Snow",       color = { 250, 252, 255 } },
			alphaBed  = { material = "Glacier",    color = { 200, 225, 245 } },
		},
		lighting = {
			AtmDensity = 0.40, AtmHaze = 1.2, AtmColor = { 220, 230, 245 }, AtmDecay = { 150, 170, 200 }, AtmGlare = 0.6,
			CCTint = { 235, 245, 255 }, CCSaturation = -0.10, CCContrast = 0, CCBrightness = 0.05,
			ClockOverride = -1, Weather = "snow",
		},
		beasts = {
			{ id = "SnowHare",      name = "Snow Hare",      rarity = "Common",    baseIncome = 6,        baseKg = 4 },    -- [assumed] income
			{ id = "MountainGoat",  name = "Mountain Goat",  rarity = "Uncommon",  baseIncome = 18,       baseKg = 90 },   -- [assumed] income
			{ id = "SnowWolf",      name = "Snow Wolf",      rarity = "Rare",      baseIncome = 280,      baseKg = 50 },   -- [assumed] income
			{ id = "PolarBear",     name = "Polar Bear",     rarity = "Epic",      baseIncome = 4000,     baseKg = 700,  tameSeconds = 120 }, -- [assumed] income
			{ id = "FrostLynx",     name = "Frost Lynx",     rarity = "Legendary", baseIncome = 40000,    baseKg = 25 },   -- [assumed] income
			{ id = "FrostMammoth",  name = "Frost Mammoth",  rarity = "Cosmic",    baseIncome = 400000,   baseKg = 6000 },
			{ id = "IceElk",        name = "Ice Elk",        rarity = "Mythic",    baseIncome = 150000,   baseKg = 450 },  -- [assumed] income
			{ id = "FrostWyvern",   name = "Frost Wyvern",   rarity = "Eternal",   baseIncome = 65000000, baseKg = 3000, tameSeconds = 14400, top = true },
		},
	},
	{
		index = 6, id = "VolcanoRidge", name = "Volcano Ridge", saeSlot = "Volcano",
		sign = "700K SPEED", speedRequired = 700000,
		startX = 1552, endX = 1872, length = 320,
		herdX = 1744, herdSide = -1, herdSpacing = 12, herdFraction = 0.6,
		cliffHeight = 44, alphaBedDiameter = 16,
		font = "LuckiestGuy",
		alpha = { id = "MagmaOx", name = "Magma Ox", species = "Ox" },
		indexWeapon = "Lava Bat",
		theme = {
			trail     = { material = "CrackedLava", color = { 90, 60, 50 } },
			shoulder  = { material = "Basalt",      color = { 58, 52, 52 } },
			wall      = { material = "Basalt",      color = { 50, 44, 44 } },
			crest     = { material = "Rock",        color = { 70, 60, 58 } },
			toe       = { material = "Basalt",      color = { 44, 40, 40 } },
			archPost  = { material = "Basalt",      color = { 60, 50, 50 } },
			archCap   = { material = "Neon",        color = { 255, 110, 30 } },
			archBoard = { material = "Slate",       color = { 60, 50, 48 } },
			signText  = { 255, 150, 60 },
			herdZone  = { material = "Ground",      color = { 80, 64, 58 } },
			alphaBed  = { material = "CrackedLava", color = { 120, 60, 40 } },
		},
		lighting = {
			AtmDensity = 0.45, AtmHaze = 2.2, AtmColor = { 255, 140, 90 }, AtmDecay = { 120, 50, 30 }, AtmGlare = 0.2,
			CCTint = { 255, 225, 205 }, CCSaturation = 0.10, CCContrast = 0.12, CCBrightness = 0,
			ClockOverride = -1, Weather = "embers",
		},
		beasts = {
			{ id = "AshLizard",        name = "Ash Lizard",        rarity = "Common",    baseIncome = 6,         baseKg = 3 },     -- [assumed] income
			{ id = "FireFox",          name = "Fire Fox",          rarity = "Uncommon",  baseIncome = 18,        baseKg = 9 },     -- [assumed] income
			{ id = "EmberHog",         name = "Ember Hog",         rarity = "Rare",      baseIncome = 280,       baseKg = 150 },   -- [assumed] income
			{ id = "LavaOx",           name = "Lava Ox",           rarity = "Epic",      baseIncome = 9500,      baseKg = 1100 },
			{ id = "CinderRam",        name = "Cinder Ram",        rarity = "Legendary", baseIncome = 90000,     baseKg = 160 },   -- [assumed] income
			{ id = "MagmaTortoise",    name = "Magma Tortoise",    rarity = "Mythic",    baseIncome = 400000,    baseKg = 2500 },  -- [assumed] income
			{ id = "InfernoMammoth",   name = "Inferno Mammoth",   rarity = "Secret",    baseIncome = 8000000,   baseKg = 9000 },
			{ id = "HellfireStallion", name = "Hellfire Stallion", rarity = "Eternal",   baseIncome = 100000000, baseKg = 1200, top = true },
		},
	},
	{
		index = 7, id = "StormMesa", name = "Storm Mesa", saeSlot = "Abyss Ocean",
		sign = "2.5M SPEED", speedRequired = 2500000,
		startX = 1872, endX = 2224, length = 352,
		herdX = 2083, herdSide = 1, herdSpacing = 14, herdFraction = 0.6,
		cliffHeight = 40, alphaBedDiameter = 16,
		font = "LuckiestGuy",
		alpha = { id = "StormGriffin", name = "Storm Griffin", species = "Griffin" },
		indexWeapon = "Thunder Whip",
		theme = {
			trail     = { material = "Ground", color = { 128, 116, 104 } },
			shoulder  = { material = "Slate",  color = { 112, 112, 122 } },
			wall      = { material = "Slate",  color = { 84, 86, 98 } },
			crest     = { material = "Rock",   color = { 100, 102, 116 } },
			toe       = { material = "Slate",  color = { 96, 96, 108 } },
			archPost  = { material = "Slate",  color = { 90, 92, 104 } },
			archCap   = { material = "Neon",   color = { 120, 220, 255 } },
			archBoard = { material = "Metal",  color = { 80, 84, 92 } },
			signText  = { 255, 230, 90 },
			herdZone  = { material = "Grass",  color = { 110, 124, 104 } },
			alphaBed  = { material = "Wood",   color = { 110, 86, 60 } },
		},
		lighting = {
			AtmDensity = 0.50, AtmHaze = 2.4, AtmColor = { 130, 145, 170 }, AtmDecay = { 70, 80, 100 }, AtmGlare = 0,
			CCTint = { 215, 225, 255 }, CCSaturation = -0.25, CCContrast = 0.10, CCBrightness = -0.05,
			ClockOverride = -1, Weather = "rain+lightning",
		},
		beasts = {
			{ id = "SparkCoyote",       name = "Spark Coyote",       rarity = "Common",    baseIncome = 6,         baseKg = 15 },   -- [assumed] income
			{ id = "StormEagle",        name = "Storm Eagle",        rarity = "Uncommon",  baseIncome = 18,        baseKg = 7 },    -- [assumed] income
			{ id = "ThunderRam",        name = "Thunder Ram",        rarity = "Rare",      baseIncome = 280,       baseKg = 120 },  -- [assumed] income
			{ id = "StaticLynx",        name = "Static Lynx",        rarity = "Epic",      baseIncome = 4000,      baseKg = 25,  tameSeconds = 240 }, -- [assumed] income
			{ id = "CloudBison",        name = "Cloud Bison",        rarity = "Legendary", baseIncome = 225000,    baseKg = 1500 }, -- [assumed] income
			{ id = "StormGriffinCalf",  name = "Storm Griffin calf", rarity = "Cosmic",    baseIncome = 15000000,  baseKg = 900 },
			{ id = "LightningWolf",     name = "Lightning Wolf",     rarity = "Mythic",    baseIncome = 1250000,   baseKg = 80 },   -- [assumed] income
			{ id = "SkyThunderbird",    name = "Sky Thunderbird",    rarity = "Eternal",   baseIncome = 130000000, baseKg = 700, top = true },
		},
	},
	{
		index = 8, id = "DinoBadlands", name = "Dino Badlands", saeSlot = "Prehistoric",
		sign = "17M SPEED", speedRequired = 17000000,
		startX = 2224, endX = 2608, length = 384,
		herdX = 2454, herdSide = -1, herdSpacing = 14, herdFraction = 0.6,
		cliffHeight = 44, alphaBedDiameter = 22,
		font = "LuckiestGuy",
		alpha = { id = "RodeoRex", name = "Rodeo Rex", species = "T-Rex" },
		indexWeapon = "Dino Bone Club",
		theme = {
			trail     = { material = "Ground",     color = { 156, 104, 70 } },
			shoulder  = { material = "Grass",      color = { 112, 140, 64 } },
			wall      = { material = "Sandstone",  color = { 170, 96, 66 } },
			crest     = { material = "Sandstone",  color = { 196, 128, 86 } },
			toe       = { material = "Ground",     color = { 150, 100, 70 } },
			archPost  = { material = "Marble",     color = { 236, 226, 200 } },
			archCap   = { material = "Marble",     color = { 236, 226, 200 } },
			archBoard = { material = "WoodPlanks", color = { 120, 86, 56 } },
			signText  = nil,
			herdZone  = { material = "LeafyGrass", color = { 92, 132, 56 } },
			alphaBed  = { material = "Grass",      color = { 120, 150, 70 } },
		},
		lighting = {
			AtmDensity = 0.40, AtmHaze = 1.8, AtmColor = { 200, 190, 140 }, AtmDecay = { 110, 120, 80 }, AtmGlare = 0,
			CCTint = { 245, 255, 225 }, CCSaturation = 0.15, CCContrast = 0, CCBrightness = 0,
			ClockOverride = -1, Weather = "none",
		},
		beasts = {
			{ id = "Dodo",         name = "Dodo",         rarity = "Rare",      baseIncome = 280,       baseKg = 15,    tameSeconds = 90 },  -- [assumed] income
			{ id = "Raptor",       name = "Raptor",       rarity = "Epic",      baseIncome = 4000,      baseKg = 35 },                       -- [assumed] income
			{ id = "Pterodactyl",  name = "Pterodactyl",  rarity = "Legendary", baseIncome = 225000,    baseKg = 25,    tameSeconds = 180 }, -- [assumed] income
			{ id = "Ankylosaurus", name = "Ankylosaurus", rarity = "Mythic",    baseIncome = 120000,    baseKg = 6000,  tameSeconds = 300 },
			{ id = "Triceratops",  name = "Triceratops",  rarity = "Mythic",    baseIncome = 1250000,   baseKg = 9000 },                     -- [assumed] income
			-- baseKg 35,000 is derived from SAE's Bronto: 2,536,813 kg earned ~$21M/s on a $1.5M/s base
			{ id = "Bronto",       name = "Bronto",       rarity = "Cosmic",    baseIncome = 1500000,   baseKg = 35000 },
			{ id = "TRexCalf",     name = "T-Rex calf",   rarity = "Secret",    baseIncome = 25000000,  baseKg = 7000,  tameSeconds = 10800 }, -- [assumed] income
			{ id = "Spinosaurus",  name = "Spinosaurus",  rarity = "Eternal",   baseIncome = 180000000, baseKg = 7500,  tameSeconds = 21600, top = true },
		},
	},
	{
		index = 9, id = "GhostTown", name = "Ghost Town", saeSlot = nil,
		sign = "150M SPEED", speedRequired = 150000000,
		startX = 2608, endX = 3024, length = 416,
		herdX = 2858, herdSide = 1, herdSpacing = 14, herdFraction = 0.6,
		cliffHeight = 36, alphaBedDiameter = 16,
		font = "Creepster",
		alpha = { id = "PhantomSteed", name = "Phantom Steed", species = "Horse" },
		indexWeapon = "Ghost Lasso",
		theme = {
			trail     = { material = "Ground",     color = { 110, 100, 92 } },
			shoulder  = { material = "Grass",      color = { 74, 80, 68 } },
			wall      = { material = "Rock",       color = { 60, 58, 66 } },
			crest     = { material = "Slate",      color = { 70, 66, 80 } },
			toe       = { material = "Ground",     color = { 70, 66, 62 } },
			archPost  = { material = "Wood",       color = { 70, 60, 56 } },
			archCap   = { material = "Neon",       color = { 110, 255, 170 } },
			archBoard = { material = "WoodPlanks", color = { 90, 80, 70 } },
			signText  = { 170, 255, 210 },
			herdZone  = { material = "Ground",     color = { 100, 96, 90 } },
			alphaBed  = { material = "Slate",      color = { 60, 70, 70 } },
		},
		lighting = {
			AtmDensity = 0.55, AtmHaze = 2.6, AtmColor = { 90, 140, 120 }, AtmDecay = { 40, 70, 60 }, AtmGlare = 0,
			CCTint = { 200, 255, 225 }, CCSaturation = -0.35, CCContrast = 0.15, CCBrightness = 0,
			ClockOverride = 0, Weather = "wisps",
		},
		beasts = {
			{ id = "GhostChick",      name = "Ghost Chick",      rarity = "Uncommon",  baseIncome = 18,        baseKg = 1 },    -- [assumed] income
			{ id = "SkeletonSteer",   name = "Skeleton Steer",   rarity = "Rare",      baseIncome = 280,       baseKg = 400 },  -- [assumed] income
			{ id = "SpectralWolf",    name = "Spectral Wolf",    rarity = "Epic",      baseIncome = 4000,      baseKg = 45 },   -- [assumed] income
			{ id = "WraithGoat",      name = "Wraith Goat",      rarity = "Legendary", baseIncome = 225000,    baseKg = 60 },   -- [assumed] income
			{ id = "HauntedMule",     name = "Haunted Mule",     rarity = "Mythic",    baseIncome = 1250000,   baseKg = 350 },  -- [assumed] income
			{ id = "BoneVulture",     name = "Bone Vulture",     rarity = "Cosmic",    baseIncome = 25000000,  baseKg = 12 },   -- [assumed] income
			{ id = "BansheeCat",      name = "Banshee Cat",      rarity = "Secret",    baseIncome = 120000000, baseKg = 5 },    -- [assumed] income
			{ id = "BansheeStallion", name = "Banshee Stallion", rarity = "Eternal",   baseIncome = 400000000, baseKg = 1000, top = true },
		},
	},
	{
		index = 10, id = "CosmicRift", name = "Cosmic Rift", saeSlot = "Cosmic",
		sign = "700M SPEED", speedRequired = 700000000,
		startX = 3024, endX = 3600, length = 576,
		herdX = 3456, herdSide = -1, herdSpacing = 16, herdFraction = 0.75,
		cliffHeight = 48, alphaBedDiameter = 22,
		font = "Michroma",
		alpha = { id = "CosmicKrakenCow", name = "Cosmic Kraken-Cow", species = "Kraken-Cow" },
		indexWeapon = "Cosmic Whip",
		theme = {
			trail     = { material = "Slate",         color = { 56, 46, 92 } },
			shoulder  = { material = "Slate",         color = { 46, 36, 76 } },
			wall      = { material = "Basalt",        color = { 34, 28, 54 } },
			crest     = { material = "Glass",         color = { 110, 80, 200 }, transparency = 0.1 },
			toe       = { material = "Slate",         color = { 40, 32, 64 } },
			archPost  = { material = "Glass",         color = { 120, 90, 220 } },
			archCap   = { material = "Neon",          color = { 200, 140, 255 } },
			archBoard = { material = "SmoothPlastic", color = { 24, 18, 40 } },
			signText  = { 200, 160, 255 },
			herdZone  = { material = "Slate",         color = { 80, 60, 130 } },
			alphaBed  = { material = "Neon",          color = { 140, 90, 255 }, transparency = 0.4 },
		},
		lighting = {
			AtmDensity = 0.35, AtmHaze = 1.2, AtmColor = { 150, 110, 255 }, AtmDecay = { 40, 20, 90 }, AtmGlare = 1.0,
			CCTint = { 230, 215, 255 }, CCSaturation = 0.20, CCContrast = 0.15, CCBrightness = 0,
			ClockOverride = 0, Weather = "starmotes",
		},
		beasts = {
			{ id = "StarChick",     name = "Star Chick",     rarity = "Epic",      baseIncome = 4000,       baseKg = 2 },     -- [assumed] income
			{ id = "NebulaGoat",    name = "Nebula Goat",    rarity = "Legendary", baseIncome = 225000,     baseKg = 70 },    -- [assumed] income
			{ id = "MeteorRam",     name = "Meteor Ram",     rarity = "Mythic",    baseIncome = 1000000,    baseKg = 200 },   -- [assumed] income
			{ id = "CosmicGorilla", name = "Cosmic Gorilla", rarity = "Mythic",    baseIncome = 1250000,    baseKg = 300,  tameSeconds = 420 }, -- [assumed] income
			{ id = "CometFox",      name = "Comet Fox",      rarity = "Cosmic",    baseIncome = 25000000,   baseKg = 10 },    -- [assumed] income
			{ id = "SkyWhale",      name = "Sky Whale",      rarity = "Secret",    baseIncome = 350000000,  baseKg = 40000 }, -- [assumed] income
			{ id = "GalaxyBison",   name = "Galaxy Bison",   rarity = "Eternal",   baseIncome = 900000000,  baseKg = 2000 },  -- [assumed] income
			-- baseKg 1,200 matches SAE's Unicorn base weight
			{ id = "StarUnicorn",   name = "Star Unicorn",   rarity = "Divine",    baseIncome = 1000000000, baseKg = 1200, tameSeconds = 43200, top = true },
		},
	},
}

-- Weekly areas that will be appended past Cosmic Rift (MAP_SPEC section 11). Not built yet.
AreasConfig.Upcoming = {
	{ id = "SakuraSprings",      name = "Sakura Springs",       sign = "2.5B SPEED", speedRequired = 2500000000 },
	{ id = "TitanCanyon",        name = "Titan Canyon",         sign = "7B SPEED",   speedRequired = 7000000000 },
	{ id = "HeavenHellRanch",    name = "Heaven & Hell Ranch",  sign = "20B SPEED",  speedRequired = 20000000000 },
	{ id = "EnchantedFrontier",  name = "Enchanted Frontier",   sign = "50B SPEED",  speedRequired = 50000000000 },
}

----------------------------------------------------------------------------------------------
-- Small helpers (pure Lua)
----------------------------------------------------------------------------------------------

-- Look an area up by index (1-10) or by id ("CactusCanyon").
function AreasConfig.getArea(key)
	for _, area in ipairs(AreasConfig.Areas) do
		if area.index == key or area.id == key then
			return area
		end
	end
	return nil
end

-- The area whose X range contains x, or nil (Town, trailhead, Frontier End).
function AreasConfig.areaAtX(x)
	for _, area in ipairs(AreasConfig.Areas) do
		if x >= area.startX and x < area.endX then
			return area
		end
	end
	return nil
end

function AreasConfig.getRarity(id)
	for _, rarity in ipairs(AreasConfig.Rarities) do
		if rarity.id == id then
			return rarity
		end
	end
	return nil
end

return AreasConfig
