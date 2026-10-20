--[[
	UI: the style kit, copied from Steal An Egg's real UI (screenshots in the vault note
	"Roblox Research/Concepts/UI Style Guide.md").

	* One font everywhere: Montserrat Black. Roblox ships it as the Gotham family
	  (Enum.Font.GothamBlack = GothamSSm, weight Heavy). The cash counter uses the italic face.
	* White text with a thick black outline. Coloured text is white with a vertical UIGradient
	  (white on top, tint at the bottom), so the black outline stays black.
	* Lime-green price buttons, a red square close button, a green window header with a light
	  diagonal shine, and a dark grey window body.

	Sizes are in pixels for a 1280 x 720 screen. Each ScreenGui gets a UIScale (UI.autoScale),
	so phones and big monitors see the same layout.

	Components from the Check-UI kit (MIT, .claude/skills/check-ui-clean-roblox, game/vendor/CheckUI):
	the 3D beveled buy and close buttons, damier (checkerboard) overlays, rotating sunbursts and
	its uploaded icons (GameConfig.Icons, each with an emoji fallback if the image fails to load).
]]

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local UI = {}

local FAMILY = "rbxasset://fonts/families/GothamSSm.json"
UI.Font = Font.new(FAMILY, Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
UI.FontItalic = Font.new(FAMILY, Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
UI.FontBold = Font.new(FAMILY, Enum.FontWeight.Bold, Enum.FontStyle.Normal)

UI.Colors = {
	Outline = Color3.fromRGB(0, 0, 0),
	White = Color3.fromRGB(255, 255, 255),
	CashGreen = Color3.fromRGB(24, 255, 24),      -- the "$43,931" counter
	HighlightGreen = Color3.fromRGB(40, 230, 40), -- "x2" inside descriptions
	SpeedBlue = Color3.fromRGB(70, 215, 255),
	HeaderTop = Color3.fromRGB(140, 236, 70),
	HeaderBottom = Color3.fromRGB(86, 200, 30),
	HeaderBorder = Color3.fromRGB(40, 110, 20),
	Body = Color3.fromRGB(58, 59, 66),
	BodyBorder = Color3.fromRGB(30, 30, 34),
	CardBorder = Color3.fromRGB(28, 28, 30),
	Grey = Color3.fromRGB(110, 110, 116),
	Red = Color3.fromRGB(255, 70, 60),
}

-- Bottom tints for gradient text (top is always white)
UI.Tints = {
	Featured = { Color3.fromRGB(255, 236, 110), Color3.fromRGB(255, 170, 30) }, -- yellow -> orange, both ends tinted
	Gold = { Color3.fromRGB(255, 250, 150), Color3.fromRGB(255, 200, 0) },      -- "-- FEATURED --" / "-- PASSES --"
	Cyan = { Color3.fromRGB(170, 250, 255), Color3.fromRGB(0, 200, 255) },      -- "-- SPEED --"
	Green = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 255, 150) },   -- "Money" label
	Blue = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(130, 240, 255) },    -- "Speed" label
	Peach = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 205, 140) },   -- "Stars" label
}

UI.Rainbow = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 160, 30)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 60)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 230, 90)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(60, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 80, 255)),
})

function UI.new(className, props, children)
	local instance = Instance.new(className)
	local parent = nil
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UI.corner(radius)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

-- A border stroke for frames and buttons
function UI.border(thickness, color)
	return UI.new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or UI.Colors.Outline,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

--[[ Outlined text.
	opts: size (UDim2), position, anchor, color, stroke (px), italic, align ("Left"/"Center"/"Right"),
	      rich (RichText), maxSize (TextSize cap), z, name, parent ]]
function UI.text(text, opts)
	opts = opts or {}
	local label = UI.new("TextLabel", {
		Name = opts.name or "Text",
		BackgroundTransparency = 1,
		FontFace = opts.italic and UI.FontItalic or UI.Font,
		Text = text,
		TextScaled = true,
		RichText = opts.rich == true,
		TextColor3 = opts.color or UI.Colors.White,
		TextXAlignment = Enum.TextXAlignment[opts.align or "Center"],
		Size = opts.size or UDim2.new(1, 0, 1, 0),
		Position = opts.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = opts.anchor or Vector2.new(0, 0),
		ZIndex = opts.z or 2,
	})
	UI.new("UIStroke", {
		Name = "Outline",
		Thickness = opts.stroke or 3,
		Color = UI.Colors.Outline,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = label,
	})
	if opts.maxSize then
		UI.new("UITextSizeConstraint", { MaxTextSize = opts.maxSize, Parent = label })
	end
	if opts.parent then
		label.Parent = opts.parent
	end
	return label
