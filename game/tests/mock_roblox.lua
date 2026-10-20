--[[
	mock_roblox.lua: a small, strict imitation of the Roblox API for running map code under
	plain Lua 5.3 (fengari). It defines the globals game, workspace, Instance, Vector3, Vector2,
	CFrame, Color3, UDim2, UDim, Enum, NumberRange, NumberSequence, ColorSequence, warn and typeof.

	It is strict on purpose, so the tests catch mistakes Studio would also reject:
	  * Instance.new only accepts the classes listed below.
	  * Writing a property that the class does not have raises "X is not a valid member of Y".
	  * Property values are type-checked (a Color3 property only takes a Color3, and so on).
	  * Enum.<Type>.<Item> only accepts real item names for the enum types listed below.
	  * Reading a missing member (workspace.Map when there is no Map) raises an error, as in Roblox.
	  * SetAttribute checks the attribute name and the value type.
	  * CollectionService:GetTagged only returns instances that are still in the DataModel.
]]

local MOCK = {}

local function fail(message)
	error(message, 3)
end

----------------------------------------------------------------------------------------------
-- Vector3 / Vector2
----------------------------------------------------------------------------------------------
local V3 = {}
local Vector3 = {}

local function isV3(v)
	return getmetatable(v) == V3
end

function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end

V3.__index = function(v, key)
	if key == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif key == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return Vector3.new(v.X / m, v.Y / m, v.Z / m)
	elseif key == "Dot" then
		return function(a, b)
			return a.X * b.X + a.Y * b.Y + a.Z * b.Z
		end
	elseif key == "Cross" then
		return function(a, b)
			return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
		end
	end
	fail(tostring(key) .. " is not a valid member of Vector3")
