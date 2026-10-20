--[[
	Steal a Beast: BUILD THE MAP

	GENERATED FILE: do not edit. It is made by game/tools/build_command_bar.js from
	game/src/ReplicatedStorage/Shared/AreasConfig.lua and game/src/ServerStorage/MapBuilder/init.lua.

	How to use it:
	  1. Open your place in Roblox Studio.
	  2. View tab > Command Bar.
	  3. Select ALL of this file, copy it, paste it into the Command Bar and press Enter.
	  4. Wait for "[MapBuilder] Built workspace.Map ..." in the Output window, then File > Save.

	Running it again rebuilds the map (the old workspace.Map is deleted first).
	Ctrl+Z undoes the whole build in one step.
]]

local AreasConfig = (function()
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
	----------------------------------------------------------------------------------------------
	-- Look: Steal An Egg's bright, studded checkerboard style (2026-10-20 screenshots).
	-- MapBuilder restyles the ground, paths, walls and plot floors after building:
	--   * Plastic with Studs surfaces, colours from this table (or the area theme made brighter)
	--   * plus a checkerboard Texture on the faces you see. The default is the Check-UI kit's
	--     already-uploaded 2x2 checker tile (rbxassetid://385956923, MIT, game/vendor/CheckUI),
	--     drawn black at CheckerTransparency so it only darkens every other square.
	--   * To use our own studded tile instead (game/assets/checker_studs.png, studs drawn in), upload
	--     it and set workspace attribute CheckerTexture to its id (see game/README.md).
	----------------------------------------------------------------------------------------------
	AreasConfig.Style = {
		Enabled = true,
		CheckerTexture = "rbxassetid://385956923",
		CheckerTransparency = 0.85, -- 0 for a see-through image like checker_studs.png
		TileStuds = 4,              -- one checker square = 4 x 4 studs (the image holds 2 x 2 squares)
		Saturation = 1.35,          -- area theme colours are made this much more saturated ...
		Brightness = 1.12,          -- ... and this much brighter
		Town = {
			grass = { 118, 214, 38 },   -- Square and ranch yards (Steal An Egg's bright green)
			plot = { 104, 198, 30 },    -- plot floors, a shade darker than the yards
			path = { 128, 118, 140 },   -- Main Street, boardwalks, trailhead (the purple-grey path)
			wall = { 205, 120, 55 },    -- the Town palisade (the orange checker wall)
		},
		-- Per-area colours that replace the brightened theme (area 1 copies Steal An Egg's Forest)
		AreaOverrides = {
			[1] = {
				trail = { 128, 118, 140 },
				shoulder = { 118, 214, 38 },
				wall = { 205, 120, 55 },
				crest = { 118, 214, 38 },
				toe = { 190, 108, 48 },
			},
		},
	}

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
			font = "GothamBlack",
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
				signText  = nil,
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
			font = "GothamBlack",
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
			font = "GothamBlack",
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
			font = "GothamBlack",
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
			font = "GothamBlack",
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
			font = "GothamBlack",
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
			font = "GothamBlack",
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
			font = "GothamBlack",
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
			font = "GothamBlack",
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
			font = "GothamBlack",
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
end)()

local MapBuilder = (function()
	--[[
		MapBuilder  (ServerStorage.MapBuilder)

		Builds the whole static map for Steal a Beast exactly as game/MAP_SPEC.md describes it:
		the Town (spawn, shops, Safe Zone, red line), the 7 ranch plots and the 10-area lane.
		Everything goes under workspace.Map:

		  Map (Folder)
		    Town (Folder)    Ground, Fence, Zones, TownGate, Square, TradingPost, Street
		    Plots (Folder)   Plot1 ... Plot7
		    Lane (Folder)    Trailhead, Boundaries, Waypoints, FrontierEnd, Stampede markers,
		                     Areas (Folder) -> Area01_DustyPrairie ... Area10_CosmicRift

		MapBuilder.build(config) is idempotent: it deletes workspace.Map first, so running it
		again rebuilds the map instead of making a second copy.

		How to run it in Roblox Studio:
		  * Easiest: paste game/tools/BuildMap.command.lua into View > Command Bar and press Enter.
		  * With Rojo: after "rojo serve" and connecting the Studio plugin, run this in the Command Bar:
		      require(game.ServerStorage.MapBuilder:Clone()).build(require(game.ReplicatedStorage.Shared.AreasConfig:Clone()))

		Notes:
		  * All parts are Anchored. Tags and attributes follow MAP_SPEC sections 3.2 and 3.3.
		  * Scattered props use a small seeded random generator written in plain arithmetic
		    (not Random.new), so Studio and the Lua test harness place every prop in exactly the same spot.
		  * Written in the Luau subset that is also valid Lua 5.3 (no type annotations, no +=,
		    no continue, no backtick strings, no // and no bitwise operators), so tests/run_tests.js
		    can run it under fengari against a mocked Roblox API.
	]]

	local MapBuilder = {}
	MapBuilder.Version = 1

	local rad = math.rad
	local EMPTY = {}
	local GREY = { 163, 162, 165 }
	-- Steal An Egg style: white sign text with a black outline
	local CREAM = { 255, 255, 255 }
	local DARK_STROKE = { 0, 0, 0 }
	local DEFAULT_BAND = { 26, 56 }
	-- Scatter tries per prop with the spec's spacing rule (section 6.5). If all fail, the prop gets
	-- the same number of tries again with a relaxed spacing rule, so crowded areas (Area 1 is only
	-- 160 studs long and its north side is mostly herd) still get every prop the spec counts.
	local SCATTER_TRIES = 60

	-- Colours for spec lines that name a material without a colour [assumed]
	local DEFAULT_COLOR = {
		Wood = { 120, 84, 52 },
		WoodPlanks = { 164, 112, 70 },
		Metal = { 90, 90, 96 },
		Slate = { 84, 86, 98 },
		Snow = { 240, 244, 250 },
		Neon = { 255, 255, 255 },
		SmoothPlastic = GREY,
	}

	----------------------------------------------------------------------------------------------
	-- Small helpers
	----------------------------------------------------------------------------------------------

	local function color(c)
		return Color3.fromRGB(c[1], c[2], c[3])
	end

	local function luminance(c)
		return (0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3]) / 255
	end

	-- Light text gets a dark outline and dark text gets a light one.
	local function strokeFor(c)
		if luminance(c) > 0.12 then
			return DARK_STROKE
		end
		return CREAM
	end

	local function addTag(ctx, inst, tagName)
		ctx.cs:AddTag(inst, tagName)
	end

	local function setAttributes(inst, attrs)
		for key, value in pairs(attrs) do
			inst:SetAttribute(key, value)
		end
	end

	-- Lighting profile tables hold colours as {r, g, b}; attributes need Color3.
	local function setProfileAttributes(inst, profile)
		for key, value in pairs(profile) do
			if type(value) == "table" then
				inst:SetAttribute(key, color(value))
			else
				inst:SetAttribute(key, value)
			end
		end
	end

	local function newFolder(name, parent)
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
		return f
	end

	-- Deterministic Park-Miller (MINSTD) generator. The arithmetic stays exact in both Luau
	-- (doubles) and Lua 5.3 (integers), so every build places props identically.
	local function makeRng(seed)
		local state = (seed * 7919 + 104729) % 2147483646 + 1
		local function step()
			state = (state * 48271) % 2147483647
			return state
		end
		for _ = 1, 4 do
			step()
		end
		local rng = {}
		function rng.number(lo, hi)
			return lo + (hi - lo) * ((step() - 1) / 2147483646)
		end
		function rng.integer(lo, hi)
			local v = lo + math.floor(((step() - 1) / 2147483646) * (hi - lo + 1))
			if v > hi then
				v = hi
			end
			return v
		end
		return rng
	end

	----------------------------------------------------------------------------------------------
	-- GUI helpers (signs, floating labels)
	----------------------------------------------------------------------------------------------

	-- Default rows {top, height} as fractions of the face, by number of lines.
	local DEFAULT_ROWS = {
		{ { 0.05, 0.9 } },
		{ { 0.04, 0.56 }, { 0.62, 0.34 } },
		{ { 0.03, 0.36 }, { 0.41, 0.28 }, { 0.71, 0.26 } },
	}

	local function makeLabel(name, text, fontName, textColor, strokeColor, position, size)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Position = position
		label.Size = size
		label.Font = Enum.Font[fontName]
		label.Text = text
		label.TextScaled = true
		label.TextWrapped = true
		label.TextColor3 = color(textColor)
		label.TextStrokeColor3 = color(strokeColor)
		label.TextStrokeTransparency = 0
		return label
	end

	-- g = { face = "Left", lines = {...}, font =, color =, stroke =, pps =, rows =, name = }
	local function addSign(part, g)
		local gui = Instance.new("SurfaceGui")
		gui.Name = g.name or ("Sign" .. g.face)
		gui.Face = Enum.NormalId[g.face]
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = g.pps or 20
		gui.LightInfluence = 0
		local rows = g.rows or DEFAULT_ROWS[#g.lines]
		local textColor = g.color or CREAM
		local stroke = g.stroke or strokeFor(textColor)
		for i, text in ipairs(g.lines) do
			local row = rows[i]
			local label = makeLabel("Line" .. i, text, g.font or "GothamBlack", textColor, stroke,
				UDim2.new(0.03, 0, row[1], 0), UDim2.new(0.94, 0, row[2], 0))
			label.Parent = gui
		end
		gui.Parent = part
		return gui
	end

	-- b = { lines = {...}, w =, h = (studs), up = (studs above the part), enabled =, color =, name = }
	local function addBillboard(part, b)
		local gui = Instance.new("BillboardGui")
		gui.Name = b.name or "Label"
		gui.Size = UDim2.new(b.w or 10, 0, b.h or 3, 0)
		gui.StudsOffset = Vector3.new(0, b.up or 4, 0)
		gui.MaxDistance = b.maxDistance or 150
		gui.LightInfluence = 0
		gui.AlwaysOnTop = false
		local textColor = b.color or CREAM
		local n = #b.lines
		for i, text in ipairs(b.lines) do
			local label = makeLabel("Line" .. i, text, b.font or "GothamBlack", textColor, strokeFor(textColor),
				UDim2.new(0, 0, (i - 1) / n, 0), UDim2.new(1, 0, 1 / n, 0))
			label.Parent = gui
		end
		if b.enabled == false then
			gui.Enabled = false
		end
		gui.Parent = part
		return gui
	end

	local function addLight(part, l)
		local light = Instance.new("PointLight")
		light.Range = l.range
		if l.brightness then
			light.Brightness = l.brightness
		end
		if l.color then
			light.Color = color(l.color)
		end
		light.Shadows = false
		light.Parent = part
		return light
	end

	local function addFire(part)
		local fire = Instance.new("Fire")
		fire.Size = 4
		fire.Heat = 6
		fire.Color = color({ 255, 140, 40 })
		fire.SecondaryColor = color({ 255, 60, 20 })
		fire.Parent = part
		return fire
	end

	-- kind = "smoke" (volcano vent) or "steam" (geysers)
	local function addEmitter(part, kind)
		local e = Instance.new("ParticleEmitter")
		e.Name = (kind == "steam") and "Steam" or "Smoke"
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Rate = (kind == "steam") and 8 or 5
		e.Lifetime = NumberRange.new(2, 4)
		e.Speed = NumberRange.new(4, 8)
		e.Size = NumberSequence.new(2, 9)
		e.Transparency = NumberSequence.new(0.35, 1)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-20, 20)
		e.Acceleration = Vector3.new(0, 2, 0)
		if kind == "steam" then
			e.Color = ColorSequence.new(color({ 235, 240, 245 }))
		else
			e.Color = ColorSequence.new(color({ 90, 80, 80 }))
		end
		e.Parent = part
		return e
	end

	----------------------------------------------------------------------------------------------
	-- Parts
	--
	-- A part spec is { shape, dims, pos, material, colour, opts } (MAP_SPEC section 0 shorthand):
	--   "Block" {x, y, z}   Part, Shape Block
	--   "Ball"  {d}         Part, Shape Ball, Size (d, d, d)
	--   "VCyl"  {h, d}      Cylinder Size (h, d, d) turned CFrame.Angles(0, 0, rad(90)): vertical axis
	--   "HCylX" {len, d}    Cylinder Size (len, d, d), axis along X
	--   "HCylZ" {len, d}    Cylinder Size (len, d, d) turned 90 degrees about Y: axis along Z
	--   "Wedge" {x, y, z}   WedgePart (slope low at local -Z, high at +Z)
	-- pos is the centre relative to baseCF. opts:
	--   name, class ("SpawnLocation"), cf (CFrame instead of pos), rotX/rotY/rotZ (degrees, applied
	--   after the offset), t (Transparency), refl, nc (CanCollide false), decor, noShadow,
	--   invisible, query (keep CanQuery), collide (keep CanCollide), tags, attrs, light, fire,
	--   emitter, gui (list of signs), billboard, secret (SecretSpot id)
	----------------------------------------------------------------------------------------------

	local function shapeRotation(shape)
		if shape == "VCyl" then
			return CFrame.Angles(0, 0, rad(90))
		elseif shape == "HCylZ" then
			return CFrame.Angles(0, rad(90), 0)
		end
		return nil
	end

	local function newPart(ctx, spec, baseCF, parent, defaults)
		local shape, dims, pos, material, rgb = spec[1], spec[2], spec[3], spec[4], spec[5]
		local o = spec[6] or EMPTY
		defaults = defaults or EMPTY

		local className = o.class
		if not className then
			className = (shape == "Wedge") and "WedgePart" or "Part"
		end
		local part = Instance.new(className)

		-- Shape first, then Size (a Ball or Cylinder constrains its Size).
		local size
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
			size = Vector3.new(dims[1], dims[1], dims[1])
		elseif shape == "VCyl" or shape == "HCylX" or shape == "HCylZ" then
			part.Shape = Enum.PartType.Cylinder
			size = Vector3.new(dims[1], dims[2], dims[2])
		elseif shape == "Wedge" then
			size = Vector3.new(dims[1], dims[2], dims[3])
		else
			part.Shape = Enum.PartType.Block
			size = Vector3.new(dims[1], dims[2], dims[3])
		end
		part.Size = size

		local cf
		if o.cf then
			cf = baseCF * o.cf
		else
			cf = baseCF * CFrame.new(pos[1], pos[2], pos[3])
		end
		if o.rotX or o.rotY or o.rotZ then
			cf = cf * CFrame.Angles(rad(o.rotX or 0), rad(o.rotY or 0), rad(o.rotZ or 0))
		end
		local shapeRot = shapeRotation(shape)
		if shapeRot then
			cf = cf * shapeRot
		end
		part.CFrame = cf

		part.Anchored = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		material = material or "SmoothPlastic"
		part.Material = Enum.Material[material]
		part.Color = color(rgb or DEFAULT_COLOR[material] or GREY)

		local t = o.t or defaults.t
		if t then
			part.Transparency = t
		end
		if o.refl then
			part.Reflectance = o.refl
		end
		if o.nc or defaults.nc then
			part.CanCollide = false
		end

		-- Decor: no touch, no queries, and no shadow when the part is under 3 studs (section 0).
		local decor = o.decor
		if decor == nil then
			decor = defaults.decor
		end
		if decor then
			part.CanTouch = false
			part.CanQuery = false
			if math.max(size.X, size.Y, size.Z) < 3 then
				part.CastShadow = false
			end
		end
		if o.noShadow or defaults.noShadow then
			part.CastShadow = false
		end
		-- Invisible: Transparency 1, CanCollide/CanTouch/CanQuery false (zones re-enable CanQuery).
		if o.invisible then
			part.Transparency = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = false
		end
		if o.query then
			part.CanQuery = true
		end
		if o.collide then
			part.CanCollide = true
		end

		part.Name = o.name or defaults.name or "Part"

		if o.light then
			addLight(part, o.light)
		end
		if o.fire then
			addFire(part)
		end
		if o.emitter then
			addEmitter(part, o.emitter)
		end
		if o.gui then
			for _, g in ipairs(o.gui) do
				addSign(part, g)
			end
		end
		if o.billboard then
			addBillboard(part, o.billboard)
		end
		if o.secret then
			addTag(ctx, part, "SecretSpot")
			part:SetAttribute("SecretId", o.secret)
		end
		if o.tags then
			for _, tagName in ipairs(o.tags) do
				addTag(ctx, part, tagName)
			end
		end
		if o.attrs then
			setAttributes(part, o.attrs)
		end

		part.Parent = parent
		ctx.parts = ctx.parts + 1
		return part
	end

	-- Builds a list of specs into parent. Returns (partsByName, list).
	local function buildParts(ctx, parent, baseCF, specs, defaults)
		local byName, list = {}, {}
		for _, spec in ipairs(specs) do
			local p = newPart(ctx, spec, baseCF, parent, defaults)
			if byName[p.Name] == nil then
				byName[p.Name] = p
			end
			table.insert(list, p)
		end
		return byName, list
	end

	-- A Model made of specs. mopts = { primary =, tags =, attrs =, streaming =, defaults = }
	local function buildModel(ctx, name, parent, baseCF, specs, mopts)
		mopts = mopts or EMPTY
		local m = Instance.new("Model")
		m.Name = name
		local byName, list = buildParts(ctx, m, baseCF, specs, mopts.defaults)
		m.PrimaryPart = (mopts.primary and byName[mopts.primary]) or list[1]
		if mopts.tags then
			for _, tagName in ipairs(mopts.tags) do
				addTag(ctx, m, tagName)
			end
		end
		if mopts.attrs then
			setAttributes(m, mopts.attrs)
		end
		if mopts.streaming then
			m.ModelStreamingMode = Enum.ModelStreamingMode[mopts.streaming]
		end
		m.Parent = parent
		ctx.models = ctx.models + 1
		return m, byName
	end

	-- Street lamp: pole + glowing ball with a PointLight (Range 18, no shadows).
	local function buildLamp(ctx, parent, name, x, z)
		return buildModel(ctx, name, parent, CFrame.new(), {
			{ "VCyl", { 12, 1 }, { x, 6, z }, "Metal", { 60, 56, 52 }, { name = "Pole", decor = true } },
			{ "Ball", { 2 }, { x, 12.8, z }, "Neon", { 255, 210, 140 }, { name = "Lamp", decor = true, light = { range = 18 } } },
		})
	end

	----------------------------------------------------------------------------------------------
	-- Collision groups (MAP_SPEC section 3.4)
	----------------------------------------------------------------------------------------------

	local function collisionGroupNames(plotCount)
		local names = { "Players", "Beasts", "Alphas", "AlphaBlocker" }
		for i = 1, plotCount do
			table.insert(names, "GateLock" .. i)
		end
		for i = 1, plotCount do
			table.insert(names, "Owner" .. i)
		end
		return names
	end

	local function groupKind(name)
		local kind, num = string.match(name, "^(%a+)(%d*)$")
		return kind, tonumber(num)
	end

	-- Should groups a and b collide? Encodes the table in section 3.4.
	function MapBuilder.groupsCollide(a, b)
		local ka, ia = groupKind(a)
		local kb, ib = groupKind(b)
		if ka == "Beasts" or kb == "Beasts" then
			local other = (ka == "Beasts") and kb or ka
			return other == "Default"
		end
		if ka == "Alphas" or kb == "Alphas" then
			local other = (ka == "Alphas") and kb or ka
			return other == "Default" or other == "AlphaBlocker"
		end
		if ka == "AlphaBlocker" or kb == "AlphaBlocker" then
			return false
		end
		if ka == "GateLock" or kb == "GateLock" then
			local lockIndex, otherKind, otherIndex = ia, kb, ib
			if kb == "GateLock" then
				lockIndex, otherKind, otherIndex = ib, ka, ia
			end
			if otherKind == "Players" then
				return true
			end
			if otherKind == "Owner" then
				return otherIndex ~= lockIndex
			end
			return false
		end
		return true
	end

	local function registerCollisionGroups(plotCount)
		local ok, err = pcall(function()
			local PhysicsService = game:GetService("PhysicsService")
			local names = collisionGroupNames(plotCount)
			for _, name in ipairs(names) do
				if not PhysicsService:IsCollisionGroupRegistered(name) then
					PhysicsService:RegisterCollisionGroup(name)
				end
			end
			local all = { "Default" }
			for _, name in ipairs(names) do
				table.insert(all, name)
			end
			for i = 1, #all do
				for j = i, #all do
					if not (i == 1 and j == 1) then
						PhysicsService:CollisionGroupSetCollidable(all[i], all[j], MapBuilder.groupsCollide(all[i], all[j]))
					end
				end
			end
		end)
		if not ok then
			warn("[MapBuilder] Could not register collision groups (" .. tostring(err) .. "). "
				.. "AlphaBlocker is made non-solid so it cannot block players; register the groups at server start.")
		end
		return ok
	end

	----------------------------------------------------------------------------------------------
	-- Town (MAP_SPEC section 4)
	----------------------------------------------------------------------------------------------

	local function zoneSpec(name, tagName, size, pos)
		local attrs = nil
		if tagName == "SafeZone" then
			attrs = { ZoneName = name }
		end
		return { "Block", size, pos, nil, nil, { name = name, invisible = true, query = true, tags = { tagName }, attrs = attrs } }
	end

	local function buildTown(ctx, cfg, map)
		local I = CFrame.new()
		local town = newFolder("Town", map)
		setProfileAttributes(town, cfg.Town.Lighting)

		-- 4.2 Ground (6 parts, top at Y 0)
		local ground = newFolder("Ground", town)
		buildParts(ctx, ground, I, {
			{ "Block", { 160, 4, 256 }, { -16, -2, 0 }, "Ground", { 196, 164, 116 }, { name = "SquareGround" } },
			{ "Block", { 336, 4, 48 }, { 232, -2, 0 }, "Ground", { 176, 138, 96 }, { name = "MainStreet" } },
			{ "Block", { 336, 4, 16 }, { 232, -2, 32 }, "WoodPlanks", { 150, 104, 62 }, { name = "BoardwalkN" } },
			{ "Block", { 336, 4, 16 }, { 232, -2, -32 }, "WoodPlanks", { 150, 104, 62 }, { name = "BoardwalkS" } },
			{ "Block", { 336, 4, 88 }, { 232, -2, 84 }, "Grass", { 140, 160, 84 }, { name = "RanchGroundN" } },
			{ "Block", { 336, 4, 88 }, { 232, -2, -84 }, "Grass", { 140, 160, 84 }, { name = "RanchGroundS" } },
		})

		-- 4.3 Fence: log palisade, 45 posts, 5 invisible boundary walls (55 parts)
		local fence = newFolder("Fence", town)
		local palisade = { 120, 82, 48 }
		buildParts(ctx, fence, I, {
			{ "Block", { 496, 12, 2 }, { 152, 6, 129 }, "Wood", palisade, { name = "Palisade_N" } },
			{ "Block", { 496, 12, 2 }, { 152, 6, -129 }, "Wood", palisade, { name = "Palisade_S" } },
			{ "Block", { 2, 12, 256 }, { -97, 6, 0 }, "Wood", palisade, { name = "Palisade_W" } },
			{ "Block", { 2, 12, 64 }, { 401, 6, 96 }, "Wood", palisade, { name = "Palisade_EN" } },
			{ "Block", { 2, 12, 64 }, { 401, 6, -96 }, "Wood", palisade, { name = "Palisade_ES" } },
		})
		local postCount = 0
		local function post(x, z)
			postCount = postCount + 1
			newPart(ctx, { "VCyl", { 14, 3 }, { x, 7, z }, "Wood", { 96, 64, 36 }, { name = string.format("Post_%03d", postCount) } }, I, fence)
		end
		for _, z in ipairs({ 129, -129 }) do
			for x = -96, 384, 32 do
				post(x, z)
			end
			post(400, z)
		end
		for z = -96, 96, 32 do
			post(-97, z)
		end
		for _, z in ipairs({ 64, 96, -64, -96 }) do
			post(401, z)
		end
		buildParts(ctx, fence, I, {
			{ "Block", { 500, 80, 2 }, { 152, 40, 131 }, nil, nil, { name = "Boundary_N", invisible = true, collide = true } },
			{ "Block", { 500, 80, 2 }, { 152, 40, -131 }, nil, nil, { name = "Boundary_S", invisible = true, collide = true } },
			{ "Block", { 2, 80, 264 }, { -99, 40, 0 }, nil, nil, { name = "Boundary_W", invisible = true, collide = true } },
			{ "Block", { 2, 80, 66 }, { 403, 40, 97 }, nil, nil, { name = "Boundary_EN", invisible = true, collide = true } },
			{ "Block", { 2, 80, 66 }, { 403, 40, -97 }, nil, nil, { name = "Boundary_ES", invisible = true, collide = true } },
		})

		-- 4.1 Zones (invisible volumes, CanQuery true)
		local zones = newFolder("Zones", town)
		buildParts(ctx, zones, I, {
			zoneSpec("SZ_Square", "SafeZone", { 160, 60, 256 }, { -16, 30, 0 }),
			zoneSpec("SZ_Street", "SafeZone", { 336, 60, 80 }, { 232, 30, 0 }),
			zoneSpec("SZ_Gate", "SafeZone", { 40, 60, 128 }, { 380, 30, 0 }),
			zoneSpec("SZ_TradingPost", "SafeZone", { 64, 60, 80 }, { 328, 30, -80 }),
			zoneSpec("TownBounds", "TownBounds", { 496, 80, 256 }, { 152, 40, 0 }),
		})

		-- 4.4 Town Gate: the red line (8 parts)
		local gateX = cfg.Town.GateX
		local laneWidth = cfg.Town.LaneHalfWidth * 2
		local _, gateParts = buildModel(ctx, "TownGate", town, I, {
			{ "Block", { 1, 0.2, laneWidth }, { gateX, 0, 0 }, "Neon", { 255, 40, 40 }, { name = "RedLine", nc = true, tags = { "TownGate" } } },
			{ "Block", { 2, 60, laneWidth }, { gateX, 30, 0 }, nil, nil, { name = "AlphaBlocker", invisible = true, collide = true } },
			{ "Block", { 2, 40, laneWidth }, { gateX - 1, 20, 0 }, "ForceField", { 255, 150, 80 }, { name = "SundownCurtain", t = 1, nc = true, decor = true } },
			{ "VCyl", { 30, 5 }, { gateX + 4, 15, 34 }, "Wood", { 110, 74, 42 }, { name = "GatePostN" } },
			{ "VCyl", { 30, 5 }, { gateX + 4, 15, -34 }, "Wood", { 110, 74, 42 }, { name = "GatePostS" } },
			{ "Block", { 3, 8, 76 }, { gateX + 4, 33, 0 }, "WoodPlanks", { 176, 128, 78 }, { name = "GateBoard", gui = {
				{ face = "Left", lines = { "THE FRONTIER \u{2192}", "weapons ON past the red line" } },
				{ face = "Right", lines = { "TOWN \u{00B7} SAFE ZONE" } },
			} } },
			-- The spec puts the lanterns at y 31, inside the GateBoard (y 29..37); they sit on top of it here.
			{ "Ball", { 2 }, { gateX + 4, 38, 34 }, "Neon", { 255, 200, 120 }, { name = "LanternN", light = { range = 16 } } },
			{ "Ball", { 2 }, { gateX + 4, 38, -34 }, "Neon", { 255, 200, 120 }, { name = "LanternS", light = { range = 16 } } },
		}, { primary = "RedLine", streaming = "Persistent" })
		if ctx.groupsOk then
			gateParts.AlphaBlocker.CollisionGroup = "AlphaBlocker"
		else
			gateParts.AlphaBlocker.CanCollide = false
		end

		-- 4.5 Town Square fixtures (47 parts)
		local square = newFolder("Square", town)
		local spawn = newPart(ctx, { "Block", { 20, 1, 20 }, { 0, 0.5, 0 }, "Slate", { 150, 120, 90 },
			{ name = "SpawnLocation", class = "SpawnLocation", rotY = -90 } }, I, square)
		spawn.Neutral = true
		spawn.Duration = 0

		buildModel(ctx, "GeneralStore", square, I, {
			{ "Block", { 44, 22, 2 }, { 0, 11, 112 }, "WoodPlanks", { 164, 112, 70 }, { name = "Facade" } },
			{ "Block", { 44, 18, 14 }, { 0, 9, 120 }, "Wood", { 140, 96, 58 }, { name = "Body" } },
			{ "Block", { 40, 1, 8 }, { 0, 12.5, 107 }, "Fabric", { 190, 60, 50 }, { name = "Awning" } },
			{ "VCyl", { 12, 1 }, { -19, 6, 103.5 }, "Wood", nil, { name = "AwningPost" } },
			{ "VCyl", { 12, 1 }, { 19, 6, 103.5 }, "Wood", nil, { name = "AwningPost" } },
			{ "Block", { 24, 4, 4 }, { 0, 2, 105 }, "WoodPlanks", nil, { name = "Counter" } },
			{ "Block", { 30, 5, 0.6 }, { 0, 18, 110.7 }, "WoodPlanks", { 70, 46, 30 }, { name = "Sign", gui = {
				{ face = "Front", lines = { "GENERAL STORE" }, color = { 255, 214, 120 } },
			} } },
			{ "VCyl", { 0.2, 18 }, { 0, 0.1, 90 }, "Neon", { 255, 200, 40 }, { name = "ShopPad", t = 0.25, nc = true,
				tags = { "ShopPad" }, attrs = { ShopId = "General" }, billboard = { lines = { "SHOP" }, w = 10, h = 3, up = 4 } } },
		}, { primary = "Facade", streaming = "Persistent" })

		newPart(ctx, { "Block", { 12, 16, 2 }, { 36, 8, 104 }, nil, nil, { name = "EventPortalSpot", invisible = true, tags = { "EventPortalSpot" } } }, I, square)

		buildModel(ctx, "IndexBoard", square, I, {
			{ "Block", { 2, 22, 44 }, { -88, 14, 0 }, "WoodPlanks", { 176, 128, 78 }, { name = "Board", gui = {
				{ face = "Right", lines = { "BEAST INDEX" }, rows = { { 0.03, 0.22 } } },
			} } },
			{ "VCyl", { 26, 2.5 }, { -88, 13, 23 }, "Wood", nil, { name = "Post" } },
			{ "VCyl", { 26, 2.5 }, { -88, 13, -23 }, "Wood", nil, { name = "Post" } },
			{ "Block", { 4, 1.5, 48 }, { -88, 25.75, 0 }, "Wood", nil, { name = "RoofCap" } },
			{ "VCyl", { 0.2, 16 }, { -70, 0.1, 0 }, "Neon", { 60, 220, 230 }, { name = "IndexPad", t = 0.25, nc = true,
				tags = { "IndexPad" }, billboard = { lines = { "INDEX" }, w = 10, h = 3, up = 4 } } },
		}, { primary = "Board", streaming = "Persistent" })

		buildModel(ctx, "RewardsChest", square, I, {
			{ "Block", { 14, 1, 12 }, { 0, 0.5, -104 }, "Marble", { 220, 214, 200 }, { name = "Pedestal" } },
			{ "Block", { 8, 5, 6 }, { 0, 3.5, -104 }, "Wood", { 170, 36, 36 }, { name = "Base" } },
			{ "HCylX", { 8, 6 }, { 0, 6, -104 }, "Wood", { 170, 36, 36 }, { name = "Lid" } },
			{ "Block", { 0.8, 5.4, 6.2 }, { -2.5, 3.6, -104 }, "Foil", { 255, 200, 60 }, { name = "Band" } },
			{ "Block", { 0.8, 5.4, 6.2 }, { 2.5, 3.6, -104 }, "Foil", { 255, 200, 60 }, { name = "Band" } },
			{ "Block", { 1.6, 2, 0.4 }, { 0, 5.2, -100.9 }, "Neon", { 255, 210, 80 }, { name = "Lock" } },
			{ "VCyl", { 0.2, 14 }, { 0, 0.1, -90 }, "Neon", { 255, 80, 80 }, { name = "RewardsPad", t = 0.25, nc = true,
				tags = { "RewardsPad" }, billboard = { lines = { "FREE REWARDS" }, w = 14, h = 3, up = 4 } } },
		}, { primary = "Base", streaming = "Persistent" })

		buildModel(ctx, "SundownClock", square, I, {
			{ "Block", { 12, 30, 12 }, { -56, 15, 80 }, "Brick", { 150, 84, 64 }, { name = "Tower" } },
			{ "Wedge", { 12, 6, 6 }, { -56, 33, 83 }, "WoodPlanks", { 96, 64, 52 }, { name = "Roof", rotY = 180 } },
			{ "Wedge", { 12, 6, 6 }, { -56, 33, 77 }, "WoodPlanks", { 96, 64, 52 }, { name = "Roof" } },
			{ "Block", { 0.4, 9, 9 }, { -49.8, 22, 80 }, "SmoothPlastic", { 245, 240, 225 }, { name = "Face", gui = {
				{ face = "Right", lines = { "SUNDOWN IN", "4:50" }, pps = 30 },
			} } },
		}, { primary = "Tower", tags = { "SundownClock" }, streaming = "Persistent" })

		buildModel(ctx, "Leaderboards", square, I, {
			{ "Block", { 4, 2, 42 }, { -56, 1, -80 }, "Wood", nil, { name = "Base" } },
			{ "Block", { 1, 16, 18 }, { -56, 10, -70 }, "WoodPlanks", { 176, 128, 78 }, { name = "CashBoard", gui = {
				{ face = "Right", lines = { "TOP CASH" }, rows = { { 0.03, 0.16 } } },
			} } },
			{ "Block", { 1, 16, 18 }, { -56, 10, -90 }, "WoodPlanks", { 176, 128, 78 }, { name = "SpeedBoard", gui = {
				{ face = "Right", lines = { "TOP SPEED" }, rows = { { 0.03, 0.16 } } },
			} } },
		}, { primary = "Base", tags = { "Leaderboard" }, streaming = "Persistent" })

		local decor = newFolder("Decor", square)
		local lampSpots = { { 40, 40 }, { 40, -40 }, { -40, 40 }, { -40, -40 }, { -80, 60 }, { -80, -60 } }
		for i, spot in ipairs(lampSpots) do
			buildLamp(ctx, decor, string.format("Lamp_%02d", i), spot[1], spot[2])
		end
		for _, side in ipairs({ 1, -1 }) do
			buildParts(ctx, decor, I, {
				{ "Block", { 8, 2.4, 3 }, { 24, 1.2, 60 * side }, "WoodPlanks", nil, { name = "Trough", decor = true } },
				{ "Block", { 7.4, 0.2, 2.4 }, { 24, 2.35, 60 * side }, "SmoothPlastic", { 80, 150, 200 }, { name = "Water", nc = true, decor = true } },
				{ "VCyl", { 3, 2.4 }, { 30, 1.5, 64 * side }, "Wood", { 130, 90, 56 }, { name = "Barrel", decor = true } },
			})
		end

		-- 4.6 Trading Post (15 parts)
		local trading = newFolder("TradingPost", town)
		buildModel(ctx, "SellStand", trading, I, {
			{ "Block", { 20, 4, 4 }, { 312, 2, -58 }, "WoodPlanks", { 164, 112, 70 }, { name = "Counter" } },
			{ "Block", { 22, 14, 2 }, { 312, 7, -70 }, "Wood", { 140, 96, 58 }, { name = "BackWall" } },
			{ "Wedge", { 24, 3, 12 }, { 312, 15.5, -64 }, "Fabric", { 60, 140, 70 }, { name = "Awning", rotY = 180 } },
			{ "Block", { 18, 4, 0.5 }, { 312, 19, -68.7 }, "WoodPlanks", nil, { name = "Sign", gui = {
				{ face = "Back", lines = { "SELL" } },
			} } },
			{ "Ball", { 3 }, { 306, 4.8, -58 }, "Foil", { 255, 200, 60 }, { name = "Coin", decor = true } },
			{ "Ball", { 2.4 }, { 318, 4.6, -58 }, "Foil", { 255, 200, 60 }, { name = "Coin", decor = true } },
			{ "VCyl", { 0.2, 14 }, { 312, 0.1, -50 }, "Neon", { 70, 220, 100 }, { name = "SellPad", t = 0.25, nc = true, tags = { "SellPad" } } },
		}, { primary = "Counter", streaming = "Persistent" })
		buildModel(ctx, "BreedingBarn", trading, I, {
			{ "Block", { 24, 14, 22 }, { 344, 7, -94 }, "Wood", { 168, 44, 38 }, { name = "Body", gui = {
				{ face = "Back", lines = { "BREEDING BARN" }, rows = { { 0.02, 0.17 } } },
			} } },
			{ "Wedge", { 22, 6, 12 }, { 338, 17, -94 }, "WoodPlanks", { 96, 64, 52 }, { name = "RoofW", rotY = 90 } },
			{ "Wedge", { 22, 6, 12 }, { 350, 17, -94 }, "WoodPlanks", { 96, 64, 52 }, { name = "RoofE", rotY = -90 } },
			{ "Block", { 10, 10, 0.4 }, { 344, 6, -82.8 }, "Wood", { 236, 228, 214 }, { name = "Door" } },
			{ "Block", { 4, 3, 0.4 }, { 344, 16.5, -82.8 }, "SmoothPlastic", { 40, 30, 26 }, { name = "Loft" } },
			{ "HCylX", { 5, 4 }, { 334, 2, -76 }, "Grass", { 220, 190, 100 }, { name = "Hay", decor = true } },
			{ "HCylX", { 5, 4 }, { 334, 2, -70 }, "Grass", { 220, 190, 100 }, { name = "Hay", decor = true } },
			{ "VCyl", { 0.2, 14 }, { 344, 0.1, -72 }, "Neon", { 255, 110, 200 }, { name = "BreedingPad", t = 0.25, nc = true, tags = { "BreedingPad" } } },
		}, { primary = "Body", streaming = "Persistent" })

		-- 4.7 Street furniture (32 parts)
		local street = newFolder("Street", town)
		local lamps = newFolder("Lamps", street)
		local lampIndex = 0
		for _, x in ipairs({ 72, 148, 220, 292, 368 }) do
			for _, z in ipairs({ 25, -25 }) do
				lampIndex = lampIndex + 1
				buildLamp(ctx, lamps, string.format("Lamp_%02d", lampIndex), x, z)
			end
		end
		local barrels = newFolder("AlleyBarrels", street)
		for _, x in ipairs({ 148, 220, 292 }) do
			for _, z in ipairs({ 60, 100, -60, -100 }) do
				newPart(ctx, { "VCyl", { 3, 2.4 }, { x, 1.5, z }, "Wood", { 130, 90, 56 }, { name = "Barrel", decor = true } }, I, barrels)
			end
		end

		return town
	end

	----------------------------------------------------------------------------------------------
	-- Ranch plots (MAP_SPEC section 5). Built in plot-local space (front = local -Z) and placed
	-- with the pivot CFrame from AreasConfig.Plots.List.
	----------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------
	-- Plot fence (section 13): Steal An Egg's wooden rail fence with an X brace in every bay
	----------------------------------------------------------------------------------------------
	local FENCE = {
		bay = 8,                       -- studs between posts
		bottomY = 2.0, topY = 5.6,     -- rail centre heights (the plot floor is at y 1)
		rail = { 0.5, 0.4 },           -- rail height, depth
		brace = { 0.45, 0.3 },         -- brace thickness, depth
		post = { 1.2, 6, 1.2 },        -- post size (stands on the floor)
		railColor = { 198, 96, 40 },   -- orange-brown rails and braces
		postColor = { 88, 56, 40 },    -- dark posts
	}

	-- Runs in plot-local coordinates: { name, from {x, z}, to {x, z}, skipEndPosts }. The front has
	-- the gate gap. The side runs skip their end posts, because the front and back runs already put
	-- a post in each corner.
	local PLOT_FENCE_RUNS = {
		{ "FrontW", { -32, -39.5 }, { -8, -39.5 } },
		{ "FrontE", { 8, -39.5 }, { 32, -39.5 } },
		{ "Left", { -31.5, -40 }, { -31.5, 40 }, true },
		{ "Right", { 31.5, -40 }, { 31.5, 40 }, true },
		{ "Back", { -32, 39.5 }, { 32, 39.5 } },
	}

	-- atan2 that behaves the same in Luau (math.atan takes one argument) and Lua 5.3
	local function atan2(y, x)
		if x > 0 then
			return math.atan(y / x)
		elseif x < 0 then
			return math.atan(y / x) + ((y >= 0) and math.pi or -math.pi)
		end
		return (y > 0 and math.pi / 2) or (y < 0 and -math.pi / 2) or 0
	end

	-- Appends the parts of one straight fence run to `list` (part specs with an explicit cf).
	local function appendFenceRun(list, run)
		local name, a, b = run[1], run[2], run[3]
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local length = math.sqrt(dx * dx + dz * dz)
		local yaw = atan2(-dz, dx) -- turns local +X onto the run direction
		local bays = math.max(1, math.floor(length / FENCE.bay + 0.5))
		local bayLength = length / bays
		local function at(t, y)
			return CFrame.new(a[1] + dx * t, y, a[2] + dz * t) * CFrame.Angles(0, yaw, 0)
		end
		-- rails span the whole run
		for _, y in ipairs({ FENCE.bottomY, FENCE.topY }) do
			table.insert(list, { "Block", { length, FENCE.rail[1], FENCE.rail[2] }, nil, "Wood", FENCE.railColor,
				{ name = "Rail" .. name, cf = at(0.5, y), decor = true } })
		end
		-- posts at every bay boundary, braces in every bay
		local h = FENCE.topY - FENCE.bottomY
		local diagonal = math.sqrt(bayLength * bayLength + h * h)
		local angle = atan2(h, bayLength)
		for i = 0, bays do
			if not (run[4] and (i == 0 or i == bays)) then
				table.insert(list, { "Block", FENCE.post, nil, "Wood", FENCE.postColor,
					{ name = "Post" .. name, cf = at(i / bays, 1 + FENCE.post[2] / 2) } })
			end
			if i < bays then
				local mid = at((i + 0.5) / bays, (FENCE.bottomY + FENCE.topY) / 2)
				for _, sign in ipairs({ 1, -1 }) do
					table.insert(list, { "Block", { diagonal, FENCE.brace[1], FENCE.brace[2] }, nil, "Wood", FENCE.railColor,
						{ name = "Brace" .. name, cf = mid * CFrame.Angles(0, 0, sign * angle), decor = true } })
				end
			end
		end
	end

	local function buildPlot(ctx, cfg, plotsFolder, p)
		local pivot = CFrame.new(p.x, 0, p.z)
		if p.rotated then
			pivot = pivot * CFrame.Angles(0, math.pi, 0)
		end
		local plotCfg = cfg.Plots
		local plot = Instance.new("Model")
		plot.Name = "Plot" .. p.index

		-- Platform, volumes and spawn
		local own = buildParts(ctx, plot, pivot, {
			{ "Block", { 64, 1, 80 }, { 0, 0.5, 0 }, "Grass", { 124, 160, 76 }, { name = "PlotBase" } },
			{ "Block", { 64, 40, 80 }, { 0, 20, 0 }, nil, nil, { name = "PlotBounds", invisible = true, query = true, tags = { "PlotBounds" } } },
			{ "Block", { 60, 12, 52 }, { 0, 7, 0 }, nil, nil, { name = "PenArea", invisible = true, query = true, tags = { "PenArea" } } },
			{ "Block", { 12, 0.2, 14 }, { 0, 1.0, -33 }, "Ground", { 170, 132, 90 }, { name = "EntryPath", nc = true } },
			-- y 1.05 instead of 1.0 so the amber strip does not z-fight with EntryPath where they overlap
			{ "Block", { 16, 0.2, 1 }, { 0, 1.05, -39.5 }, "Neon", { 255, 170, 40 }, { name = "Threshold", nc = true } },
			{ "Wedge", { 16, 1, 4 }, { 0, 0.5, -42 }, "WoodPlanks", { 150, 104, 62 }, { name = "GateRamp" } },
			{ "Block", { 6, 1, 6 }, { -18, 0.5, -48 }, nil, nil, { name = "PlotSpawn", invisible = true, tags = { "PlotSpawn" } } },
		})
		own.PlotBase.PivotOffset = CFrame.new(0, -0.5, 0) -- model pivot sits on the ground, like the spec's pivot

		-- Fence: Steal An Egg's wooden rail fence (posts, two rails, an X brace in every bay; section 13),
		-- plus the invisible colliders (height 14) that stop players jumping in
		local fence = newFolder("Fence", plot)
		local fenceParts = {}
		for _, run in ipairs(PLOT_FENCE_RUNS) do
			appendFenceRun(fenceParts, run)
		end
		for _, c in ipairs({
			{ { 24, 14, 1 }, { -20, 8, -39.5 }, "ColliderFrontW" },
			{ { 24, 14, 1 }, { 20, 8, -39.5 }, "ColliderFrontE" },
			{ { 1, 14, 80 }, { -31.5, 8, 0 }, "ColliderLeft" },
			{ { 1, 14, 80 }, { 31.5, 8, 0 }, "ColliderRight" },
			{ { 64, 14, 1 }, { 0, 8, 39.5 }, "ColliderBack" },
		}) do
			table.insert(fenceParts, { "Block", c[1], c[2], nil, nil, { name = c[3], invisible = true, collide = true } })
		end
		buildParts(ctx, fence, pivot, fenceParts)

		-- Gate (8 parts). GateLock is off by default: T1, no collision (section 5.5).
		local _, gate = buildModel(ctx, "Gate", plot, pivot, {
			{ "VCyl", { 16, 2 }, { -9, 9, -39.5 }, "Wood", { 110, 76, 46 }, { name = "GatePostL" } },
			{ "VCyl", { 16, 2 }, { 9, 9, -39.5 }, "Wood", { 110, 76, 46 }, { name = "GatePostR" } },
			{ "Ball", { 1.6 }, { -9, 17.8, -39.5 }, "Neon", { 255, 200, 120 }, { name = "LanternL", light = { range = 12 } } },
			{ "Ball", { 1.6 }, { 9, 17.8, -39.5 }, "Neon", { 255, 200, 120 }, { name = "LanternR", light = { range = 12 } } },
			{ "Block", { 20, 4, 1 }, { 0, 14, -39.5 }, "WoodPlanks", { 190, 140, 80 }, { name = "OwnerSign", tags = { "OwnerSign" }, gui = {
				{ face = "Front", lines = { "FREE RANCH" } },
			} } },
			{ "Block", { 0.6, 4, 8 }, { -8.5, 3, -35 }, "Wood", { 120, 84, 52 }, { name = "GateDoorL", nc = true } }, -- swung open into the pen (section 13)
			{ "Block", { 0.6, 4, 8 }, { 8.5, 3, -35 }, "Wood", { 120, 84, 52 }, { name = "GateDoorR", nc = true } },
			{ "Block", { 16, 14, 1 }, { 0, 8, -39.5 }, "ForceField", { 255, 60, 60 }, { name = "GateLock", t = 1, nc = true,
				tags = { "GateLock" }, attrs = { PlotIndex = p.index, Locked = false } } },
		}, { primary = "OwnerSign" })
		-- Headshot slot for RanchService (hidden until someone owns the ranch)
		local headshot = Instance.new("ImageLabel")
		headshot.Name = "Headshot"
		headshot.BackgroundTransparency = 1
		headshot.Size = UDim2.new(0.18, 0, 0.9, 0)
		headshot.Position = UDim2.new(0.01, 0, 0.05, 0)
		headshot.Image = ""
		headshot.Visible = false
		headshot.Parent = gate.OwnerSign:FindFirstChild("SignFront")
		if ctx.groupsOk then
			gate.GateLock.CollisionGroup = "GateLock" .. p.index
		end

		-- Pen: slots 1-10 built; 1-7 active at PenLevel 1 (section 5.4)
		local pen = newFolder("Pen", plot)
		for s = 1, plotCfg.PenBuiltSlots do
			local xz = plotCfg.SlotLayout[s]
			local active = s <= plotCfg.PenStartSlots
			local pad = newPart(ctx, { "Block", { 10, 0.4, 10 }, { xz[1], 1.1, xz[2] },
				active and "Sand" or "SmoothPlastic", active and { 222, 196, 120 } or { 120, 120, 120 },
				{ name = string.format("Slot%02d", s), nc = true, t = (not active) and 0.5 or nil, tags = { "PenSlot" },
					attrs = { PlotIndex = p.index, SlotIndex = s, Active = active, Occupied = false },
					billboard = (not active) and { lines = { "LOCKED" }, w = 6, h = 1.6, up = 2, maxDistance = 80 } or nil } }, pivot, pen)
			local pivotAttachment = Instance.new("Attachment")
			pivotAttachment.Name = "BeastPivot"
			pivotAttachment.Position = Vector3.new(0, 0.2, 0) -- top centre of the pad (world y 1.3)
			pivotAttachment.Parent = pad
		end

		-- Upgrade Pen sign (section 13): Steal An Egg's dark sign by the pen. RanchService writes the
		-- level and price on it and adds the "Upgrade" prompt.
		buildModel(ctx, "UpgradeSign", plot, pivot, {
			{ "Block", { 0.6, 4.4, 0.6 }, { -17, 2.2, -41.5 }, "SmoothPlastic", { 30, 30, 36 }, { name = "Post" } },
			{ "Block", { 6, 3.6, 0.4 }, { -17, 5.8, -41.5 }, "SmoothPlastic", { 22, 30, 54 }, { name = "Board", gui = {
				{ face = "Front", lines = { "Upgrade Pen", "Level 1 > Level 2", "$0" }, pps = 50 },
			} } },
		}, { primary = "Board", tags = { "UpgradeSign" }, attrs = { PlotIndex = p.index } })

		-- Barn (ridge runs front to back)
		buildModel(ctx, "Barn", plot, pivot, {
			{ "Block", { 32, 12, 12 }, { 0, 7, 33 }, "Wood", { 168, 44, 38 }, { name = "Body" } },
			{ "Wedge", { 12, 7, 16 }, { -8, 16.5, 33 }, "WoodPlanks", { 96, 64, 52 }, { name = "RoofW", rotY = 90 } },
			{ "Wedge", { 12, 7, 16 }, { 8, 16.5, 33 }, "WoodPlanks", { 96, 64, 52 }, { name = "RoofE", rotY = -90 } },
			{ "Block", { 10, 9, 0.4 }, { 0, 5.5, 26.8 }, "Wood", { 236, 228, 214 }, { name = "Door" } },
			{ "Block", { 4, 3, 0.4 }, { 0, 15.5, 26.8 }, "SmoothPlastic", { 40, 30, 26 }, { name = "Loft" } },
		}, { primary = "Body" })

		-- Treadmill: on the boardwalk, directly in front of the plot, right of the gate
		buildModel(ctx, "Treadmill", plot, pivot, {
			{ "Block", { 18, 1, 10 }, { 18, 0.5, -48 }, "Wood", { 110, 76, 46 }, { name = "Base",
				billboard = { name = "TierDisplay", lines = { "WAGON WHEEL \u{00B7} TIER 1", "+1 / step" }, w = 12, h = 3.6, up = 6, maxDistance = 100 } } },
			{ "Block", { 14, 0.2, 7 }, { 18, 1.1, -48 }, "Fabric", { 45, 45, 48 }, { name = "Belt" } },
			{ "HCylX", { 1, 10 }, { 27.5, 5.5, -48 }, "Wood", { 130, 92, 56 }, { name = "Wheel" } },
			{ "Ball", { 2 }, { 28.2, 5.5, -48 }, "Foil", { 230, 190, 90 }, { name = "Hub" } },
			{ "Block", { 14, 0.5, 0.5 }, { 20, 4, -51.75 }, "Metal", { 90, 90, 96 }, { name = "RailL" } },
			{ "Block", { 14, 0.5, 0.5 }, { 20, 4, -44.25 }, "Metal", { 90, 90, 96 }, { name = "RailR" } },
		}, { primary = "Base", tags = { "Treadmill" }, attrs = { PlotIndex = p.index, Tier = 1 } })

		-- Decor
		local decor = newFolder("Decor", plot)
		buildParts(ctx, decor, pivot, {
			{ "HCylX", { 5, 4 }, { -24, 3, 29 }, "Grass", { 220, 190, 100 }, { name = "Hay" } },
			{ "HCylX", { 5, 4 }, { -24, 3, 33.5 }, "Grass", { 220, 190, 100 }, { name = "Hay" } },
			{ "Block", { 8, 2, 3 }, { 24, 2, 32 }, "WoodPlanks", nil, { name = "Trough" } },
			{ "Block", { 7.4, 0.2, 2.4 }, { 24, 3.05, 32 }, "SmoothPlastic", { 80, 150, 200 }, { name = "Water", nc = true } },
		}, { decor = true })

		plot.PrimaryPart = own.PlotBase
		setAttributes(plot, { PlotIndex = p.index, Row = p.row, OwnerUserId = 0, PenLevel = 1, GateLocked = false })
		addTag(ctx, plot, "Plot")
		plot.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		plot.Parent = plotsFolder
		ctx.models = ctx.models + 1
		return plot
	end

	----------------------------------------------------------------------------------------------
	-- Area props and landmarks (MAP_SPEC section 7)
	--
	-- Recipe fields:
	--   name, count, r (spacing radius), nc, noShadow, climb (keeps queries on, not decor),
	--   parts (list of part specs, or function(entry, index) returning one)
	--   Placement (one of):
	--     at = {x, z, yaw}        a landmark at a world position (placed first)
	--     fixed = { {x=, y=, z=, yaw=, ...}, ... }   one copy per entry (placed first)
	--     world = true            parts are in world coordinates; register = { {x, z, r}, ... }
	--     (none)                  seeded scatter (section 6.5): band = {min, max} |Z|, fixedYaw,
	--                             sky = {yMin, yMax}, zRange = {lo, hi}, zFixed, ignoreHerd
	--     follow = recipeIndex, offset = {dx, y, dz}   one copy per placed copy of another recipe
	--   landmark = true puts the copy in the Landmarks folder instead of Props.
	----------------------------------------------------------------------------------------------

	local function tumbleweed(rgb)
		return { name = "Tumbleweed", count = 6, r = 2, nc = true, parts = {
			{ "Ball", { 3 }, { 0, 1.5, 0 }, "Grass", rgb, { t = 0.1 } },
		} }
	end

	local function cycadParts()
		local list = { { "VCyl", { 8, 2.2 }, { 0, 4, 0 }, "Wood", { 110, 86, 56 }, { name = "Trunk" } } }
		for _, theta in ipairs({ 0, 120, 240 }) do
			local t = rad(theta)
			-- yaw so that the wedge's low edge (local -Z) points outward along theta
			table.insert(list, { "Wedge", { 1.5, 3, 7 }, { 3.5 * math.cos(t), 9, 3.5 * math.sin(t) }, "LeafyGrass", { 80, 140, 60 },
				{ name = "Frond", rotY = -(theta + 90) } })
		end
		return list
	end

	local function bootHillParts()
		local list = {}
		local wood = { 80, 72, 66 }
		for _, gz in ipairs({ -6, 0, 6 }) do
			for _, gx in ipairs({ -9, -3, 3, 9 }) do
				local corner = (gx == -9 or gx == 9) and (gz == -6 or gz == 6)
				if corner then
					table.insert(list, { "Block", { 0.5, 4, 0.5 }, { gx, 2, gz }, "Wood", wood, { name = "CrossPost" } })
					table.insert(list, { "Block", { 2.4, 0.5, 0.5 }, { gx, 3, gz }, "Wood", wood, { name = "CrossBar" } })
				else
					table.insert(list, { "Block", { 2.4, 3.2, 0.6 }, { gx, 1.6, gz }, "Slate", { 110, 110, 116 }, { name = "Tombstone" } })
				end
			end
		end
		table.insert(list, { "Block", { 26, 3, 0.4 }, { 0, 1.5, 10 }, "Wood", wood, { name = "Fence" } })
		table.insert(list, { "Block", { 26, 3, 0.4 }, { 0, 1.5, -10 }, "Wood", wood, { name = "Fence" } })
		table.insert(list, { "Block", { 0.4, 3, 20 }, { 13, 1.5, 0 }, "Wood", wood, { name = "Fence" } })
		table.insert(list, { "Block", { 0.4, 3, 20 }, { -13, 1.5, 0 }, "Wood", wood, { name = "Fence" } })
		return list
	end

	local function ribcageParts()
		local list = {}
		local bone = { 236, 226, 200 }
		for _, x in ipairs({ 2514, 2524, 2534 }) do
			for _, side in ipairs({ 1, -1 }) do
				-- each rib leans its top 40 degrees toward Z = 0
				table.insert(list, { "Block", { 1.5, 31, 1.5 }, { x, 12, 12 * side }, "Marble", bone, { name = "Rib", rotX = -40 * side } })
			end
		end
		table.insert(list, { "Block", { 26, 1.5, 1.5 }, { 2524, 24.5, 0 }, "Marble", bone, { name = "Spine" } })
		return list
	end

	local function riftGateParts()
		local list = {}
		for k = 0, 7 do
			table.insert(list, { "Block", { 1.5, 1.5, 11.6 }, nil, "Neon", { 200, 140, 255 }, { name = "Ring",
				cf = CFrame.new(3584, 18, 0) * CFrame.Angles(rad(45 * k), 0, 0) * CFrame.new(0, 14, 0) } })
		end
		table.insert(list, { "HCylX", { 0.3, 26 }, { 3584, 18, 0 }, "Neon", { 160, 80, 255 }, { name = "Disc", t = 0.6 } })
		return list
	end

	local PROP_RECIPES = {}

	PROP_RECIPES.DustyPrairie = {
		{ name = "OakTree", count = 6, r = 7, parts = {
			{ "VCyl", { 10, 2.5 }, { 0, 5, 0 }, "Wood", { 110, 76, 48 }, { name = "Trunk" } },
			{ "Ball", { 11 }, { 0, 13, 0 }, "LeafyGrass", { 88, 140, 60 }, { name = "Canopy" } },
			{ "Ball", { 8 }, { 3, 16, 2 }, "LeafyGrass", { 104, 156, 70 }, { name = "Canopy" } },
		} },
		{ name = "HayBale", count = 8, r = 3, parts = {
			{ "HCylX", { 5, 4 }, { 0, 2, 0 }, "Grass", { 220, 190, 100 } },
		} },
		{ name = "SplitRailFence", count = 6, r = 7, parts = {
			{ "VCyl", { 4, 0.8 }, { -6, 2, 0 }, "Wood", { 120, 84, 52 }, { name = "Post" } },
			{ "VCyl", { 4, 0.8 }, { 6, 2, 0 }, "Wood", { 120, 84, 52 }, { name = "Post" } },
			{ "Block", { 13, 0.5, 0.4 }, { 0, 1.5, 0 }, "Wood", { 120, 84, 52 }, { name = "Rail" } },
			{ "Block", { 13, 0.5, 0.4 }, { 0, 3, 0 }, "Wood", { 120, 84, 52 }, { name = "Rail" } },
		} },
		{ name = "Wildflowers", count = 10, r = 2, nc = true, parts = {
			{ "Ball", { 1.6 }, { 0, 0.6, 0 }, "SmoothPlastic", { 250, 210, 60 } },
			{ "Ball", { 1.4 }, { 1.2, 0.5, 0.8 }, "SmoothPlastic", { 240, 120, 160 } },
		} },
		{ name = "Boulder", count = 5, r = 5, parts = {
			{ "Ball", { 6 }, { 0, 1.5, 0 }, "Slate", { 130, 124, 116 } },
			{ "Ball", { 3.5 }, { 3, 1, 1.5 }, "Slate", { 140, 134, 126 } },
		} },
		tumbleweed({ 170, 140, 90 }),
		{ name = "Windmill", landmark = true, at = { 472, -44 }, r = 7, parts = {
			{ "Block", { 3, 20, 3 }, { 0, 10, 0 }, "Wood", { 130, 92, 56 }, { name = "Tower" } },
			{ "HCylZ", { 2, 2 }, { 0, 20, 2 }, "Metal", { 150, 150, 155 }, { name = "Hub" } },
			{ "Block", { 1, 7, 0.3 }, { 0, 23.5, 3.2 }, "SmoothPlastic", { 230, 225, 210 }, { name = "Blade" } },
			{ "Block", { 1, 7, 0.3 }, { 0, 16.5, 3.2 }, "SmoothPlastic", { 230, 225, 210 }, { name = "Blade" } },
			{ "Block", { 7, 1, 0.3 }, { -3.5, 20, 3.2 }, "SmoothPlastic", { 230, 225, 210 }, { name = "Blade" } },
			{ "Block", { 7, 1, 0.3 }, { 3.5, 20, 3.2 }, "SmoothPlastic", { 230, 225, 210 }, { name = "Blade" } },
			{ "Block", { 0.3, 3, 5 }, { 0, 20, -3 }, "Metal", { 150, 150, 155 }, { name = "Tail" } },
			{ "VCyl", { 4, 6 }, { 6, 2, 0 }, "CorrodedMetal", { 120, 110, 100 }, { name = "Tank" } },
		} },
		{ name = "CoveredWagon", landmark = true, at = { 542, -40 }, r = 7, parts = {
			{ "Block", { 10, 3, 5 }, { 0, 3, 0 }, "WoodPlanks", { 150, 104, 62 }, { name = "Body" } },
			{ "HCylX", { 10, 6 }, { 0, 5, 0 }, "Fabric", { 236, 228, 208 }, { name = "Bonnet" } },
			{ "HCylZ", { 0.6, 4 }, { -3.5, 2, 2.8 }, "Wood", { 90, 60, 36 }, { name = "Wheel" } },
			{ "HCylZ", { 0.6, 4 }, { 3.5, 2, 2.8 }, "Wood", { 90, 60, 36 }, { name = "Wheel" } },
			{ "HCylZ", { 0.6, 4 }, { -3.5, 2, -2.8 }, "Wood", { 90, 60, 36 }, { name = "Wheel" } },
			{ "HCylZ", { 0.6, 4 }, { 3.5, 2, -2.8 }, "Wood", { 90, 60, 36 }, { name = "Wheel" } },
		} },
	}

	PROP_RECIPES.CactusCanyon = {
		{ name = "Saguaro", count = 8, r = 5, parts = {
			{ "VCyl", { 14, 3 }, { 0, 7, 0 }, "Grass", { 74, 128, 64 }, { name = "Trunk" } },
			{ "Ball", { 3 }, { 0, 14, 0 }, "Grass", { 74, 128, 64 }, { name = "Top" } },
			{ "Block", { 2.5, 1.8, 1.8 }, { -2.4, 6, 0 }, "Grass", { 74, 128, 64 }, { name = "Arm" } },
			{ "VCyl", { 5, 1.8 }, { -3.6, 8.5, 0 }, "Grass", { 74, 128, 64 }, { name = "Arm" } },
			{ "Block", { 2.5, 1.8, 1.8 }, { 2.4, 8.5, 0 }, "Grass", { 74, 128, 64 }, { name = "Arm" } },
			{ "VCyl", { 4, 1.8 }, { 3.6, 10.5, 0 }, "Grass", { 74, 128, 64 }, { name = "Arm" } },
		} },
		{ name = "BarrelCactus", count = 10, r = 2, parts = {
			{ "Ball", { 3 }, { 0, 1.2, 0 }, "Grass", { 90, 140, 70 } },
			{ "Ball", { 0.9 }, { 0, 2.7, 0 }, "SmoothPlastic", { 255, 90, 140 }, { name = "Flower" } },
		} },
		{ name = "Hoodoo", count = 4, r = 4, parts = {
			{ "VCyl", { 10, 6 }, { 0, 5, 0 }, "Sandstone", { 200, 120, 80 } },
			{ "VCyl", { 5, 4.5 }, { 0, 12.5, 0 }, "Sandstone", { 220, 150, 100 } },
			{ "Ball", { 6 }, { 0, 15.5, 0 }, "Sandstone", { 180, 100, 70 } },
		} },
		{ name = "CattleSkull", count = 3, r = 2, parts = {
			{ "Ball", { 2.4 }, { 0, 1, 0 }, "Marble", { 240, 232, 214 } },
			{ "Block", { 1.4, 1, 1.8 }, { 0, 0.8, 1.4 }, "Marble", { 240, 232, 214 }, { name = "Snout" } },
			{ "HCylX", { 2.5, 0.5 }, { -1.8, 1.6, 0 }, "Marble", { 240, 232, 214 }, { name = "Horn" } },
			{ "HCylX", { 2.5, 0.5 }, { 1.8, 1.6, 0 }, "Marble", { 240, 232, 214 }, { name = "Horn" } },
		} },
		{ name = "MesaBoulder", count = 5, r = 5, parts = {
			{ "Ball", { 7 }, { 0, 2, 0 }, "Sandstone", { 190, 110, 72 } },
			{ "Ball", { 4 }, { 3.5, 1.2, -1.5 }, "Sandstone", { 205, 125, 85 } },
		} },
		{ name = "WantedPoster", count = 2, r = 3, parts = {
			{ "VCyl", { 6, 0.6 }, { -2, 3, 0 }, "Wood", { 110, 76, 46 }, { name = "Post" } },
			{ "VCyl", { 6, 0.6 }, { 2, 3, 0 }, "Wood", { 110, 76, 46 }, { name = "Post" } },
			{ "Block", { 5, 3.5, 0.3 }, { 0, 4.5, 0 }, "WoodPlanks", { 214, 186, 140 }, { name = "Poster", gui = {
				{ face = "Front", lines = { "WANTED", "RATTLESNAKE KING" }, font = "SpecialElite", color = { 60, 36, 20 }, pps = 60 },
				{ face = "Back", lines = { "WANTED", "RATTLESNAKE KING" }, font = "SpecialElite", color = { 60, 36, 20 }, pps = 60 },
			} } },
		} },
		tumbleweed({ 170, 140, 90 }),
		{ name = "OasisSpring", landmark = true, at = { 642, 42 }, r = 12, parts = {
			{ "VCyl", { 0.4, 18 }, { 0, 0.05, 0 }, "SmoothPlastic", { 70, 160, 200 }, { name = "Pool", t = 0.25, refl = 0.2, nc = true } },
			{ "VCyl", { 0.3, 21 }, { 0, 0.02, 0 }, "Sand", { 170, 130, 90 }, { name = "WetRim", nc = true } },
			{ "VCyl", { 12, 1.6 }, { -7, 6, 5 }, "Wood", { 140, 100, 60 }, { name = "PalmTrunk" } },
			{ "Ball", { 6 }, { -7, 12.5, 5 }, "LeafyGrass", { 80, 150, 60 }, { name = "Fronds" } },
			{ "VCyl", { 12, 1.6 }, { 7, 6, 5 }, "Wood", { 140, 100, 60 }, { name = "PalmTrunk" } },
			{ "Ball", { 6 }, { 7, 12.5, 5 }, "LeafyGrass", { 80, 150, 60 }, { name = "Fronds" } },
		} },
	}

	PROP_RECIPES.GoldRushMine = {
		{ name = "TimberFrame", count = 6, r = 7, parts = {
			{ "Block", { 1.5, 12, 1.5 }, { -5, 6, 0 }, "Wood", { 110, 78, 46 }, { name = "Post" } },
			{ "Block", { 1.5, 12, 1.5 }, { 5, 6, 0 }, "Wood", { 110, 78, 46 }, { name = "Post" } },
			{ "Block", { 12, 1.5, 1.5 }, { 0, 12.75, 0 }, "Wood", { 110, 78, 46 }, { name = "Beam" } },
		} },
		{ name = "Minecart", count = 4, r = 4, parts = {
			{ "Block", { 5, 3, 3.5 }, { 0, 2.5, 0 }, "CorrodedMetal", { 110, 96, 86 }, { name = "Tub" } },
			{ "Ball", { 3.6 }, { 0, 3.8, 0 }, "Foil", { 240, 190, 60 }, { name = "Ore" } },
			{ "HCylZ", { 0.4, 1.6 }, { -1.7, 0.8, 1.9 }, "Metal", { 60, 60, 64 }, { name = "Wheel" } },
			{ "HCylZ", { 0.4, 1.6 }, { 1.7, 0.8, 1.9 }, "Metal", { 60, 60, 64 }, { name = "Wheel" } },
			{ "HCylZ", { 0.4, 1.6 }, { -1.7, 0.8, -1.9 }, "Metal", { 60, 60, 64 }, { name = "Wheel" } },
			{ "HCylZ", { 0.4, 1.6 }, { 1.7, 0.8, -1.9 }, "Metal", { 60, 60, 64 }, { name = "Wheel" } },
		} },
		{ name = "RailTrack", count = 3, r = 12, fixedYaw = 0, band = { 30, 50 }, parts = {
			{ "Block", { 24, 0.3, 0.4 }, { 0, 0.15, 1.6 }, "Metal", { 90, 90, 96 }, { name = "Rail" } },
			{ "Block", { 24, 0.3, 0.4 }, { 0, 0.15, -1.6 }, "Metal", { 90, 90, 96 }, { name = "Rail" } },
			{ "Block", { 24, 0.1, 4.4 }, { 0, 0.05, 0 }, "WoodPlanks", { 110, 80, 56 }, { name = "Bed" } },
		} },
		{ name = "GoldOre", count = 8, r = 3, parts = {
			{ "Ball", { 3 }, { 0, 1, 0 }, "Foil", { 255, 196, 40 } },
			{ "Ball", { 2 }, { 1.5, 0.8, 1 }, "Neon", { 255, 210, 80 } },
			{ "Ball", { 4 }, { -1.4, 1.2, -0.8 }, "Slate", { 100, 92, 86 } },
		} },
		{ name = "LanternPost", count = 6, r = 2, parts = {
			{ "VCyl", { 8, 0.6 }, { 0, 4, 0 }, "Wood", { 110, 78, 46 }, { name = "Pole" } },
			{ "Block", { 1.6, 0.3, 0.3 }, { 0.8, 7.8, 0 }, "Wood", { 110, 78, 46 }, { name = "Arm" } },
			{ "Ball", { 1.2 }, { 1.6, 7.2, 0 }, "Neon", { 255, 180, 80 }, { name = "Lantern", light = { range = 14, brightness = 1.5 } } },
		} },
		{ name = "DynamiteCrate", count = 4, r = 2, parts = {
			{ "Block", { 3, 2.4, 2.4 }, { 0, 1.2, 0 }, "WoodPlanks", { 160, 112, 64 }, { name = "Crate" } },
			{ "HCylX", { 2.6, 0.6 }, { 0, 2.7, 0.5 }, "SmoothPlastic", { 200, 40, 40 }, { name = "Stick" } },
			{ "HCylX", { 2.6, 0.6 }, { 0, 2.7, -0.5 }, "SmoothPlastic", { 200, 40, 40 }, { name = "Stick" } },
		} },
		{ name = "RockPile", count = 5, r = 4, parts = {
			{ "Ball", { 5 }, { 0, 1.5, 0 }, "Slate", { 100, 92, 86 } },
			{ "Ball", { 3 }, { 2.4, 1, 1 }, "Pebble", { 128, 112, 96 } },
		} },
		{ name = "MineMouth", landmark = true, world = true, register = { { 844, -52, 9 } }, parts = {
			{ "Block", { 14, 12, 1 }, { 844, 6, -56 }, "SmoothPlastic", { 20, 18, 16 }, { name = "Opening" } },
			{ "Block", { 1.6, 13, 1.6 }, { 836.2, 6.5, -55 }, "Wood", nil, { name = "Post" } },
			{ "Block", { 1.6, 13, 1.6 }, { 851.8, 6.5, -55 }, "Wood", nil, { name = "Post" } },
			{ "Block", { 17, 1.6, 1.6 }, { 844, 13.3, -55 }, "Wood", nil, { name = "Lintel" } },
			{ "Block", { 8, 2, 0.3 }, { 844, 15, -54.8 }, "WoodPlanks", nil, { name = "Sign", gui = {
				{ face = "Back", lines = { "BIG DIGGER MINE CO." }, pps = 40 },
			} } },
			{ "Block", { 4, 0.3, 10 }, { 844, 0.15, -49 }, "Metal", { 90, 90, 96 }, { name = "RailSpur" } },
		} },
	}

	PROP_RECIPES.BayouSwamp = {
		{ name = "Cypress", count = 8, r = 7, parts = {
			{ "VCyl", { 3, 5 }, { 0, 1.5, 0 }, "Wood", { 92, 74, 54 }, { name = "Flare" } },
			{ "VCyl", { 16, 2.6 }, { 0, 9, 0 }, "Wood", { 92, 74, 54 }, { name = "Trunk" } },
			{ "Ball", { 12 }, { 0, 18, 0 }, "LeafyGrass", { 60, 92, 50 }, { name = "Canopy" } },
			{ "Block", { 0.4, 6, 6 }, { 0, 13, 0 }, "Grass", { 110, 130, 80 }, { name = "Moss", t = 0.2, nc = true } },
		} },
		{ name = "SwampPool", count = 5, r = 9, nc = true, parts = {
			{ "VCyl", { 0.4, 16 }, { 0, 0.05, 0 }, "SmoothPlastic", { 60, 92, 70 }, { name = "Water", t = 0.2, refl = 0.15 } },
			{ "VCyl", { 0.3, 18 }, { 0, 0, 0 }, "Mud", { 70, 62, 44 }, { name = "Rim" } },
		} },
		-- one per pool at pool origin + (3, 0, 2); y 0.2 (spec 0.15) so the pads sit just above the water
		{ name = "LilyPads", follow = 2, offset = { 3, 0, 2 }, nc = true, parts = {
			{ "VCyl", { 0.2, 2.4 }, { 0, 0.2, 0 }, "LeafyGrass", { 80, 140, 60 } },
			{ "VCyl", { 0.2, 2.4 }, { 1.8, 0.2, 1 }, "LeafyGrass", { 80, 140, 60 } },
			{ "VCyl", { 0.2, 2.4 }, { -1.5, 0.2, 1.6 }, "LeafyGrass", { 80, 140, 60 } },
		} },
		{ name = "ReedClump", count = 8, r = 2, nc = true, parts = {
			{ "VCyl", { 4, 0.3 }, { 0, 2, 0 }, "Grass", { 110, 130, 70 }, { name = "Reed" } },
			{ "VCyl", { 3.4, 0.3 }, { 0.6, 1.7, 0.4 }, "Grass", { 110, 130, 70 }, { name = "Reed" } },
			{ "VCyl", { 1, 0.6 }, { 0, 4.3, 0 }, "SmoothPlastic", { 100, 70, 40 }, { name = "Cattail" } },
		} },
		{ name = "FallenLog", count = 4, r = 6, parts = {
			{ "HCylX", { 10, 2.2 }, { 0, 1, 0 }, "Wood", { 90, 70, 50 }, { name = "Log" } },
			{ "Block", { 5, 0.4, 2 }, { 1, 2.1, 0 }, "Grass", { 90, 120, 60 }, { name = "Moss" } },
		} },
		{ name = "Fireflies", count = 6, nc = true, noShadow = true, parts = {
			{ "Ball", { 0.4 }, { 0, 3, 0 }, "Neon", { 210, 255, 120 } },
			{ "Ball", { 0.4 }, { 1.5, 4, 1 }, "Neon", { 210, 255, 120 } },
			{ "Ball", { 0.4 }, { -1, 5, -1.2 }, "Neon", { 210, 255, 120 } },
		} },
		{ name = "CrocSnoutRock", count = 3, r = 4, parts = {
			{ "Block", { 6, 1, 2 }, { 0, 0.3, 0 }, "Grass", { 70, 90, 50 }, { name = "Snout" } },
			{ "Ball", { 0.8 }, { -2.2, 0.9, 0.6 }, "Neon", { 255, 220, 60 }, { name = "Eye" } },
			{ "Ball", { 0.8 }, { -2.2, 0.9, -0.6 }, "Neon", { 255, 220, 60 }, { name = "Eye" } },
		} },
		{ name = "StiltShack", landmark = true, at = { 1078, 46 }, r = 9, parts = {
			{ "VCyl", { 6, 1 }, { 5, 3, 4 }, "Wood", { 90, 70, 50 }, { name = "Stilt" } },
			{ "VCyl", { 6, 1 }, { -5, 3, 4 }, "Wood", { 90, 70, 50 }, { name = "Stilt" } },
			{ "VCyl", { 6, 1 }, { 5, 3, -4 }, "Wood", { 90, 70, 50 }, { name = "Stilt" } },
			{ "VCyl", { 6, 1 }, { -5, 3, -4 }, "Wood", { 90, 70, 50 }, { name = "Stilt" } },
			{ "Block", { 12, 1, 10 }, { 0, 6.5, 0 }, "WoodPlanks", { 116, 90, 60 }, { name = "Floor" } },
			{ "Block", { 10, 6, 8 }, { 0, 10, 0 }, "Wood", { 110, 86, 60 }, { name = "Walls" } },
			{ "Wedge", { 12, 3, 5 }, { 0, 14.5, 2.5 }, "WoodPlanks", { 80, 64, 48 }, { name = "Roof", rotY = 180 } },
			{ "Wedge", { 12, 3, 5 }, { 0, 14.5, -2.5 }, "WoodPlanks", { 80, 64, 48 }, { name = "Roof" } },
			{ "Block", { 2.4, 4, 0.2 }, { 0, 9, -4.1 }, "SmoothPlastic", { 30, 24, 20 }, { name = "Door" } },
		} },
	}

	PROP_RECIPES.FrostPeak = {
		{ name = "TieredPine", count = 10, r = 6, parts = {
			{ "VCyl", { 4, 1.6 }, { 0, 2, 0 }, "Wood", { 90, 64, 44 }, { name = "Trunk" } },
			{ "VCyl", { 4, 12 }, { 0, 5, 0 }, "LeafyGrass", { 40, 84, 60 }, { name = "Tier" } },
			{ "VCyl", { 4, 9 }, { 0, 9, 0 }, "LeafyGrass", { 40, 84, 60 }, { name = "Tier" } },
			{ "VCyl", { 4, 6 }, { 0, 13, 0 }, "Snow", { 240, 244, 250 }, { name = "TopTier" } },
		} },
		{ name = "SnowBoulder", count = 6, r = 4, parts = {
			{ "Ball", { 7 }, { 0, 2, 0 }, "Rock", { 160, 168, 180 } },
			{ "Ball", { 6 }, { 0, 3.4, 0 }, "Snow", { 240, 244, 250 }, { name = "Cap" } },
		} },
		{ name = "IceCrystal", count = 8, r = 3, parts = {
			{ "Block", { 2, 8, 2 }, { 0, 4, 0 }, "Ice", { 160, 220, 255 }, { t = 0.2, rotZ = 15 } },
			{ "Block", { 1.4, 5, 1.4 }, { 1.4, 2.5, 0.8 }, "Ice", { 160, 220, 255 }, { t = 0.2, rotZ = -20 } },
			{ "Block", { 1.2, 4, 1.2 }, { -1, 2, -1 }, "Ice", { 160, 220, 255 }, { t = 0.2, rotX = 25 } },
		} },
		{ name = "Snowman", count = 3, r = 3, parts = {
			{ "Ball", { 5 }, { 0, 2.5, 0 }, "Snow", { 240, 244, 250 } },
			{ "Ball", { 3.6 }, { 0, 6.3, 0 }, "Snow", { 240, 244, 250 } },
			{ "Ball", { 2.6 }, { 0, 9.2, 0 }, "Snow", { 240, 244, 250 }, { name = "Head" } },
			{ "HCylZ", { 1.2, 0.4 }, { 0, 9.2, 1.6 }, "SmoothPlastic", { 255, 140, 40 }, { name = "Nose" } },
			{ "VCyl", { 1.6, 2 }, { 0, 11, 0 }, "SmoothPlastic", { 25, 25, 30 }, { name = "Hat" } },
		} },
		{ name = "LogPile", count = 4, r = 4, parts = {
			{ "HCylX", { 6, 1.4 }, { 0, 0.7, 0.75 }, "Wood", { 110, 80, 54 } },
			{ "HCylX", { 6, 1.4 }, { 0, 0.7, -0.75 }, "Wood", { 110, 80, 54 } },
			{ "HCylX", { 6, 1.4 }, { 0, 1.9, 0 }, "Wood", { 110, 80, 54 } },
		} },
		{ name = "SnowDrift", count = 6, r = 5, parts = {
			{ "Ball", { 8 }, { 0, -2, 0 }, "Snow", { 240, 244, 250 } },
		} },
		-- slippery on purpose (Glacier), so it keeps CanCollide
		{ name = "FrozenPond", count = 2, r = 10, band = { 30, 50 }, parts = {
			{ "VCyl", { 0.3, 20 }, { 0, 0.1, 0 }, "Glacier", { 180, 215, 240 } },
		} },
		{ name = "Igloo", landmark = true, at = { 1324, -44 }, r = 10, parts = {
			{ "Ball", { 16 }, { 0, 0, 0 }, "Snow", { 240, 244, 250 }, { name = "Dome" } },
			{ "HCylZ", { 5, 6 }, { 0, 1.5, 8 }, "Snow", { 240, 244, 250 }, { name = "Tunnel" } },
			{ "Block", { 3, 3.5, 0.2 }, { 0, 1.75, 10.6 }, "SmoothPlastic", { 20, 20, 24 }, { name = "Door" } },
		} },
	}

	PROP_RECIPES.VolcanoRidge = {
		{ name = "MiniVolcano", landmark = true, climb = true, at = { 1712, 40 }, r = 16, parts = {
			{ "VCyl", { 6, 30 }, { 0, 3, 0 }, "Basalt", { 56, 48, 48 }, { name = "Step1" } },
			{ "VCyl", { 6, 22 }, { 0, 9, 0 }, "Basalt", { 66, 56, 54 }, { name = "Step2" } },
			{ "VCyl", { 6, 14 }, { 0, 15, 0 }, "Rock", { 80, 64, 60 }, { name = "Step3" } },
			{ "VCyl", { 0.6, 10 }, { 0, 18.1, 0 }, "Neon", { 255, 110, 30 }, { name = "Lava" } },
			{ "Ball", { 2 }, { 2, 18.4, 1 }, "Neon", { 255, 170, 60 }, { name = "Bubble" } },
			{ "Ball", { 1.6 }, { -2, 18.4, -1.5 }, "Neon", { 255, 170, 60 }, { name = "Bubble" } },
			{ "Block", { 2, 2, 2 }, { 0, 20, 0 }, nil, nil, { name = "SmokeVent", invisible = true, emitter = "smoke" } },
		} },
		-- lava at y 0.1 (spec 0.05) so its top clears the rim's top instead of z-fighting with it
		{ name = "LavaPool", count = 5, r = 7, nc = true, parts = {
			{ "VCyl", { 0.4, 12 }, { 0, 0.1, 0 }, "Neon", { 255, 100, 20 }, { name = "Lava" } },
			{ "VCyl", { 0.5, 14 }, { 0, 0, 0 }, "Basalt", { 40, 36, 36 }, { name = "Rim" } },
		} },
		{ name = "ObsidianSpike", count = 8, r = 3, parts = {
			{ "Block", { 2.5, 9, 2.5 }, { 0, 4.5, 0 }, "Glass", { 30, 20, 40 }, { refl = 0.2, rotZ = 10 } },
			{ "Block", { 1.6, 6, 1.6 }, { 1.6, 3, 0.8 }, "Glass", { 30, 20, 40 }, { refl = 0.2, rotZ = -15 } },
		} },
		{ name = "CharredTree", count = 6, r = 4, parts = {
			{ "VCyl", { 12, 1.6 }, { 0, 6, 0 }, "Wood", { 40, 34, 30 }, { name = "Trunk" } },
			{ "Block", { 5, 0.8, 0.8 }, { 1.8, 9, 0 }, "Wood", { 40, 34, 30 }, { name = "Branch", rotZ = 30 } },
			{ "Block", { 4, 0.7, 0.7 }, { -1.6, 10.5, 0 }, "Wood", { 40, 34, 30 }, { name = "Branch", rotZ = -35 } },
		} },
		{ name = "MagmaRock", count = 8, r = 4, parts = {
			{ "Ball", { 6 }, { 0, 1.8, 0 }, "CrackedLava", { 70, 50, 44 } },
			{ "Ball", { 3 }, { 2.6, 1, 1.4 }, "Basalt", { 58, 52, 52 } },
		} },
		-- origin at the splash (X, 0, +-54); the fall hangs on the cliff face at |Z| 63.4
		{ name = "LavaFall", nc = true, r = 4, fixed = {
			{ x = 1592, z = 54, side = 1 },
			{ x = 1672, z = -54, side = -1 },
			{ x = 1772, z = 54, side = 1 },
			{ x = 1842, z = -54, side = -1 },
		}, parts = function(e)
			return {
				{ "Block", { 6, 30, 1 }, { 0, 15, 9.4 * e.side }, "Neon", { 255, 120, 30 }, { name = "Fall", t = 0.1 } },
				{ "VCyl", { 0.4, 8 }, { 0, 0.05, 0 }, "Neon", { 255, 120, 30 }, { name = "Splash" } },
			}
		end },
		{ name = "EmberBrazier", count = 4, r = 3, parts = {
			{ "VCyl", { 3, 1 }, { 0, 1.5, 0 }, "Metal", { 60, 56, 56 }, { name = "Stand" } },
			{ "VCyl", { 1.5, 4 }, { 0, 3.75, 0 }, "Metal", { 60, 56, 56 }, { name = "Bowl" } },
			{ "Ball", { 2.6 }, { 0, 5, 0 }, "Neon", { 255, 140, 40 }, { name = "Fire", fire = true, light = { range = 16 } } },
		} },
		{ name = "AshDune", count = 4, r = 6, parts = {
			{ "Ball", { 10 }, { 0, -3, 0 }, "Ground", { 90, 80, 76 } },
		} },
	}

	PROP_RECIPES.StormMesa = {
		{ name = "RockSpire", count = 6, r = 6, parts = {
			{ "VCyl", { 12, 8 }, { 0, 6, 0 }, "Slate", { 100, 100, 112 } },
			{ "VCyl", { 10, 5.5 }, { 0, 17, 0 }, "Slate", { 116, 116, 128 } },
			{ "VCyl", { 6, 3 }, { 0, 25, 0 }, "Slate", { 130, 130, 140 } },
		} },
		{ name = "LightningRod", count = 6, r = 2, parts = {
			{ "Block", { 2, 1, 2 }, { 0, 0.5, 0 }, "Metal", { 150, 150, 160 }, { name = "Base" } },
			{ "VCyl", { 14, 0.6 }, { 0, 7, 0 }, "Metal", { 150, 150, 160 }, { name = "Pole" } },
			{ "Ball", { 1.2 }, { 0, 14.4, 0 }, "Neon", { 140, 230, 255 }, { name = "Tip" } },
		} },
		{ name = "StormCrystal", count = 8, r = 3, parts = {
			{ "Block", { 1.8, 6, 1.8 }, { 0, 3, 0 }, "Neon", { 120, 210, 255 }, { t = 0.15, rotZ = 15 } },
			{ "Block", { 1.2, 4, 1.2 }, { 1.2, 2, 0.6 }, "Glass", { 180, 230, 255 }, { rotZ = -20 } },
		} },
		{ name = "StormCloud", count = 6, nc = true, noShadow = true, sky = { 60, 60 }, zRange = { -40, 40 }, ignoreHerd = true, parts = {
			{ "Ball", { 18 }, { 0, 0, 0 }, "SmoothPlastic", { 90, 94, 108 }, { t = 0.15 } },
			{ "Ball", { 14 }, { 10, -2, 3 }, "SmoothPlastic", { 90, 94, 108 }, { t = 0.15 } },
			{ "Ball", { 12 }, { -9, -1, -4 }, "SmoothPlastic", { 90, 94, 108 }, { t = 0.15 } },
		} },
		{ name = "WindsweptTree", count = 5, r = 4, parts = {
			{ "VCyl", { 10, 1.4 }, { 0, 5, 0 }, "Wood", { 96, 84, 72 }, { name = "Trunk", rotZ = 12 } },
			{ "Block", { 5, 0.6, 0.6 }, { 1.5, 8, 0 }, "Wood", { 96, 84, 72 }, { name = "Branch", rotZ = 25 } },
			{ "Block", { 4, 0.5, 0.5 }, { -1.2, 9.5, 0.5 }, "Wood", { 96, 84, 72 }, { name = "Branch", rotZ = -30 } },
		} },
		{ name = "Boulder", count = 6, r = 5, parts = {
			{ "Ball", { 7 }, { 0, 2, 0 }, "Slate", { 100, 100, 112 } },
			{ "Ball", { 4 }, { 3, 1.2, 1 }, "Rock", { 110, 110, 120 } },
		} },
		{ name = "CaveHole", landmark = true, world = true, register = { { 1960, 57, 7 } }, parts = {
			{ "Block", { 8, 9, 1 }, { 1960, 4.5, 57 }, "SmoothPlastic", { 12, 12, 16 }, { name = "Opening" } },
			{ "Ball", { 4 }, { 1955.5, 2, 57.5 }, "Slate", { 84, 86, 98 }, { name = "Frame" } },
			{ "Ball", { 4 }, { 1964.5, 2, 57.5 }, "Slate", { 84, 86, 98 }, { name = "Frame" } },
			{ "Ball", { 5 }, { 1960, 9, 57.5 }, "Slate", { 84, 86, 98 }, { name = "Lintel" } },
			{ "Block", { 4, 4, 4 }, { 1960, 2, 55 }, nil, nil, { name = "SecretSpot", invisible = true, secret = "StormVault" } },
		} },
		{ name = "BrokenWindmill", landmark = true, at = { 2132, -44 }, r = 7, parts = {
			{ "Block", { 3, 18, 3 }, { 0, 9, 0 }, "Wood", { 96, 80, 66 }, { name = "Tower", rotZ = 6 } },
			{ "HCylZ", { 2, 2 }, { 0, 18, 2 }, "Metal", { 150, 150, 155 }, { name = "Hub" } },
			{ "Block", { 1, 7, 0.3 }, { 0, 21.5, 3.2 }, "SmoothPlastic", { 200, 196, 186 }, { name = "Blade" } },
			{ "Block", { 7, 1, 0.3 }, { -3.5, 18, 3.2 }, "SmoothPlastic", { 200, 196, 186 }, { name = "Blade" } },
		} },
	}

	PROP_RECIPES.DinoBadlands = {
		{ name = "GiantFern", count = 10, r = 4, parts = {
			{ "Wedge", { 1.5, 5, 5 }, { 0, 2.5, 2.5 }, "LeafyGrass", { 70, 130, 50 }, { name = "Frond", rotY = 180 } },
			{ "Wedge", { 1.5, 5, 5 }, { 0, 2.5, -2.5 }, "LeafyGrass", { 70, 130, 50 }, { name = "Frond" } },
			{ "Wedge", { 1.5, 5, 5 }, { 2.5, 2.5, 0 }, "LeafyGrass", { 70, 130, 50 }, { name = "Frond", rotY = -90 } },
			{ "Wedge", { 1.5, 5, 5 }, { -2.5, 2.5, 0 }, "LeafyGrass", { 70, 130, 50 }, { name = "Frond", rotY = 90 } },
		} },
		{ name = "CycadPalm", count = 6, r = 5, parts = cycadParts() },
		{ name = "FossilBone", count = 5, r = 4, parts = {
			{ "HCylX", { 6, 1 }, { 0, 0.5, 0 }, "Marble", { 236, 226, 200 }, { name = "Shaft" } },
			{ "Ball", { 1.6 }, { 3, 0.6, 0 }, "Marble", { 236, 226, 200 }, { name = "Knob" } },
			{ "Ball", { 1.6 }, { -3, 0.6, 0 }, "Marble", { 236, 226, 200 }, { name = "Knob" } },
		} },
		{ name = "TarPit", count = 3, r = 7, nc = true, parts = {
			{ "VCyl", { 0.4, 12 }, { 0, 0.05, 0 }, "SmoothPlastic", { 20, 18, 22 }, { name = "Tar", refl = 0.3 } },
			{ "Ball", { 1.5 }, { 2, 0.3, 1 }, "SmoothPlastic", { 30, 28, 32 }, { name = "Bubble" } },
		} },
		{ name = "SteamGeyser", count = 3, r = 4, parts = {
			{ "VCyl", { 1.5, 6 }, { 0, 0.75, 0 }, "Rock", { 130, 110, 90 }, { name = "Mound" } },
			{ "VCyl", { 0.3, 2 }, { 0, 1.6, 0 }, "SmoothPlastic", { 20, 20, 20 }, { name = "Vent" } },
			{ "Block", { 1, 1, 1 }, { 0, 2, 0 }, nil, nil, { name = "SteamEmitter", invisible = true, emitter = "steam" } },
		} },
		{ name = "Boulder", count = 6, r = 5, parts = {
			{ "Ball", { 7 }, { 0, 2, 0 }, "Sandstone", { 170, 96, 66 } },
			{ "Ball", { 4 }, { 3, 1.2, 1 }, "Sandstone", { 196, 128, 86 } },
		} },
		{ name = "StepBlocks", landmark = true, climb = true, world = true, register = { { 2406, -48, 10 } }, parts = {
			{ "Block", { 6, 1.5, 6 }, { 2414, 2, -40 }, "Grass", { 90, 170, 70 }, { name = "Step1" } },
			{ "Block", { 6, 1.5, 6 }, { 2406, 5, -44 }, "Grass", { 90, 170, 70 }, { name = "Step2" } },
			{ "Block", { 6, 1.5, 6 }, { 2398, 8, -50 }, "Grass", { 90, 170, 70 }, { name = "Step3" } },
			{ "Block", { 6, 1.5, 6 }, { 2404, 11, -55 }, "Grass", { 90, 170, 70 }, { name = "Step4" } },
			{ "Block", { 6, 1.5, 6 }, { 2412, 14, -56 }, "Grass", { 90, 170, 70 }, { name = "Step5" } },
			{ "Block", { 2, 2, 2 }, { 2412, 16, -56 }, nil, nil, { name = "SecretSpot", invisible = true, secret = "RexLookout" } },
			{ "Ball", { 5 }, { 2442, 1.8, -58 }, "LeafyGrass", { 70, 120, 50 }, { name = "Bush", decor = true } },
			{ "Ball", { 5 }, { 2454, 1.8, -60 }, "LeafyGrass", { 70, 120, 50 }, { name = "Bush", decor = true } },
			{ "Ball", { 5 }, { 2466, 1.8, -58 }, "LeafyGrass", { 70, 120, 50 }, { name = "Bush", decor = true } },
		} },
		{ name = "Ribcage", landmark = true, world = true, register = { { 2524, 22, 12 }, { 2524, -22, 12 } }, parts = ribcageParts() },
	}

	PROP_RECIPES.GhostTown = {
		{ name = "FalseFront", r = 9, fixed = {
			{ x = 2650, z = 50, yaw = 0, label = "SALOON" },
			{ x = 2712, z = 50, yaw = 0, label = "BANK" },
			{ x = 2800, z = -50, yaw = 180, label = "JAIL" },
			{ x = 2860, z = -50, yaw = 180, label = "HOTEL" },
			{ x = 2920, z = -50, yaw = 180, label = "ASSAY OFFICE" },
			{ x = 2980, z = -50, yaw = 180, label = "BARBER" },
		}, parts = function(e)
			return {
				{ "Block", { 16, 16, 1 }, { 0, 8, 0 }, "WoodPlanks", { 110, 96, 82 }, { name = "Facade", gui = {
					{ face = "Front", lines = { e.label }, font = "Creepster", color = { 170, 255, 210 }, rows = { { 0.04, 0.2 } } },
				} } },
				{ "Block", { 14, 10, 10 }, { 0, 5, 5.5 }, "Wood", { 90, 80, 70 }, { name = "Body" } },
				{ "Block", { 4, 3, 0.2 }, { -4, 9, -0.6 }, "Neon", { 120, 255, 180 }, { name = "Window", t = 0.4 } },
				{ "Block", { 3, 6, 0.2 }, { 3, 3, -0.6 }, "SmoothPlastic", { 20, 20, 20 }, { name = "Door" } },
			}
		end },
		{ name = "BootHill", landmark = true, at = { 2716, -44 }, r = 15, parts = bootHillParts() },
		{ name = "DeadTree", count = 6, r = 4, parts = {
			{ "VCyl", { 14, 1.6 }, { 0, 7, 0 }, "Wood", { 54, 48, 46 }, { name = "Trunk" } },
			{ "Block", { 5, 0.7, 0.7 }, { 1.8, 10, 0 }, "Wood", { 54, 48, 46 }, { name = "Branch", rotZ = 35 } },
			{ "Block", { 4, 0.6, 0.6 }, { -1.5, 11.5, 0.4 }, "Wood", { 54, 48, 46 }, { name = "Branch", rotZ = -40 } },
			{ "Block", { 3, 0.5, 0.5 }, { 0.6, 13, -1 }, "Wood", { 54, 48, 46 }, { name = "Branch", rotX = 30 } },
		} },
		{ name = "GhostLantern", count = 6, r = 2, parts = {
			{ "VCyl", { 9, 0.5 }, { 0, 4.5, 0 }, "Wood", { 54, 48, 46 }, { name = "Pole" } },
			{ "Block", { 1.6, 0.3, 0.3 }, { 0.8, 8.8, 0 }, "Wood", { 54, 48, 46 }, { name = "Arm" } },
			{ "Ball", { 1.2 }, { 1.6, 8.2, 0 }, "Neon", { 110, 255, 170 }, { name = "Lantern", light = { range = 14, color = { 110, 255, 170 } } } },
		} },
		{ name = "BrokenWagon", count = 2, r = 5, parts = {
			{ "Block", { 8, 2, 4 }, { 0, 1.5, 0 }, "WoodPlanks", { 90, 80, 70 }, { name = "Body", rotZ = 8 } },
			{ "HCylZ", { 0.6, 4 }, { -3, 2, 2.3 }, "Wood", { 60, 52, 48 }, { name = "Wheel" } },
			{ "HCylZ", { 0.6, 4 }, { 3, 2, 2.3 }, "Wood", { 60, 52, 48 }, { name = "Wheel" } },
			{ "HCylZ", { 0.6, 4 }, { -3, 2, -2.3 }, "Wood", { 60, 52, 48 }, { name = "Wheel" } },
		} },
		{ name = "Wisp", count = 8, nc = true, noShadow = true, sky = { 3, 8 }, parts = {
			{ "Ball", { 1.4 }, { 0, 0, 0 }, "Neon", { 170, 255, 220 }, { t = 0.3 } },
		} },
		tumbleweed({ 110, 100, 80 }),
		{ name = "WaterTower", landmark = true, at = { 2938, 48 }, r = 8, parts = {
			{ "Block", { 1, 16, 1 }, { 4, 8, 4 }, "Wood", { 80, 70, 62 }, { name = "Leg" } },
			{ "Block", { 1, 16, 1 }, { -4, 8, 4 }, "Wood", { 80, 70, 62 }, { name = "Leg" } },
			{ "Block", { 1, 16, 1 }, { 4, 8, -4 }, "Wood", { 80, 70, 62 }, { name = "Leg" } },
			{ "Block", { 1, 16, 1 }, { -4, 8, -4 }, "Wood", { 80, 70, 62 }, { name = "Leg" } },
			{ "VCyl", { 8, 10 }, { 0, 20, 0 }, "WoodPlanks", { 90, 80, 70 }, { name = "Tank" } },
			{ "VCyl", { 1, 11 }, { 0, 24.5, 0 }, "Wood", { 60, 52, 48 }, { name = "Roof" } },
		} },
	}

	PROP_RECIPES.CosmicRift = {
		{ name = "FloatingIsland", count = 6, nc = true, sky = { 30, 50 }, zFixed = 40, ignoreHerd = true, parts = {
			{ "Ball", { 14 }, { 0, 0, 0 }, "Slate", { 60, 48, 96 }, { name = "Rock" } },
			{ "Block", { 12, 2, 12 }, { 0, 6, 0 }, "LeafyGrass", { 110, 90, 200 }, { name = "Top" } },
			{ "Block", { 1.5, 5, 1.5 }, { 2, 9, 1 }, "Neon", { 220, 160, 255 }, { name = "Crystal" } },
		} },
		{ name = "CrystalPillar", count = 10, r = 4, parts = {
			{ "Block", { 3, 14, 3 }, { 0, 7, 0 }, "Glass", { 150, 110, 255 }, { t = 0.1, rotZ = 8 } },
			{ "Block", { 2, 9, 2 }, { 2, 4.5, 1 }, "Neon", { 200, 150, 255 }, { rotZ = -12 } },
			{ "Block", { 1.6, 6, 1.6 }, { -1.6, 3, -1 }, "Glass", { 150, 110, 255 } },
		} },
		{ name = "RiftCrack", count = 8, nc = true, band = { 0, 56 }, parts = {
			{ "Block", { 24, 0.2, 1.2 }, { 0, 0.02, 0 }, "Neon", { 180, 90, 255 } },
		} },
		-- outside the walls; no shadows so the 60-stud planets do not darken the lane [assumed]
		{ name = "Planet", nc = true, noShadow = true, fixed = {
			{ x = 3144, y = 170, z = 260, rgb = { 220, 120, 90 } },
			{ x = 3354, y = 200, z = -300, rgb = { 90, 160, 255 } },
			{ x = 3544, y = 150, z = 220, rgb = { 255, 200, 120 } },
		}, parts = function(e)
			return {
				{ "Ball", { 60 }, { 0, 0, 0 }, "SmoothPlastic", e.rgb, { name = "Globe" } },
				{ "VCyl", { 0.5, 100 }, { 0, 0, 0 }, "Neon", { 255, 220, 160 }, { name = "Ring", t = 0.5, rotX = 20 } },
			}
		end },
		{ name = "StarMote", count = 12, nc = true, noShadow = true, sky = { 10, 40 }, parts = {
			{ "Ball", { 0.8 }, { 0, 0, 0 }, "Neon", { 255, 255, 255 } },
		} },
		{ name = "GlowingCrater", count = 4, r = 9, parts = {
			{ "VCyl", { 1, 18 }, { 0, 0.3, 0 }, "Basalt", { 40, 34, 60 }, { name = "Rim" } },
			{ "VCyl", { 1.2, 12 }, { 0, 0.3, 0 }, "Neon", { 255, 120, 60 }, { name = "Glow" } },
			{ "Ball", { 4 }, { 2, 1.5, 0 }, "CrackedLava", { 80, 50, 60 }, { name = "Meteor" } },
		} },
		{ name = "AuroraRibbon", nc = true, noShadow = true, fixed = {
			{ x = 3144, y = 90, z = 40 },
			{ x = 3312, y = 95, z = 0, yaw = 10 },
			{ x = 3480, y = 90, z = -40 },
		}, parts = {
			{ "Block", { 120, 30, 0.5 }, { 0, 0, 0 }, "Neon", { 90, 255, 200 }, { t = 0.7 } },
		} },
		{ name = "CosmicBoulder", count = 6, r = 5, parts = {
			{ "Ball", { 8 }, { 0, 2.5, 0 }, "Slate", { 60, 50, 90 } },
			{ "Ball", { 4 }, { 3, 1.5, 1 }, "Glass", { 150, 110, 255 } },
		} },
		{ name = "RiftGate", landmark = true, nc = true, world = true, parts = riftGateParts() },
	}

	-- Extra entrance parts per area id (section 7)
	local ENTRANCE_EXTRAS = {
		FrostPeak = {
			{ "Block", { 1.8, 1, 68 }, { 0, 36.5, 0 }, "Snow", { 240, 244, 250 }, { name = "SnowCap" } },
		},
	}

	local function placeInstance(ctx, rec, parent, index, total, x, y, z, yaw, entry)
		local m = Instance.new("Model")
		if total > 1 then
			m.Name = string.format("%s_%02d", rec.name, index)
		else
			m.Name = rec.name
		end
		local base = CFrame.new(x, y, z)
		if yaw ~= 0 then
			base = base * CFrame.Angles(0, rad(yaw), 0)
		end
		local specs = rec.parts
		if type(specs) == "function" then
			specs = specs(entry or EMPTY, index)
		end
		local defaults = { decor = not rec.climb, nc = rec.nc, noShadow = rec.noShadow, name = rec.name }
		local _, list = buildParts(ctx, m, base, specs, defaults)
		m.PrimaryPart = list[1]
		m.Parent = parent
		ctx.models = ctx.models + 1
		return m
	end

	local function isFixedRecipe(rec)
		return rec.at ~= nil or rec.fixed ~= nil or rec.world == true
	end

	-- Landmarks and fixed props first, then the seeded scatter (section 6.5).
	local function buildAreaProps(ctx, a, areaModel)
		local landmarks = newFolder("Landmarks", areaModel)
		local props = newFolder("Props", areaModel)
		local recipes = PROP_RECIPES[a.id]
		if not recipes then
			return
		end
		local placed = {}
		local positions = {}

		local function register(x, z, r)
			table.insert(placed, { x = x, z = z, r = r })
		end
		-- strict = the spec's rule (closer than r + rOther + 2). The relaxed rule only keeps the
		-- bigger of the two footprints clear; it is used after 60 strict tries fail.
		local function tooClose(x, z, r, relaxed)
			for _, p in ipairs(placed) do
				local dx, dz = x - p.x, z - p.z
				local limit = r + p.r + 2
				if relaxed then
					limit = math.max(r, p.r) + 1
				end
				if dx * dx + dz * dz < limit * limit then
					return true
				end
			end
			return false
		end

		for ri, rec in ipairs(recipes) do
			if isFixedRecipe(rec) then
				local dest = rec.landmark and landmarks or props
				positions[ri] = {}
				if rec.world then
					placeInstance(ctx, rec, dest, 1, 1, 0, 0, 0, 0, nil)
					for _, reg in ipairs(rec.register or EMPTY) do
						register(reg[1], reg[2], reg[3])
					end
				elseif rec.at then
					placeInstance(ctx, rec, dest, 1, 1, rec.at[1], 0, rec.at[2], rec.at[3] or 0, nil)
					if rec.r then
						register(rec.at[1], rec.at[2], rec.r)
					end
				else
					for i, e in ipairs(rec.fixed) do
						placeInstance(ctx, rec, dest, i, #rec.fixed, e.x, e.y or 0, e.z, e.yaw or 0, e)
						if rec.r then
							register(e.x, e.z, rec.r)
						end
					end
				end
			end
		end

		for ri, rec in ipairs(recipes) do
			if not isFixedRecipe(rec) then
				local rng = makeRng(a.index * 100 + ri)
				positions[ri] = {}
				if rec.follow then
					local source = positions[rec.follow] or EMPTY
					for i, pos in ipairs(source) do
						local yaw = rng.number(0, 360)
						placeInstance(ctx, rec, props, i, #source, pos.x + rec.offset[1], rec.offset[2], pos.z + rec.offset[3], yaw, nil)
					end
				else
					local band = rec.band or DEFAULT_BAND
					for i = 1, rec.count do
						local done = false
						local try = 0
						while (not done) and try < SCATTER_TRIES * 2 do
							try = try + 1
							local relaxed = try > SCATTER_TRIES
							local x = rng.number(a.startX + 14, a.endX - 14)
							local y, z, side = 0, 0, nil
							if rec.zRange then
								z = rng.number(rec.zRange[1], rec.zRange[2])
							else
								side = (rng.integer(0, 1) == 0) and -1 or 1
								if rec.zFixed then
									z = side * rec.zFixed
								else
									z = side * rng.number(band[1], band[2])
								end
							end
							if rec.sky then
								y = rng.number(rec.sky[1], rec.sky[2])
							end
							local blocked = false
							if side and (not rec.ignoreHerd) and side == a.herdSide and math.abs(x - a.herdX) < 48 then
								blocked = true
							end
							if (not blocked) and rec.r and tooClose(x, z, rec.r, relaxed) then
								blocked = true
							end
							if not blocked then
								local yaw = rec.fixedYaw or rng.number(0, 360)
								placeInstance(ctx, rec, props, i, rec.count, x, y, z, yaw, nil)
								if rec.r then
									register(x, z, rec.r)
								end
								table.insert(positions[ri], { x = x, z = z })
								done = true
							end
						end
						if not done then
							ctx.skipped = ctx.skipped + 1
							table.insert(ctx.skippedNames, a.id .. "/" .. rec.name)
						end
					end
				end
			end
		end
	end

	----------------------------------------------------------------------------------------------
	-- Areas (MAP_SPEC sections 6.3 and 6.4)
	----------------------------------------------------------------------------------------------

	local function areaAttributes(a)
		return { AreaIndex = a.index, AreaId = a.id, AreaName = a.name, SpeedRequired = a.speedRequired }
	end

	local function withAreaAttributes(a, extra)
		local attrs = areaAttributes(a)
		for key, value in pairs(extra or EMPTY) do
			attrs[key] = value
		end
		return attrs
	end

	-- The 8 herd points, SpawnIndex order (section 6.4 "authoritative formula").
	function MapBuilder.herdPoints(a)
		local pts = {}
		local s, side = a.herdSpacing, a.herdSide
		for patchIndex, patch in ipairs({ -1, 1 }) do
			local px = a.herdX + patch * (s + 4)
			for _, zr in ipairs({ 28 - s / 2, 28 + s / 2 }) do
				for _, dx in ipairs({ -s / 2, s / 2 }) do
					table.insert(pts, { x = px + dx, y = 0.5, z = side * zr, patch = patchIndex })
				end
			end
		end
		return pts
	end

	local function themeSpec(shape, dims, pos, part, opts)
		opts = opts or {}
		if part.transparency and opts.t == nil then
			opts.t = part.transparency
		end
		return { shape, dims, pos, part.material, part.color, opts }
	end

	local function buildArea(ctx, cfg, areasFolder, a)
		local I = CFrame.new()
		local S, E = a.startX, a.endX
		local L = E - S
		local C = (S + E) / 2
		local H = a.cliffHeight
		local sigma = a.herdSide
		local s = a.herdSpacing
		local th = a.theme
		local font = a.font or "GothamBlack"
		local signText = th.signText or CREAM
		local halfWidth = cfg.Town.LaneHalfWidth

		local area = Instance.new("Model")
		area.Name = string.format("Area%02d_%s", a.index, a.id)

		-- Ground
		local ground = newFolder("Ground", area)
		buildParts(ctx, ground, I, {
			themeSpec("Block", { L, 4, 40 }, { C, -2, 0 }, th.trail, { name = "TrailStrip" }),
			themeSpec("Block", { L, 4, 44 }, { C, -2, 42 }, th.shoulder, { name = "ShoulderN" }),
			themeSpec("Block", { L, 4, 44 }, { C, -2, -42 }, th.shoulder, { name = "ShoulderS" }),
		})

		-- Cliffs (inner face at Z +-64)
		local cliffs = newFolder("Cliffs", area)
		buildParts(ctx, cliffs, I, {
			themeSpec("Block", { L, H, 12 }, { C, H / 2, halfWidth + 6 }, th.wall, { name = "WallN" }),
			themeSpec("Block", { L, H, 12 }, { C, H / 2, -(halfWidth + 6) }, th.wall, { name = "WallS" }),
			themeSpec("Block", { 0.4 * L, 0.5 * H, 10 }, { S + 0.3 * L, 1.25 * H, 71 }, th.crest, { name = "CrestN" }),
			themeSpec("Block", { 0.4 * L, 0.5 * H, 10 }, { S + 0.7 * L, 1.25 * H, -71 }, th.crest, { name = "CrestS" }),
			themeSpec("Wedge", { L, 0.4 * H, 6 }, { C, 0.2 * H, 61 }, th.toe, { name = "ToeN" }),
			themeSpec("Wedge", { L, 0.4 * H, 6 }, { C, 0.2 * H, -61 }, th.toe, { name = "ToeS", rotY = 180 }),
		})

		-- Entrance arch with the Speed sign (a soft gate: no barrier)
		local entranceSpecs = {
			themeSpec("VCyl", { 26, 4 }, { S, 13, 30 }, th.archPost, { name = "PostN" }),
			themeSpec("VCyl", { 26, 4 }, { S, 13, -30 }, th.archPost, { name = "PostS" }),
			themeSpec("Ball", { 5 }, { S, 38.5, 30 }, th.archCap, { name = "CapN" }),
			themeSpec("Ball", { 5 }, { S, 38.5, -30 }, th.archCap, { name = "CapS" }),
			themeSpec("Block", { 1.5, 10, 68 }, { S, 31, 0 }, th.archBoard, { name = "SignBoard", tags = { "AreaSign" },
				attrs = areaAttributes(a), gui = {
					{ face = "Left", lines = { string.upper(a.name), a.sign }, font = font, color = signText },
					{ face = "Right", lines = { "\u{2190} TOWN" }, font = font, color = signText, rows = { { 0.15, 0.7 } } },
				} }),
			{ "Block", { 2, 60, 128 }, { S, 30, 0 }, nil, nil, { name = "EntranceTrigger", invisible = true, query = true,
				tags = { "AreaEntrance" }, attrs = areaAttributes(a) } },
		}
		for _, extra in ipairs(ENTRANCE_EXTRAS[a.id] or EMPTY) do
			local pos = extra[3]
			table.insert(entranceSpecs, { extra[1], extra[2], { S + pos[1], pos[2], pos[3] }, extra[4], extra[5], extra[6] })
		end
		buildModel(ctx, "Entrance", area, I, entranceSpecs, { primary = "SignBoard" })

		-- Bounds
		local bounds = newPart(ctx, { "Block", { L, 120, 128 }, { C, 60, 0 }, nil, nil, { name = "Bounds", invisible = true, query = true,
			tags = { "AreaBounds" }, attrs = areaAttributes(a) } }, I, area)

		-- Herd: zone, 8 spawn points in 2 patches, the sleeping Alpha and its Speed sign
		local herd = newFolder("Herd", area)
		local alphaZ = sigma * (42 + s / 2)
		local trailYaw = (sigma == 1) and 0 or 180
		newPart(ctx, themeSpec("Block", { 2 * (s + 4) + s + 10, 0.2, s + 10 }, { a.herdX, 0, 28 * sigma }, th.herdZone,
			{ name = "HerdZone", nc = true, tags = { "HerdZone" }, attrs = areaAttributes(a) }), I, herd)
		for i, pt in ipairs(MapBuilder.herdPoints(a)) do
			newPart(ctx, { "Block", { 2, 1, 2 }, { pt.x, pt.y, pt.z }, nil, nil, { name = string.format("HerdSpawn%02d", i),
				invisible = true, rotY = trailYaw, tags = { "HerdSpawn" },
				attrs = withAreaAttributes(a, { SpawnIndex = i, PatchIndex = pt.patch, Occupied = false }) } }, I, herd)
		end
		newPart(ctx, { "Block", { 8, 1, 8 }, { a.herdX, 0.5, alphaZ }, nil, nil, { name = "AlphaSpawn", invisible = true,
			rotY = trailYaw, tags = { "AlphaSpawn" },
			attrs = withAreaAttributes(a, { AlphaId = a.alpha.id, LeashX = cfg.Town.GateX }) } }, I, herd)
		newPart(ctx, themeSpec("VCyl", { 0.3, a.alphaBedDiameter }, { a.herdX, 0.05, alphaZ }, th.alphaBed,
			{ name = "AlphaBed", nc = true }), I, herd)
		buildModel(ctx, "HerdSign", herd, I, {
			themeSpec("VCyl", { 8, 1 }, { a.herdX + 18, 4, alphaZ }, th.archPost, { name = "Post" }),
			themeSpec("Block", { 8, 3.5, 0.5 }, { a.herdX + 18, 9, alphaZ }, th.archBoard, { name = "Board", gui = {
				{ face = (sigma == 1) and "Front" or "Back", lines = { string.upper(a.alpha.name), a.sign }, font = font,
					color = signText, pps = 40 },
			} }),
		}, { primary = "Board", tags = { "HerdSign" }, attrs = areaAttributes(a) })

		-- Landmarks and props
		buildAreaProps(ctx, a, area)

		area.PrimaryPart = bounds
		setAttributes(area, withAreaAttributes(a, { StartX = S, EndX = E, HerdX = a.herdX, HerdSide = sigma, HerdSpacing = s }))
		setProfileAttributes(area, a.lighting)
		area.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		area.LevelOfDetail = Enum.ModelLevelOfDetail.StreamingMesh
		area.Parent = areasFolder
		ctx.models = ctx.models + 1
		return area
	end

	----------------------------------------------------------------------------------------------
	-- Lane (MAP_SPEC section 6.1)
	----------------------------------------------------------------------------------------------

	local function buildLane(ctx, cfg, map)
		local I = CFrame.new()
		local laneCfg = cfg.Lane
		local halfWidth = cfg.Town.LaneHalfWidth
		local lane = newFolder("Lane", map)

		local thStart, thEnd = laneCfg.TrailheadStartX, laneCfg.TrailheadEndX
		newPart(ctx, { "Block", { thEnd - thStart, 4, 2 * halfWidth }, { (thStart + thEnd) / 2, -2, 0 }, "Ground", { 176, 138, 96 },
			{ name = "Trailhead" } }, I, lane)

		-- Invisible lane walls at Z +-64..68, two pieces per side
		local boundaries = newFolder("Boundaries", lane)
		local mid = (thStart + laneCfg.FrontierEndX) / 2
		local half1 = mid - thStart
		local wallZ = halfWidth + 2
		local wallOpts = function(name)
			return { name = name, invisible = true, collide = true, tags = { "LaneBoundary" } }
		end
		buildParts(ctx, boundaries, I, {
			{ "Block", { half1, 200, 4 }, { thStart + half1 / 2, 100, wallZ }, nil, nil, wallOpts("LaneWall_N1") },
			{ "Block", { half1, 200, 4 }, { thStart + half1 / 2, 100, -wallZ }, nil, nil, wallOpts("LaneWall_S1") },
			{ "Block", { half1, 200, 4 }, { mid + half1 / 2, 100, wallZ }, nil, nil, wallOpts("LaneWall_N2") },
			{ "Block", { half1, 200, 4 }, { mid + half1 / 2, 100, -wallZ }, nil, nil, wallOpts("LaneWall_S2") },
		})

		-- Waypoints WP00..WP11 for Alpha steering and the Stampede route
		local waypoints = newFolder("Waypoints", lane)
		for k, x in ipairs(laneCfg.WaypointX) do
			newPart(ctx, { "Block", { 2, 1, 2 }, { x, 0.5, 0 }, nil, nil, { name = string.format("WP%02d", k - 1), invisible = true,
				tags = { "LaneWaypoint" }, attrs = { Order = k - 1 } } }, I, waypoints)
		end

		-- Frontier End: the barrier where new areas will attach
		local endStart, endX = laneCfg.AreasEndX, laneCfg.FrontierEndX
		local nextArea = cfg.Upcoming and cfg.Upcoming[1]
		local endLines = { "FRONTIER END" }
		if nextArea then
			endLines = { string.upper(nextArea.name), nextArea.sign, "COMING SATURDAY" }
		end
		buildModel(ctx, "FrontierEnd", lane, I, {
			{ "Block", { endX - endStart, 4, 2 * halfWidth }, { (endStart + endX) / 2, -2, 0 }, "Slate", { 40, 32, 60 }, { name = "Ground" } },
			{ "Block", { 2, 40, 2 * halfWidth }, { endX - 1, 20, 0 }, "ForceField", { 255, 150, 220 }, { name = "Barrier", t = 0.1 } },
			{ "Block", { 4, 200, 2 * halfWidth + 8 }, { endX + 2, 100, 0 }, nil, nil, { name = "Collider", invisible = true, collide = true } },
			{ "VCyl", { 26, 4 }, { endX - 20, 13, 30 }, "Glass", { 120, 90, 220 }, { name = "PostN" } },
			{ "VCyl", { 26, 4 }, { endX - 20, 13, -30 }, "Glass", { 120, 90, 220 }, { name = "PostS" } },
			{ "Block", { 1.5, 10, 68 }, { endX - 20, 31, 0 }, "SmoothPlastic", { 24, 18, 40 }, { name = "Board", gui = {
				{ face = "Left", lines = endLines, font = "GothamBlack", color = { 255, 200, 235 } },
			} } },
		}, { primary = "Ground", tags = { "FrontierEnd" } })

		-- Stampede markers: from the start of Ghost Town down to the trailhead
		newPart(ctx, { "Block", { 4, 1, 4 }, { laneCfg.StampedeStartX, 0.5, 0 }, nil, nil, { name = "StampedeStart", invisible = true } }, I, lane)
		newPart(ctx, { "Block", { 4, 1, 4 }, { laneCfg.StampedeEndX, 0.5, 0 }, nil, nil, { name = "StampedeEnd", invisible = true } }, I, lane)

		local areasFolder = newFolder("Areas", lane)
		for _, a in ipairs(cfg.Areas) do
			buildArea(ctx, cfg, areasFolder, a)
		end
		return lane
	end

	----------------------------------------------------------------------------------------------
	-- Place settings: Lighting (section 8) and streaming (section 9)
	----------------------------------------------------------------------------------------------

	local function applyLighting(cfg)
		local Lighting = game:GetService("Lighting")
		local base = cfg.Town.BaseLighting
		local profile = cfg.Town.Lighting
		pcall(function()
			Lighting.ClockTime = base.ClockTime
			Lighting.Brightness = base.Brightness
			Lighting.Ambient = color(base.Ambient)
			Lighting.OutdoorAmbient = color(base.OutdoorAmbient)
		end)
		pcall(function()
			Lighting.Technology = Enum.Technology.ShadowMap
		end)

		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if not atmosphere then
			atmosphere = Instance.new("Atmosphere")
		end
		atmosphere.Density = profile.AtmDensity
		atmosphere.Haze = profile.AtmHaze
		atmosphere.Color = color(profile.AtmColor)
		atmosphere.Decay = color(profile.AtmDecay)
		atmosphere.Glare = profile.AtmGlare
		atmosphere.Parent = Lighting

		local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
		if not bloom then
			bloom = Instance.new("BloomEffect")
		end
		bloom.Intensity = base.BloomIntensity
		bloom.Parent = Lighting

		-- The client AreaLightingController tweens this one between area profiles.
		local cc = Lighting:FindFirstChild("AreaColorCorrection")
		if not (cc and cc:IsA("ColorCorrectionEffect")) then
			cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "AreaColorCorrection"
		end
		cc.TintColor = color(profile.CCTint)
		cc.Saturation = profile.CCSaturation
		cc.Contrast = profile.CCContrast
		cc.Brightness = profile.CCBrightness
		cc.Parent = Lighting
	end

	local function applyStreaming(cfg)
		local ok = pcall(function()
			local ws = game:GetService("Workspace")
			ws.StreamingEnabled = true
			ws.StreamingMinRadius = cfg.Town.Streaming.MinRadius
			ws.StreamingTargetRadius = cfg.Town.Streaming.TargetRadius
		end)
		if not ok then
			warn("[MapBuilder] Could not change Workspace streaming from here. Set StreamingEnabled = true, "
				.. "StreamingMinRadius = 256 and StreamingTargetRadius = 1024 in Workspace's Properties.")
		end
	end

	-- A new Studio "Baseplate" place has a 2048-wide Baseplate whose top is also at Y = 0 (it would
	-- flicker against the map's ground) and a second SpawnLocation. Remove just those two.
	local function removeTemplateParts(ws)
		local removed = {}
		local baseplate = ws:FindFirstChild("Baseplate")
		if baseplate and baseplate:IsA("BasePart") then
			baseplate:Destroy()
			table.insert(removed, "Baseplate")
		end
		local spawn = ws:FindFirstChild("SpawnLocation")
		if spawn and spawn:IsA("SpawnLocation") then
			spawn:Destroy()
			table.insert(removed, "SpawnLocation")
		end
		return removed
	end

	local function loadDefaultConfig()
		local replicated = game:GetService("ReplicatedStorage")
		local shared = replicated:FindFirstChild("Shared")
		local module = shared and shared:FindFirstChild("AreasConfig")
		if not module then
			error("[MapBuilder] build(config): pass the AreasConfig table, or sync ReplicatedStorage.Shared.AreasConfig with Rojo first")
		end
		return require(module)
	end

	----------------------------------------------------------------------------------------------
	-- Public API
	----------------------------------------------------------------------------------------------

	-- Deletes workspace.Map (every copy, if there are several).
	function MapBuilder.clear()
		local ws = game:GetService("Workspace")
		local old = ws:FindFirstChild("Map")
		while old do
			old:Destroy()
			old = ws:FindFirstChild("Map")
		end
	end

	----------------------------------------------------------------------------------------------
	-- Steal An Egg look (AreasConfig.Style): bright Plastic ground and walls with Studs surfaces
	-- and, once the texture is uploaded, a two-tone checkerboard Texture on the faces you see.
	----------------------------------------------------------------------------------------------
	local SIDE_FACES = { "Front", "Back", "Left", "Right" }
	local ALL_SURFACES = { "TopSurface", "BottomSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }

	local function rgbToHsv(c)
		local r, g, b = c[1] / 255, c[2] / 255, c[3] / 255
		local maxc, minc = math.max(r, g, b), math.min(r, g, b)
		local d = maxc - minc
		local h = 0
		if d > 0 then
			if maxc == r then
				h = ((g - b) / d) % 6
			elseif maxc == g then
				h = (b - r) / d + 2
			else
				h = (r - g) / d + 4
			end
			h = h / 6
		end
		local sat = (maxc > 0) and d / maxc or 0
		return h, sat, maxc
	end

	local function hsvToRgb(h, sat, v)
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p, q, t = v * (1 - sat), v * (1 - f * sat), v * (1 - (1 - f) * sat)
		local k = i % 6
		local r, g, b
		if k == 0 then r, g, b = v, t, p
		elseif k == 1 then r, g, b = q, v, p
		elseif k == 2 then r, g, b = p, v, t
		elseif k == 3 then r, g, b = p, q, v
		elseif k == 4 then r, g, b = t, p, v
		else r, g, b = v, p, q end
		return { math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5) }
	end

	-- A theme colour made brighter and more saturated (cartoon look)
	function MapBuilder.vivid(c, style)
		local h, sat, v = rgbToHsv(c)
		return hsvToRgb(h, math.min(1, sat * style.Saturation), math.min(1, v * style.Brightness))
	end

	-- faces = list of NormalId names that get the checker texture
	local function studify(part, rgb, faces, style, allSides)
		if not part then
			return 0
		end
		part.Material = Enum.Material.Plastic
		part.Color = color(rgb)
		if allSides then
			for _, surface in ipairs(ALL_SURFACES) do
				part[surface] = Enum.SurfaceType.Studs
			end
		else
			part.TopSurface = Enum.SurfaceType.Studs
		end
		local added = 0
		if style.CheckerTexture ~= "" then
			local tile = 2 * style.TileStuds
			for _, face in ipairs(faces) do
				local texture = Instance.new("Texture")
				texture.Name = "Checker" .. face
				texture.Texture = style.CheckerTexture
				texture.Face = Enum.NormalId[face]
				texture.StudsPerTileU = tile
				texture.StudsPerTileV = tile
				texture.Color3 = color(style.CheckerColor or { 0, 0, 0 })
				texture.Transparency = style.CheckerTransparency or 0
				texture.Parent = part
				added = added + 1
			end
		end
		return added
	end

	local function child(parent, ...)
		local node = parent
		for _, name in ipairs({ ... }) do
			node = node and node:FindFirstChild(name)
		end
		return node
	end

	-- Returns the number of parts restyled and textures added.
	function MapBuilder.applyStyle(map, config)
		local style = config.Style
		if not style or style.Enabled == false then
			return 0, 0
		end
		-- A texture id set on the place wins, so nobody has to edit this repo to swap the tile:
		--   workspace:SetAttribute("CheckerTexture", "rbxassetid://123")   then rebuild the map
		-- (CheckerTransparency on the place, default 0, goes with it.)
		local ws = game:GetService("Workspace")
		local fromPlace = ws:GetAttribute("CheckerTexture")
		if type(fromPlace) == "string" and fromPlace ~= "" then
			local copy = {}
			for k, v in pairs(style) do
				copy[k] = v
			end
			copy.CheckerTexture = fromPlace
			copy.CheckerTransparency = tonumber(ws:GetAttribute("CheckerTransparency")) or 0
			copy.CheckerColor = { 255, 255, 255 } -- our own tile carries its colours (white stud highlights)
			style = copy
		end
		local parts, textures = 0, 0
		local function apply(part, rgb, faces, allSides)
			if part then
				parts = parts + 1
				textures = textures + studify(part, rgb, faces, style, allSides)
			end
		end
		local TOP = { "Top" }
		local WALL = { "Top", "Front", "Back", "Left", "Right" }

		local town = map:FindFirstChild("Town")
		local ground = child(town, "Ground")
		apply(child(ground, "SquareGround"), style.Town.grass, TOP)
		apply(child(ground, "RanchGroundN"), style.Town.grass, TOP)
		apply(child(ground, "RanchGroundS"), style.Town.grass, TOP)
		apply(child(ground, "MainStreet"), style.Town.path, TOP)
		apply(child(ground, "BoardwalkN"), style.Town.path, TOP)
		apply(child(ground, "BoardwalkS"), style.Town.path, TOP)
		local fence = child(town, "Fence")
		for _, name in ipairs({ "Palisade_N", "Palisade_S", "Palisade_W", "Palisade_EN", "Palisade_ES" }) do
			apply(child(fence, name), style.Town.wall, WALL, true)
		end

		for _, plot in ipairs(child(map, "Plots") and map.Plots:GetChildren() or {}) do
			apply(plot:FindFirstChild("PlotBase"), style.Town.plot, TOP)
		end

		local lane = map:FindFirstChild("Lane")
		apply(child(lane, "Trailhead"), style.Town.path, TOP)
		for _, a in ipairs(config.Areas) do
			local area = child(lane, "Areas", string.format("Area%02d_%s", a.index, a.id))
			if area then
				local override = (style.AreaOverrides and style.AreaOverrides[a.index]) or {}
				local function pick(key)
					return override[key] or MapBuilder.vivid(a.theme[key].color, style)
				end
				apply(child(area, "Ground", "TrailStrip"), pick("trail"), TOP)
				apply(child(area, "Ground", "ShoulderN"), pick("shoulder"), TOP)
				apply(child(area, "Ground", "ShoulderS"), pick("shoulder"), TOP)
				apply(child(area, "Cliffs", "WallN"), pick("wall"), WALL, true)
				apply(child(area, "Cliffs", "WallS"), pick("wall"), WALL, true)
				apply(child(area, "Cliffs", "CrestN"), pick("crest"), WALL, true)
				apply(child(area, "Cliffs", "CrestS"), pick("crest"), WALL, true)
				-- the wedge toes keep their slope, so they only get studs and colour
				apply(child(area, "Cliffs", "ToeN"), pick("toe"), {}, true)
				apply(child(area, "Cliffs", "ToeS"), pick("toe"), {}, true)
			end
		end
		return parts, textures
	end

	--[[
		MapBuilder.build(config, options) -> report
		config  = the AreasConfig table (loaded from ReplicatedStorage.Shared if omitted)
		options = { lighting = true, streaming = true, removeTemplateBaseplate = true }
		report  = { parts =, models =, areas =, plots =, skippedProps =, seconds =, removed = {...} }
	]]
	function MapBuilder.build(config, options)
		config = config or loadDefaultConfig()
		options = options or EMPTY
		local started = os.clock()
		local ws = game:GetService("Workspace")

		local ctx = {
			parts = 0,
			models = 0,
			skipped = 0,
			skippedNames = {},
			cs = game:GetService("CollectionService"),
		}

		MapBuilder.clear()
		local removed = {}
		if options.removeTemplateBaseplate ~= false then
			removed = removeTemplateParts(ws)
		end
		ctx.groupsOk = registerCollisionGroups(config.Plots.Count)

		-- Built unparented, then parented once at the end.
		local map = Instance.new("Folder")
		map.Name = "Map"
		setAttributes(map, {
			MapVersion = config.Town.MapVersion,
			TownGateX = config.Town.GateX,
			LaneHalfWidth = config.Town.LaneHalfWidth,
			TrailHalfWidth = config.Town.TrailHalfWidth,
		})

		buildTown(ctx, config, map)
		local plotsFolder = newFolder("Plots", map)
		for _, p in ipairs(config.Plots.List) do
			buildPlot(ctx, config, plotsFolder, p)
		end
		buildLane(ctx, config, map)
		ctx.styledParts, ctx.textures = MapBuilder.applyStyle(map, config)
		map.Parent = ws

		if options.lighting ~= false then
			applyLighting(config)
		end
		if options.streaming ~= false then
			applyStreaming(config)
		end

		local report = {
			parts = ctx.parts,
			models = ctx.models,
			areas = #config.Areas,
			plots = #config.Plots.List,
			skippedProps = ctx.skipped,
			skippedNames = ctx.skippedNames,
			collisionGroups = ctx.groupsOk,
			removed = removed,
			styledParts = ctx.styledParts,
			textures = ctx.textures,
			seconds = os.clock() - started,
		}
		print(string.format("[MapBuilder] Built workspace.Map: %d parts, %d models, %d plots, %d areas in %.2f s.",
			report.parts, report.models, report.plots, report.areas, report.seconds))
		if config.Style and config.Style.Enabled ~= false then
			if ctx.textures > 0 then
				print(string.format("[MapBuilder] Studded checker look on %d parts (%d textures).", ctx.styledParts, ctx.textures))
			else
				print(string.format("[MapBuilder] Studs on %d parts (no checker texture: AreasConfig.Style.CheckerTexture is empty).",
					ctx.styledParts))
			end
		end
		if #removed > 0 then
			print("[MapBuilder] Removed the template " .. table.concat(removed, " and ") .. " from Workspace.")
		end
		if ctx.skipped > 0 then
			warn(string.format("[MapBuilder] %d scattered props found no free spot: %s", ctx.skipped, table.concat(ctx.skippedNames, ", ")))
		end
		return report
	end

	return MapBuilder
end)()

-- Build, recorded as one undo step when Studio allows it
local ChangeHistoryService = nil
pcall(function()
	ChangeHistoryService = game:GetService("ChangeHistoryService")
end)
local recording = nil
if ChangeHistoryService then
	pcall(function()
		recording = ChangeHistoryService:TryBeginRecording("Build Steal a Beast map")
	end)
end
local ok, result = pcall(MapBuilder.build, AreasConfig)
if ChangeHistoryService and recording then
	pcall(function()
		if ok then
			ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
		else
			ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)
		end
	end)
end
if not ok then
	error("[MapBuilder] Build failed: " .. tostring(result), 0)
end
return result