end

-- White-to-tint vertical gradient on a text label (the outline stays black).
function UI.tint(label, tint)
	local gradient = label:FindFirstChildOfClass("UIGradient") or UI.new("UIGradient", { Parent = label })
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(tint[1], tint[2])
	return gradient
end

function UI.rainbow(label)
	local gradient = label:FindFirstChildOfClass("UIGradient") or UI.new("UIGradient", { Parent = label })
	gradient.Rotation = 0
	gradient.Color = UI.Rainbow
	return gradient
end

-- Light diagonal stripes like the shop header's glass shine.
function UI.shine(frame, transparency)
	local holder = UI.new("Frame", {
		Name = "Shine",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = frame.ZIndex,
		Parent = frame,
	})
	for i, x in ipairs({ 0.42, 0.5, 0.78 }) do
		UI.new("Frame", {
			BackgroundColor3 = UI.Colors.White,
			BackgroundTransparency = transparency or 0.8,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(x, 0, 0.5, 0),
			Size = UDim2.new(0, i == 2 and 10 or 26, 3, 0),
			Rotation = 35,
			ZIndex = frame.ZIndex,
			Parent = holder,
		})
	end
	return holder
end

-- Rich text helper: "Get <green>x2</green> Money!" -> RichText with the highlight colour.
function UI.highlight(text)
	local hex = string.format("#%02X%02X%02X", 40, 230, 40)
	return (string.gsub(text, "<green>(.-)</green>", '<font color="' .. hex .. '">%1</font>'))
end

-- Grow a little on hover, squash on press (UI Patterns: 1.0 -> 1.08 -> 0.95).
function UI.pressable(button)
	local scale = button:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = button })
	local TweenService = game:GetService("TweenService")
	local info = TweenInfo.new(0.08)
	local function to(value)
		TweenService:Create(scale, info, { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.06)
	end)
	button.MouseLeave:Connect(function()
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.94)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.06)
	end)
end

-- Check-UI button states: { top, bottom, bevel, highlight, damier }
UI.ButtonStates = {
	buy = { Color3.fromRGB(235, 255, 30), Color3.fromRGB(20, 215, 10), Color3.fromRGB(15, 120, 15), Color3.fromRGB(235, 255, 130), Color3.fromRGB(0, 110, 0) },
	owned = { Color3.fromRGB(216, 222, 228), Color3.fromRGB(148, 160, 176), Color3.fromRGB(72, 82, 96), Color3.fromRGB(255, 255, 255), Color3.fromRGB(96, 104, 112) },
	poor = { Color3.fromRGB(255, 32, 80), Color3.fromRGB(208, 0, 32), Color3.fromRGB(112, 0, 16), Color3.fromRGB(255, 176, 200), Color3.fromRGB(144, 0, 24) },
	equip = { Color3.fromRGB(0, 205, 255), Color3.fromRGB(0, 130, 245), Color3.fromRGB(0, 50, 110), Color3.fromRGB(180, 240, 255), Color3.fromRGB(0, 75, 150) },
	gift = { Color3.fromRGB(196, 80, 255), Color3.fromRGB(140, 30, 220), Color3.fromRGB(70, 10, 110), Color3.fromRGB(230, 180, 255), Color3.fromRGB(96, 0, 144) },
}