end
V3.__add = function(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return Vector3.new(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return Vector3.new(a.X * b, a.Y * b, a.Z * b)
	end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then
		return Vector3.new(a.X / b, a.Y / b, a.Z / b)
	end
	return Vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__unm = function(a)
	return Vector3.new(-a.X, -a.Y, -a.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
V3.__tostring = function(v)
	return string.format("%g, %g, %g", v.X, v.Y, v.Z)
end

local V2 = {}
local Vector2 = {}
function Vector2.new(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, V2)
end

----------------------------------------------------------------------------------------------
-- CFrame (position + 3x3 rotation matrix, column vectors, Roblox conventions)
----------------------------------------------------------------------------------------------
local CF = {}
local CFrame = {}

local function isCF(v)
	return getmetatable(v) == CF
end

local function makeCF(x, y, z, r)
	return setmetatable({ _x = x, _y = y, _z = z, _r = r }, CF)
end

local IDENTITY_R = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }

local function matmul(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			r[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return r
end

local function rotX(t)
	local c, s = math.cos(t), math.sin(t)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end
local function rotY(t)
	local c, s = math.cos(t), math.sin(t)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rotZ(t)
	local c, s = math.cos(t), math.sin(t)
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end

function CFrame.new(a, b, c, ...)
	if a == nil then
		return makeCF(0, 0, 0, IDENTITY_R)
	end
	if isV3(a) then
		return makeCF(a.X, a.Y, a.Z, IDENTITY_R)
	end
	local rest = { ... }
	if #rest == 9 then
		return makeCF(a, b, c, rest)
	end
	if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" then
		fail("CFrame.new: expected numbers")
	end
	return makeCF(a, b, c, IDENTITY_R)
end

function CFrame.Angles(rx, ry, rz)
	return makeCF(0, 0, 0, matmul(matmul(rotX(rx or 0), rotY(ry or 0)), rotZ(rz or 0)))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles

function CFrame.fromEulerAnglesYXZ(rx, ry, rz)
	return makeCF(0, 0, 0, matmul(matmul(rotY(ry or 0), rotX(rx or 0)), rotZ(rz or 0)))
end
CFrame.fromOrientation = CFrame.fromEulerAnglesYXZ

local function cfApply(cf, v)
	local r = cf._r
	return Vector3.new(
		cf._x + r[1] * v.X + r[2] * v.Y + r[3] * v.Z,
		cf._y + r[4] * v.X + r[5] * v.Y + r[6] * v.Z,
		cf._z + r[7] * v.X + r[8] * v.Y + r[9] * v.Z)
end

local function cfRotate(cf, v)
	local r = cf._r
	return Vector3.new(r[1] * v.X + r[2] * v.Y + r[3] * v.Z, r[4] * v.X + r[5] * v.Y + r[6] * v.Z, r[7] * v.X + r[8] * v.Y + r[9] * v.Z)
end

local function cfInverse(cf)
	local r = cf._r
	local t = { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
	local p = Vector3.new(cf._x, cf._y, cf._z)
	local inv = makeCF(0, 0, 0, t)
	local q = cfRotate(inv, p)
	return makeCF(-q.X, -q.Y, -q.Z, t)
end

local function cfCompose(a, b)
	local p = cfApply(a, Vector3.new(b._x, b._y, b._z))
	return makeCF(p.X, p.Y, p.Z, matmul(a._r, b._r))
end

local CF_METHODS = {
	Inverse = function(self)
		return cfInverse(self)
	end,
	PointToObjectSpace = function(self, v)
		return cfApply(cfInverse(self), v)
	end,
	PointToWorldSpace = function(self, v)
		return cfApply(self, v)
	end,
	VectorToWorldSpace = function(self, v)
		return cfRotate(self, v)
	end,
	VectorToObjectSpace = function(self, v)
		return cfRotate(cfInverse(self), v)
	end,
	ToWorldSpace = function(self, other)
		return cfCompose(self, other)
	end,
	ToObjectSpace = function(self, other)
		return cfCompose(cfInverse(self), other)
	end,
	GetComponents = function(self)
		local r = self._r
		return self._x, self._y, self._z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]
	end,
}

CF.__index = function(cf, key)
	if key == "Position" or key == "p" then
		return Vector3.new(cf._x, cf._y, cf._z)
	elseif key == "X" then
		return cf._x
	elseif key == "Y" then
		return cf._y
	elseif key == "Z" then
		return cf._z
	elseif key == "RightVector" or key == "XVector" then
		return Vector3.new(cf._r[1], cf._r[4], cf._r[7])
	elseif key == "UpVector" or key == "YVector" then
		return Vector3.new(cf._r[2], cf._r[5], cf._r[8])
	elseif key == "ZVector" then
		return Vector3.new(cf._r[3], cf._r[6], cf._r[9])
	elseif key == "LookVector" then
		return Vector3.new(-cf._r[3], -cf._r[6], -cf._r[9])
	elseif key == "Rotation" then
		return makeCF(0, 0, 0, cf._r)
	elseif CF_METHODS[key] then
		return CF_METHODS[key]
	end
	fail(tostring(key) .. " is not a valid member of CFrame")
end
CF.__mul = function(a, b)
	if isCF(b) then
		return cfCompose(a, b)
	elseif isV3(b) then
		return cfApply(a, b)
	end
	fail("CFrame * expects a CFrame or a Vector3")
end
CF.__add = function(a, v)
	return makeCF(a._x + v.X, a._y + v.Y, a._z + v.Z, a._r)
end
CF.__sub = function(a, v)
	return makeCF(a._x - v.X, a._y - v.Y, a._z - v.Z, a._r)
end
CF.__tostring = function(cf)
	return string.format("CFrame(%g, %g, %g)", cf._x, cf._y, cf._z)
end

----------------------------------------------------------------------------------------------
-- Color3, UDim, UDim2, NumberRange, NumberSequence, ColorSequence
----------------------------------------------------------------------------------------------
local C3 = {}
local Color3 = {}
C3.__eq = function(a, b)
	return a.R == b.R and a.G == b.G and a.B == b.B
end
C3.__tostring = function(c)
	return string.format("%g, %g, %g", c.R, c.G, c.B)
end
C3.__index = function(_, key)
	fail(tostring(key) .. " is not a valid member of Color3")
end

function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end

function Color3.fromRGB(r, g, b)
	for _, v in ipairs({ r, g, b }) do
		if type(v) ~= "number" then
			fail("Color3.fromRGB expects 3 numbers")
		end
		if v < 0 or v > 255 then
			fail("Color3.fromRGB value out of range: " .. tostring(v))
		end
	end
	return setmetatable({ R = r / 255, G = g / 255, B = b / 255 }, C3)
end

local UD = {}
local UDim = {}
function UDim.new(scale, offset)
	return setmetatable({ Scale = scale or 0, Offset = offset or 0 }, UD)
end

local UD2 = {}
local UDim2 = {}
function UDim2.new(xs, xo, ys, yo)
	return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, UD2)
end
function UDim2.fromScale(xs, ys)
	return UDim2.new(xs, 0, ys, 0)
end
function UDim2.fromOffset(xo, yo)
	return UDim2.new(0, xo, 0, yo)
end

local NR = {}
local NumberRange = {}
function NumberRange.new(lo, hi)
	return setmetatable({ Min = lo, Max = hi or lo }, NR)
end

local NS = {}
local NumberSequence = {}
function NumberSequence.new(a, b)
	if type(a) == "table" then
		return setmetatable({ Keypoints = a }, NS)
	end
	return setmetatable({ Keypoints = { { Time = 0, Value = a }, { Time = 1, Value = b or a } } }, NS)
end

local CS = {}
local ColorSequence = {}
function ColorSequence.new(a, b)
	if getmetatable(a) ~= C3 then
		fail("ColorSequence.new expects a Color3")
	end
	return setmetatable({ Keypoints = { { Time = 0, Value = a }, { Time = 1, Value = b or a } } }, CS)
end

----------------------------------------------------------------------------------------------
-- Enum (only real item names)
----------------------------------------------------------------------------------------------
local ENUM_ITEMS = {
	Material = { "Plastic", "SmoothPlastic", "Neon", "Wood", "WoodPlanks", "Marble", "Basalt", "Slate", "CrackedLava",
		"Concrete", "Limestone", "Granite", "Pavement", "Brick", "Pebble", "Cobblestone", "Rock", "Sandstone",
		"CorrodedMetal", "DiamondPlate", "Foil", "Metal", "Grass", "LeafyGrass", "Sand", "Fabric", "Snow", "Mud",
		"Ground", "Asphalt", "Salt", "Ice", "Glacier", "Glass", "ForceField", "Air", "Water", "Cardboard", "Carpet",
		"CeramicTiles", "ClayRoofTiles", "RoofShingles", "Leather", "Plaster", "Rubber" },
	PartType = { "Ball", "Block", "Cylinder", "Wedge", "CornerWedge" },
	SurfaceType = { "Smooth", "Glue", "Weld", "Studs", "Inlet", "Universal", "Hinge", "Motor", "SteppingMotor", "SmoothNoOutlines" },
	NormalId = { "Right", "Top", "Back", "Left", "Bottom", "Front" },
	Font = { "Legacy", "Arial", "ArialBold", "SourceSans", "SourceSansBold", "SourceSansSemibold", "SourceSansLight",
		"SourceSansItalic", "Bodoni", "Garamond", "Cartoon", "Code", "Highway", "SciFi", "Arcade", "Fantasy", "Antique",
		"Gotham", "GothamMedium", "GothamBold", "GothamBlack", "AmaticSC", "Bangers", "Creepster", "DenkOne",
		"Fondamento", "FredokaOne", "GrenzeGotisch", "IndieFlower", "JosefinSans", "Jura", "Kalam", "LuckiestGuy",
		"Merriweather", "Michroma", "Nunito", "Oswald", "PatrickHand", "PermanentMarker", "Roboto", "RobotoCondensed",
		"RobotoMono", "Sarpanch", "SpecialElite", "TitilliumWeb", "Ubuntu", "BuilderSans", "BuilderSansMedium",
		"BuilderSansBold", "BuilderSansExtraBold", "Arimo", "ArimoBold", "Unknown" },
	SurfaceGuiSizingMode = { "FixedSize", "PixelsPerStud" },
	ModelStreamingMode = { "Default", "Atomic", "Persistent", "PersistentPerPlayer", "Nonatomic" },
	ModelLevelOfDetail = { "Automatic", "StreamingMesh", "Disabled" },
	Technology = { "Legacy", "Voxel", "Compatibility", "ShadowMap", "Future", "Unified" },
	FinishRecordingOperation = { "Cancel", "Commit", "Append" },
	TextXAlignment = { "Left", "Center", "Right" },
	TextYAlignment = { "Top", "Center", "Bottom" },
	ScaleType = { "Stretch", "Slice", "Tile", "Fit", "Crop" },
	ZIndexBehavior = { "Global", "Sibling" },
}

local EnumItemMT = {
	__tostring = function(item)
		return "Enum." .. item.EnumType .. "." .. item.Name
	end,
}
local enumTypes = {}
local Enum = setmetatable({}, {
	__index = function(_, typeName)
		local cached = enumTypes[typeName]
		if cached then
			return cached
		end
		local names = ENUM_ITEMS[typeName]
		if not names then
			fail(tostring(typeName) .. " is not a valid EnumType (mock: add it to ENUM_ITEMS if it is real)")
		end
		local items = {}
		for i, name in ipairs(names) do
			items[name] = setmetatable({ Name = name, Value = i - 1, EnumType = typeName }, EnumItemMT)
		end
		local enumType = setmetatable({}, {
			__index = function(_, itemName)
				local item = items[itemName]
				if not item then
					fail(tostring(itemName) .. " is not a valid member of Enum." .. typeName)
				end
				return item
			end,
		})
		enumTypes[typeName] = enumType
		return enumType
	end,
})

local function isEnumOf(v, typeName)
	return getmetatable(v) == EnumItemMT and v.EnumType == typeName
end

----------------------------------------------------------------------------------------------
-- typeof
----------------------------------------------------------------------------------------------
local INSTANCE_MT = {}

local function typeof(v)
	local mt = getmetatable(v)
	if mt == V3 then return "Vector3" end
	if mt == V2 then return "Vector2" end
	if mt == CF then return "CFrame" end
	if mt == C3 then return "Color3" end
	if mt == UD then return "UDim" end
	if mt == UD2 then return "UDim2" end
	if mt == NR then return "NumberRange" end
	if mt == NS then return "NumberSequence" end
	if mt == CS then return "ColorSequence" end
	if mt == EnumItemMT then return "EnumItem" end
	if mt == INSTANCE_MT then return "Instance" end
	return type(v)
end

----------------------------------------------------------------------------------------------
-- Classes: properties are { name = type } where type is a typeof() name, "Enum:<Type>",
-- "Instance", "BasePart" or "any".
----------------------------------------------------------------------------------------------
local CLASSES = {
	Instance = { props = { Name = "string", Archivable = "boolean" } },
	PVInstance = { super = "Instance", abstract = true, props = {} },
	BasePart = { super = "PVInstance", abstract = true, props = {
		Anchored = "boolean", CanCollide = "boolean", CanTouch = "boolean", CanQuery = "boolean", CastShadow = "boolean",
		Transparency = "number", Reflectance = "number", Color = "Color3", Material = "Enum:Material",
		Size = "Vector3", CFrame = "CFrame", Position = "Vector3", TopSurface = "Enum:SurfaceType",
		BottomSurface = "Enum:SurfaceType", FrontSurface = "Enum:SurfaceType", BackSurface = "Enum:SurfaceType",
		LeftSurface = "Enum:SurfaceType", RightSurface = "Enum:SurfaceType", CollisionGroup = "string", Locked = "boolean", Massless = "boolean",
		PivotOffset = "CFrame",
	}, defaults = { Anchored = false, CanCollide = true, CanTouch = true, CanQuery = true, CastShadow = true,
		Transparency = 0, Reflectance = 0, CollisionGroup = "Default", Locked = false, Massless = false } },
	Part = { super = "BasePart", props = { Shape = "Enum:PartType" } },
	WedgePart = { super = "BasePart", props = {} },
	SpawnLocation = { super = "Part", props = { Neutral = "boolean", Duration = "number", Enabled = "boolean",
		AllowTeamChangeOnTouch = "boolean" }, defaults = { Neutral = true, Duration = 10, Enabled = true } },
	Model = { super = "PVInstance", props = { PrimaryPart = "BasePart", ModelStreamingMode = "Enum:ModelStreamingMode",
		LevelOfDetail = "Enum:ModelLevelOfDetail", WorldPivot = "CFrame" } },
	Folder = { super = "Instance", props = {} },
	Decal = { super = "Instance", props = { Texture = "string", Face = "Enum:NormalId", Color3 = "Color3",
		Transparency = "number", ZIndex = "number" }, defaults = { Face = "Front", Transparency = 0 } },
	Texture = { super = "Decal", props = { StudsPerTileU = "number", StudsPerTileV = "number", OffsetStudsU = "number",
		OffsetStudsV = "number" }, defaults = { StudsPerTileU = 2, StudsPerTileV = 2 } },
	Attachment = { super = "Instance", props = { Position = "Vector3", CFrame = "CFrame", Visible = "boolean" } },
	Light = { super = "Instance", abstract = true, props = { Brightness = "number", Color = "Color3", Enabled = "boolean",
		Shadows = "boolean" }, defaults = { Brightness = 1, Enabled = true, Shadows = false } },
	PointLight = { super = "Light", props = { Range = "number" }, defaults = { Range = 8 } },
	Fire = { super = "Instance", props = { Size = "number", Heat = "number", Color = "Color3", SecondaryColor = "Color3",
		Enabled = "boolean", TimeScale = "number" } },
	ParticleEmitter = { super = "Instance", props = { Texture = "string", Rate = "number", Lifetime = "NumberRange",
		Speed = "NumberRange", Size = "NumberSequence", Transparency = "NumberSequence", Color = "ColorSequence",
		Rotation = "NumberRange", RotSpeed = "NumberRange", Acceleration = "Vector3", LightEmission = "number",
		LightInfluence = "number", Enabled = "boolean", SpreadAngle = "Vector2", Drag = "number", ZOffset = "number" } },
	GuiBase2d = { super = "Instance", abstract = true, props = {} },
	LayerCollector = { super = "GuiBase2d", abstract = true, props = { Enabled = "boolean", ResetOnSpawn = "boolean",
		ZIndexBehavior = "Enum:ZIndexBehavior" }, defaults = { Enabled = true } },
	SurfaceGui = { super = "LayerCollector", props = { Face = "Enum:NormalId", SizingMode = "Enum:SurfaceGuiSizingMode",
		PixelsPerStud = "number", CanvasSize = "Vector2", LightInfluence = "number", Brightness = "number",
		AlwaysOnTop = "boolean", ZOffset = "number", ClipsDescendants = "boolean", MaxDistance = "number",
		Adornee = "Instance" }, defaults = { Face = "Front" } },
	BillboardGui = { super = "LayerCollector", props = { Size = "UDim2", StudsOffset = "Vector3",
		StudsOffsetWorldSpace = "Vector3", ExtentsOffset = "Vector3", AlwaysOnTop = "boolean", MaxDistance = "number",
		LightInfluence = "number", Brightness = "number", ClipsDescendants = "boolean", Adornee = "Instance" } },
	GuiObject = { super = "GuiBase2d", abstract = true, props = { Size = "UDim2", Position = "UDim2", AnchorPoint = "Vector2",
		BackgroundTransparency = "number", BackgroundColor3 = "Color3", BorderSizePixel = "number", Visible = "boolean",
		ZIndex = "number", LayoutOrder = "number", Rotation = "number", ClipsDescendants = "boolean" },
		defaults = { Visible = true, BackgroundTransparency = 0 } },
	TextLabel = { super = "GuiObject", props = { Text = "string", TextColor3 = "Color3", TextScaled = "boolean",
		TextSize = "number", Font = "Enum:Font", TextStrokeTransparency = "number", TextStrokeColor3 = "Color3",
		TextWrapped = "boolean", TextXAlignment = "Enum:TextXAlignment", TextYAlignment = "Enum:TextYAlignment",
		TextTransparency = "number", RichText = "boolean", LineHeight = "number" },
		defaults = { Text = "Label", TextScaled = false, TextStrokeTransparency = 1, TextWrapped = false } },
	ImageLabel = { super = "GuiObject", props = { Image = "string", ImageColor3 = "Color3", ImageTransparency = "number",
		ScaleType = "Enum:ScaleType" } },
	Frame = { super = "GuiObject", props = {} },
	-- Lighting effects
	Atmosphere = { super = "Instance", props = { Density = "number", Offset = "number", Color = "Color3", Decay = "Color3",
		Glare = "number", Haze = "number" } },
	PostEffect = { super = "Instance", abstract = true, props = { Enabled = "boolean" }, defaults = { Enabled = true } },
	BloomEffect = { super = "PostEffect", props = { Intensity = "number", Size = "number", Threshold = "number" } },
	ColorCorrectionEffect = { super = "PostEffect", props = { TintColor = "Color3", Saturation = "number",
		Contrast = "number", Brightness = "number" } },
	-- Services
	DataModel = { super = "Instance", service = true, props = {} },
	Workspace = { super = "Model", service = true, props = { StreamingEnabled = "boolean", StreamingMinRadius = "number",
		StreamingTargetRadius = "number", Gravity = "number" } },
	Lighting = { super = "Instance", service = true, props = { ClockTime = "number", Brightness = "number",
		Ambient = "Color3", OutdoorAmbient = "Color3", Technology = "Enum:Technology", GlobalShadows = "boolean",
		ExposureCompensation = "number" } },
	CollectionService = { super = "Instance", service = true, props = {} },
	PhysicsService = { super = "Instance", service = true, props = {} },
	ReplicatedStorage = { super = "Instance", service = true, props = {} },
	ServerStorage = { super = "Instance", service = true, props = {} },
	ServerScriptService = { super = "Instance", service = true, props = {} },
}

local function classChain(className)
	local chain = {}
	local name = className
	while name do
		table.insert(chain, name)
		name = CLASSES[name].super
	end
	return chain
end

local function propType(className, key)
	local name = className
	while name do
		local cls = CLASSES[name]
		if cls.props and cls.props[key] then
			return cls.props[key]
		end
		name = cls.super
	end
	return nil
end

----------------------------------------------------------------------------------------------
-- Instances
----------------------------------------------------------------------------------------------
local DATA = setmetatable({}, { __mode = "k" })
local TAGS = {} -- tag -> ordered list of instances

local function dataOf(inst)
	return DATA[inst]
end

local function isA(inst, className)
	for _, name in ipairs(classChain(dataOf(inst).className)) do
		if name == className then
			return true
		end
	end
	return false
end

local function isInstance(v)
	return getmetatable(v) == INSTANCE_MT
end

local function fullName(inst)
	local parts = {}
	local cur = inst
	while cur and dataOf(cur).className ~= "DataModel" do
		table.insert(parts, 1, dataOf(cur).props.Name)
		cur = dataOf(cur).parent
	end
	return table.concat(parts, ".")
end

local function checkValue(className, key, expected, value)
	local actual = typeof(value)
	local ok
	if expected == "any" then
		ok = true
	elseif string.sub(expected, 1, 5) == "Enum:" then
		ok = isEnumOf(value, string.sub(expected, 6))
	elseif expected == "Instance" then
		ok = value == nil or isInstance(value)
	elseif expected == "BasePart" then
		ok = value == nil or (isInstance(value) and isA(value, "BasePart"))
	else
		ok = actual == expected
	end
	if not ok then
		fail(string.format("Unable to assign property %s. %s expected, got %s (%s)", key, expected, actual, className))
	end
end

local function isDescendantOf(inst, ancestor)
	local cur = dataOf(inst).parent
	while cur do
		if cur == ancestor then
			return true
		end
		cur = dataOf(cur).parent
	end
	return false
end

local function setParent(inst, newParent)
	local d = dataOf(inst)
	if d.destroyed then
		fail("The Parent property of " .. d.props.Name .. " is locked, current parent: NULL, new parent " .. tostring(newParent))
	end
	if newParent ~= nil and not isInstance(newParent) then
		fail("Parent must be an Instance")
	end
	if newParent == inst or (newParent and isDescendantOf(newParent, inst)) then
		fail("Attempt to set " .. d.props.Name .. " as its own parent")
	end
	local old = d.parent
	if old == newParent then
		return
	end
	if old then
		local siblings = dataOf(old).children
		for i, child in ipairs(siblings) do
			if child == inst then
				table.remove(siblings, i)
				break
			end
		end
	end
	d.parent = newParent
	if newParent then
		table.insert(dataOf(newParent).children, inst)
	end
end

local METHODS = {}

function METHODS.IsA(self, className)
	return isA(self, className)
end
function METHODS.GetChildren(self)
	local out = {}
	for i, child in ipairs(dataOf(self).children) do
		out[i] = child
	end
	return out
end
function METHODS.GetDescendants(self)
	local out = {}
	local function walk(inst)
		for _, child in ipairs(dataOf(inst).children) do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end
function METHODS.FindFirstChild(self, name, recursive)
	for _, child in ipairs(dataOf(self).children) do
		if dataOf(child).props.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in ipairs(dataOf(self).children) do
			local found = METHODS.FindFirstChild(child, name, true)
			if found then
				return found
			end
		end
	end
	return nil
end
function METHODS.WaitForChild(self, name)
	local found = METHODS.FindFirstChild(self, name)
	if not found then
		fail("Infinite yield possible on WaitForChild(\"" .. tostring(name) .. "\") (mock)")
	end
	return found
end
function METHODS.FindFirstChildOfClass(self, className)
	for _, child in ipairs(dataOf(self).children) do
		if dataOf(child).className == className then
			return child
		end
	end
	return nil
end
function METHODS.FindFirstChildWhichIsA(self, className)
	for _, child in ipairs(dataOf(self).children) do
		if isA(child, className) then
			return child
		end
	end
	return nil
end
function METHODS.FindFirstAncestorWhichIsA(self, className)
	local cur = dataOf(self).parent
	while cur do
		if isA(cur, className) then
			return cur
		end
		cur = dataOf(cur).parent
	end
	return nil
end
function METHODS.IsDescendantOf(self, ancestor)
	return isDescendantOf(self, ancestor)
end
function METHODS.IsAncestorOf(self, descendant)
	return isDescendantOf(descendant, self)
end
function METHODS.GetFullName(self)
	return fullName(self)
end
function METHODS.Destroy(self)
	local d = dataOf(self)
	for _, child in ipairs(METHODS.GetChildren(self)) do
		METHODS.Destroy(child)
	end
	if d.parent then
		setParent(self, nil)
	end
	d.destroyed = true
end
function METHODS.ClearAllChildren(self)
	for _, child in ipairs(METHODS.GetChildren(self)) do
		METHODS.Destroy(child)
	end
end
function METHODS.SetAttribute(self, name, value)
	if type(name) ~= "string" or not string.match(name, "^[%w_]+$") or #name > 100 then
		fail("SetAttribute: invalid attribute name " .. tostring(name))
	end
	local t = typeof(value)
	local allowed = { ["nil"] = true, boolean = true, number = true, string = true, Vector3 = true, Vector2 = true,
		CFrame = true, Color3 = true, UDim = true, UDim2 = true, NumberRange = true, NumberSequence = true, ColorSequence = true }
	if not allowed[t] then
		fail("SetAttribute: " .. t .. " is not a supported attribute type (" .. name .. ")")
	end
	dataOf(self).attrs[name] = value
end
function METHODS.GetAttribute(self, name)
	return dataOf(self).attrs[name]
end
function METHODS.GetAttributes(self)
	local out = {}
	for k, v in pairs(dataOf(self).attrs) do
		out[k] = v
	end
	return out
end
function METHODS.GetPivot(self)
	local d = dataOf(self)
	if isA(self, "BasePart") then
		return d.props.CFrame
	end
	if d.props.PrimaryPart then
		local pp = dataOf(d.props.PrimaryPart).props
		return pp.CFrame * (pp.PivotOffset or CFrame.new())
	end
	return CFrame.new()
end

local SERVICE_METHODS = {}

SERVICE_METHODS.DataModel = {
	GetService = function(self, name)
		local cls = CLASSES[name]
		if not cls or not cls.service or name == "DataModel" then
			fail("'" .. tostring(name) .. "' is not a valid Service name (mock)")
		end
		local existing = METHODS.FindFirstChildOfClass(self, name)
		if existing then
			return existing
		end
		local svc = MOCK.newService(name)
		setParent(svc, self)
		return svc
	end,
}

local function inGame(inst)
	local cur = inst
	while cur do
		local d = dataOf(cur)
		if d.className == "DataModel" then
			return true
		end
		cur = d.parent
	end
	return false
end

SERVICE_METHODS.CollectionService = {
	AddTag = function(_, inst, tag)
		if not isInstance(inst) or type(tag) ~= "string" then
			fail("AddTag(instance, string) expected")
		end
		local d = dataOf(inst)
		if d.tags[tag] then
			return
		end
		d.tags[tag] = true
		TAGS[tag] = TAGS[tag] or {}
		table.insert(TAGS[tag], inst)
	end,
	RemoveTag = function(_, inst, tag)
		dataOf(inst).tags[tag] = nil
	end,
	HasTag = function(_, inst, tag)
		return dataOf(inst).tags[tag] == true
	end,
	GetTags = function(_, inst)
		local out = {}
		for tag in pairs(dataOf(inst).tags) do
			table.insert(out, tag)
		end
		table.sort(out)
		return out
	end,
	GetTagged = function(_, tag)
		local out = {}
		for _, inst in ipairs(TAGS[tag] or {}) do
			local d = dataOf(inst)
			if d.tags[tag] and not d.destroyed and inGame(inst) then
				table.insert(out, inst)
			end
		end
		return out
	end,
}

local GROUPS = { Default = true }
local GROUP_ORDER = { "Default" }
local COLLIDE = {}
local function pairKey(a, b)
	if a < b then
		return a .. "|" .. b
	end
	return b .. "|" .. a
end

SERVICE_METHODS.PhysicsService = {
	RegisterCollisionGroup = function(_, name)
		if GROUPS[name] then
			fail("Collision group " .. name .. " already exists")
		end
		if #GROUP_ORDER >= 32 then
			fail("Collision group limit (32) reached")
		end
		GROUPS[name] = true
		table.insert(GROUP_ORDER, name)
	end,
	IsCollisionGroupRegistered = function(_, name)
		return GROUPS[name] == true
	end,
	CollisionGroupSetCollidable = function(_, a, b, collidable)
		if not GROUPS[a] or not GROUPS[b] then
			fail("CollisionGroupSetCollidable: unknown group " .. tostring(a) .. " / " .. tostring(b))
		end
		COLLIDE[pairKey(a, b)] = collidable
	end,
	CollisionGroupsAreCollidable = function(_, a, b)
		local v = COLLIDE[pairKey(a, b)]
		if v == nil then
			return true
		end
		return v
	end,
	GetRegisteredCollisionGroups = function()
		local out = {}
		for i, name in ipairs(GROUP_ORDER) do
			out[i] = { name = name }
		end
		return out
	end,
}

local function findMethod(className, key)
	local name = className
	while name do
		local sm = SERVICE_METHODS[name]
		if sm and sm[key] then
			return sm[key]
		end
		name = CLASSES[name].super
	end
	return METHODS[key]
end

INSTANCE_MT.__index = function(self, key)
	local d = dataOf(self)
	if key == "ClassName" then
		return d.className
	elseif key == "Parent" then
		return d.parent
	end
	local pt = propType(d.className, key)
	if pt then
		if key == "Position" and isA(self, "BasePart") then
			local cf = d.props.CFrame
			return cf and cf.Position or Vector3.new()
		end
		return d.props[key]
	end
	local method = findMethod(d.className, key)
	if method then
		return method
	end
	local child = METHODS.FindFirstChild(self, key)
	if child then
		return child
	end
	fail(tostring(key) .. " is not a valid member of " .. d.className .. " \"" .. fullName(self) .. "\"")
end

INSTANCE_MT.__newindex = function(self, key, value)
	local d = dataOf(self)
	if key == "Parent" then
		setParent(self, value)
		return
	end
	local pt = propType(d.className, key)
	if not pt then
		fail(tostring(key) .. " is not a valid member of " .. d.className .. " \"" .. fullName(self) .. "\"")
	end
	checkValue(d.className, key, pt, value)
	if isA(self, "BasePart") then
		if key == "Size" then
			if value.X <= 0 or value.Y <= 0 or value.Z <= 0 then
				fail("Part size must be positive: " .. tostring(value))
			end
		elseif key == "Position" then
			local r = d.props.CFrame and d.props.CFrame.Rotation or CFrame.new()
			d.props.CFrame = CFrame.new(value) * r
			return
		elseif key == "CollisionGroup" and not GROUPS[value] then
			fail("CollisionGroup '" .. value .. "' is not registered")
		end
	end
	if key == "PrimaryPart" and value ~= nil and not isDescendantOf(value, self) then
		fail("PrimaryPart must be a descendant of the Model")
	end
	d.props[key] = value
end

INSTANCE_MT.__tostring = function(self)
	return dataOf(self).props.Name
end

local function construct(className)
	local inst = setmetatable({}, INSTANCE_MT)
	DATA[inst] = { className = className, props = { Name = className }, children = {}, attrs = {}, tags = {},
		parent = nil, destroyed = false }
	-- defaults along the class chain (base first)
	local chain = classChain(className)
	for i = #chain, 1, -1 do
		local cls = CLASSES[chain[i]]
		for key, value in pairs(cls.defaults or {}) do
			local pt = propType(className, key)
			if pt and string.sub(pt, 1, 5) == "Enum:" and type(value) == "string" then
				value = Enum[string.sub(pt, 6)][value]
			end
			DATA[inst].props[key] = value
		end
	end
	if isA(inst, "BasePart") then
		DATA[inst].props.CFrame = CFrame.new()
		DATA[inst].props.Size = Vector3.new(4, 1, 2)
		DATA[inst].props.Color = Color3.fromRGB(163, 162, 165)
		DATA[inst].props.Material = Enum.Material.Plastic
		DATA[inst].props.TopSurface = Enum.SurfaceType.Studs
		DATA[inst].props.BottomSurface = Enum.SurfaceType.Inlet
		if CLASSES[className].props.Shape or className == "SpawnLocation" then
			DATA[inst].props.Shape = Enum.PartType.Block
		end
	end
	return inst
end

local Instance = {}
function Instance.new(className, parent)
	local cls = CLASSES[className]
	if not cls or cls.abstract or cls.service then
		fail("Unable to create an Instance of type \"" .. tostring(className) .. "\"")
	end
	local inst = construct(className)
	if parent then
		setParent(inst, parent)
	end
	return inst
end

function MOCK.newService(className)
	local svc = construct(className)
	DATA[svc].props.Name = className
	return svc
end

----------------------------------------------------------------------------------------------
-- The DataModel and globals
----------------------------------------------------------------------------------------------
local game = MOCK.newService("DataModel")
DATA[game].props.Name = "Game"
local workspace = SERVICE_METHODS.DataModel.GetService(game, "Workspace")

-- Test helpers (not part of the Roblox API)
MOCK.data = dataOf
MOCK.groups = GROUP_ORDER
MOCK.instanceCount = function()
	local n = 0
	for _ in pairs(DATA) do
		n = n + 1
	end
	return n
end

_G.game = game
_G.workspace = workspace
_G.Instance = Instance
_G.Vector3 = Vector3
_G.Vector2 = Vector2
_G.CFrame = CFrame
_G.Color3 = Color3
_G.UDim = UDim
_G.UDim2 = UDim2
_G.Enum = Enum
_G.NumberRange = NumberRange
_G.NumberSequence = NumberSequence
_G.ColorSequence = ColorSequence
_G.typeof = typeof
_G.warn = function(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring((select(i, ...)))
	end
	print("WARN: " .. table.concat(parts, " "))
end
_G.MOCK = MOCK

return MOCK
