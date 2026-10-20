--[[
	NameTagService: Steal An Egg's player tag, a round headshot with the username under it,
	floating over every player's head. It replaces Roblox's default name display.
]]

local Players = game:GetService("Players")

local NameTagService = {}

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)

local function addTag(player, character)
	local head = character:WaitForChild("Head", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not head or not humanoid then
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.new(5, 0, 3.4, 0)
	tag.StudsOffset = Vector3.new(0, 3.6, 0)
	tag.MaxDistance = 120
	tag.LightInfluence = 0
	tag.Adornee = head

	local photo = Instance.new("ImageLabel")
	photo.Name = "Headshot"
	photo.BackgroundColor3 = Color3.fromRGB(70, 70, 76)
	photo.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
	photo.AnchorPoint = Vector2.new(0.5, 0)
	photo.Position = UDim2.new(0.5, 0, 0, 0)
	photo.Size = UDim2.new(0.66, 0, 0.66, 0)
	photo.SizeConstraint = Enum.SizeConstraint.RelativeYY
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = photo
	local ring = Instance.new("UIStroke")
	ring.Thickness = 2
	ring.Color = Color3.new(0, 0, 0)
	ring.Parent = photo
	photo.Parent = tag

	local name = Instance.new("TextLabel")
	name.Name = "Username"
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 0, 0.68, 0)
	name.Size = UDim2.new(1, 0, 0.3, 0)
	name.FontFace = FONT
	name.Text = player.Name
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeColor3 = Color3.new(0, 0, 0)
	name.TextStrokeTransparency = 0
	name.Parent = tag

	tag.Parent = head
end

function NameTagService.start()
	local function watch(player)
		player.CharacterAdded:Connect(function(character)
			addTag(player, character)
		end)
		if player.Character then
			task.spawn(addTag, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
end

return NameTagService