-- Checkerboard overlay (Check-UI "damier"): the uploaded 2x2 checker tile, tinted, fading in
-- toward the bottom. tile = pixels per tile. fade = { top, bottom } transparencies, or a list of
-- { position, transparency } keypoints (Check-UI's 4-point fade is the default).
UI.DAMIER_FADE = { { 0, 1 }, { 0.3, 0.82 }, { 0.65, 0.35 }, { 1, 0.1 } }
function UI.damier(parent, color, tile, fade, z, imageTransparency, rotation)
	local layer = UI.new("ImageLabel", {
		Name = "Damier",
		BackgroundTransparency = 1,
		Image = GameConfig.UIAssets.Checker,
		ImageColor3 = color or Color3.new(0, 0, 0),
		ImageTransparency = imageTransparency or 0,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, tile or 18, 0, tile or 18),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = z or parent.ZIndex,
		Parent = parent,
	})
	fade = fade or UI.DAMIER_FADE
	local sequence
	if type(fade[1]) == "table" then
		local points = {}
		for _, kp in ipairs(fade) do
			table.insert(points, NumberSequenceKeypoint.new(kp[1], kp[2]))
		end
		sequence = NumberSequence.new(points)
	else
		sequence = NumberSequence.new(fade[1], fade[2])
	end
	UI.new("UIGradient", { Rotation = rotation or 90, Transparency = sequence, Parent = layer })
	return layer
end

-- Rotating sunburst behind an icon (Check-UI: 20 degrees per second, only while visible)
local sunbursts = {}
function UI.sunburst(parent, size, position, transparency, z)
	local burst = UI.new("ImageLabel", {
		Name = "Sunburst",
		BackgroundTransparency = 1,
		Image = GameConfig.UIAssets.Sunburst,
		ImageTransparency = transparency or 0.45,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = size,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = z or parent.ZIndex,
		Parent = parent,
	})
	table.insert(sunbursts, burst)
	return burst
end
RunService.RenderStepped:Connect(function(dt)
	for i = #sunbursts, 1, -1 do
		local burst = sunbursts[i]
		if not burst.Parent then
			table.remove(sunbursts, i)
		elseif burst.Visible then
			burst.Rotation = (burst.Rotation + 20 * dt) % 360
		end
	end
end)

-- Check-UI 3D button: gradient face, 3px dark bevel along the bottom, pastel inner highlight,
-- checker overlay and a 3px near-black border. state = a key of UI.ButtonStates.
function UI.bevelButton(opts)
	local button = UI.new("TextButton", {
		Name = opts.name or "Button",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = opts.size,
		Position = opts.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = opts.anchor or Vector2.new(0, 0),
		ZIndex = opts.z or 3,
	}, { UI.corner(4), UI.border(2.4, Color3.new(0, 0, 0)) })
	UI.new("UIGradient", { Name = "Face", Rotation = 90, Parent = button })
	UI.new("Frame", {
		Name = "Bevel",
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 3),
		ZIndex = button.ZIndex,
		Parent = button,
	})
	UI.damier(button, Color3.new(0, 0, 0), 12, nil, button.ZIndex)
	local inner = UI.new("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -1),
		Size = UDim2.new(1, -4, 1, -6),
		ZIndex = button.ZIndex,
		Parent = button,
	}, { UI.corner(3) })
	UI.new("UIStroke", { Name = "Highlight", Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inner })
	UI.setButtonState(button, opts.state or "buy")
	UI.pressable(button)
	if opts.parent then
		button.Parent = opts.parent
	end
	return button
end

function UI.setButtonState(button, state)
	local colors = UI.ButtonStates[state] or UI.ButtonStates.buy
	local face = button:FindFirstChild("Face")
	if face then
		face.Color = ColorSequence.new(colors[1], colors[2])
	end
	local bevel = button:FindFirstChild("Bevel")
	if bevel then
		bevel.BackgroundColor3 = colors[3]
	end
	local inner = button:FindFirstChild("Inner")
	local highlight = inner and inner:FindFirstChild("Highlight")
	if highlight then
		highlight.Color = colors[4]
	end
	local damier = button:FindFirstChild("Damier")
	if damier then
		damier.ImageColor3 = colors[5]
	end
end

-- Lime buy button with an optional Robux icon and the price ("467").
function UI.priceButton(text, robux, opts)
	opts = opts or {}
	local button = UI.bevelButton({
		name = "Price",
		state = opts.state or "buy",
		size = opts.size,
		position = opts.position,
		anchor = opts.anchor,
		parent = opts.parent,
	})
	local x = 0.06
	if robux then
		UI.icon(GameConfig.Icons.Robux, {
			name = "Robux",
			anchor = Vector2.new(0, 0.5),
			position = UDim2.new(0.1, 0, 0.5, -1),
			size = UDim2.new(0.62, 0, 0.62, 0),
			square = true,
			z = button.ZIndex + 1,
			parent = button,
		})
		x = 0.3
	end
	UI.text(text, {
		name = "Label",
		size = UDim2.new(1 - x - 0.06, 0, 0.68, 0),
		position = UDim2.new(x, 0, 0.13, 0),
		stroke = 2.5,
		z = button.ZIndex + 1,
		parent = button,
	})
	return button
