--[[
	MapUtil: finds the built map (workspace.Map, made by tools/BuildMap.command.lua) and
	has the small helpers every service needs: the zone test from MAP_SPEC section 3.4,
	sign text and the runtime folders.
]]

local CollectionService = game:GetService("CollectionService")

local MapUtil = {}

function MapUtil.waitForMap()
	local map = workspace:FindFirstChild("Map")
	if not map then
		warn("[MapUtil] workspace.Map is missing. Build it first: paste game/tools/BuildMap.command.lua "
			.. "into the Studio Command Bar (see game/README.md), then save the place.")
		map = workspace:WaitForChild("Map")
	end
	return map
end

-- True when pos is inside the part's box (works for rotated parts). pad grows the box.
function MapUtil.inBox(part, pos, pad)
	local p = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	pad = pad or Vector3.new(0, 0, 0)
	return math.abs(p.X) <= h.X + pad.X and math.abs(p.Y) <= h.Y + pad.Y and math.abs(p.Z) <= h.Z + pad.Z
end

function MapUtil.inAnyTagged(tag, pos)
	for _, part in ipairs(CollectionService:GetTagged(tag)) do
		if part:IsA("BasePart") and MapUtil.inBox(part, pos) then
			return part
		end
	end
	return nil
end

-- Sets the text of Line1, Line2 ... in a SurfaceGui or BillboardGui built by MapBuilder.
function MapUtil.setLines(gui, lines)
	if not gui then
		return
	end
	for i, text in ipairs(lines) do
		local label = gui:FindFirstChild("Line" .. i)
		if label then
			label.Text = text
		end
	end
end

function MapUtil.runtimeFolder(name)
	local runtime = workspace:FindFirstChild("Runtime")
	if not runtime then
		runtime = Instance.new("Folder")
		runtime.Name = "Runtime"
		runtime.Parent = workspace
	end
	local folder = runtime:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = runtime
	end
	return folder
end

function MapUtil.rootPart(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function MapUtil.humanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

return MapUtil