end

-- Check-UI's 3D beveled square close button: burgundy base, crimson-pink face shifted up 4px,
-- pastel inner line, white X.
function UI.closeButton(parent)
	local button = UI.new("TextButton", {
		Name = "Close",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(115, 0, 16),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 46, 0, 46),
		ZIndex = 4,
	}, { UI.border(2.8, Color3.new(0, 0, 0)) })
	local face = UI.new("Frame", {
		Name = "Face",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -4),
		ZIndex = 5,
		Parent = button,
	})
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 125, 175), Color3.fromRGB(255, 20, 40)), Parent = face })
	local inner = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -3, 1, -3),
		ZIndex = 6,
		Parent = face,
	})
	UI.new("UIStroke", { Thickness = 1.2, Color = Color3.fromRGB(255, 210, 235), ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inner })
	UI.new("Frame", {
		BackgroundColor3 = Color3.fromRGB(70, 0, 10),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 6,
		Parent = button,
	})
	UI.text("X", { size = UDim2.new(0.72, 0, 0.72, 0), position = UDim2.new(0.14, 0, 0.12, 0), stroke = 3, z = 7, parent = face })
	UI.pressable(button)
	button.Parent = parent
	return button
end

local function emojiLabel(emoji, opts)
	return UI.new("TextLabel", {
		Name = opts.name or "Icon",
		BackgroundTransparency = 1,
		Text = emoji,
		TextScaled = true,
		FontFace = UI.Font,
		TextColor3 = UI.Colors.White,
		Size = opts.size,
		Position = opts.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = opts.anchor or Vector2.new(0, 0),
		SizeConstraint = opts.square and Enum.SizeConstraint.RelativeYY or Enum.SizeConstraint.RelativeXY,
		ZIndex = opts.z or 2,
		Parent = opts.parent,
	})
end

--[[ An icon. icon = { image = "rbxassetid://...", emoji = "..." } (GameConfig.Icons), a plain
	"rbxassetid://..." string, or an emoji string. Images keep their shape (ScaleType Fit, as
	Check-UI requires); if one fails to load, the emoji takes its place. ]]
function UI.icon(icon, opts)
	local image, emoji = nil, nil
	if type(icon) == "table" then
		image, emoji = icon.image, icon.emoji
	elseif type(icon) == "string" and string.sub(icon, 1, 13) == "rbxassetid://" then
		image = icon
	else
		emoji = icon
	end
	if not image then
		return emojiLabel(emoji or "?", opts)
	end
	local label = UI.new("ImageLabel", {
		Name = opts.name or "Icon",
		BackgroundTransparency = 1,
		Image = image,
		ScaleType = Enum.ScaleType.Fit,
		Size = opts.size,
		Position = opts.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = opts.anchor or Vector2.new(0, 0),
		SizeConstraint = opts.square and Enum.SizeConstraint.RelativeYY or Enum.SizeConstraint.RelativeXY,
		ZIndex = opts.z or 2,
		Parent = opts.parent,
	})
	if emoji then
		task.spawn(function()
			local ok = pcall(function()
				ContentProvider:PreloadAsync({ label }, function(_, status)
					if status ~= Enum.AssetFetchStatus.Success and label.Parent then
						local fallback = emojiLabel(emoji, opts)
						fallback.Parent = label.Parent
						label:Destroy()
					end
				end)
			end)
			if not ok then
				warn("[UI] could not preload icon " .. image)
			end
		end)
	end
	return label
end

-- Keeps a layout the same size relative to any screen. Default baseline 1280x720; the Check-UI
-- windows use theirs (1050x620, clamped 0.52-1.18).
function UI.autoScale(screenGui, baseX, baseY, minScale, maxScale)
	local scale = UI.new("UIScale", { Parent = screenGui })
	local camera = workspace.CurrentCamera
	local function update()
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min(viewport.X / (baseX or 1280), viewport.Y / (baseY or 720)), minScale or 0.55, maxScale or 1.6)
	end
	update()
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
	return scale
end

function UI.screen(name, order)
	return UI.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = order or 0,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
end

return UI
