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
]]

local Players = game:GetService("Players")

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
	PriceGreen = Color3.fromRGB(110, 222, 34),    -- price buttons
	PriceGreenDark = Color3.fromRGB(60, 160, 14),
	PriceBorder = Color3.fromRGB(30, 70, 12),
	GiftPurple = Color3.fromRGB(176, 60, 230),
	GiftBorder = Color3.fromRGB(70, 20, 100),
	CloseRed = Color3.fromRGB(226, 24, 24),
	CloseBorder = Color3.fromRGB(110, 0, 0),
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

-- Square/rect button with a coloured fill, darker bottom half and a dark border.
function UI.button(opts)
	local button = UI.new("TextButton", {
		Name = opts.name or "Button",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = opts.color or UI.Colors.PriceGreen,
		BorderSizePixel = 0,
		Size = opts.size,
		Position = opts.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = opts.anchor or Vector2.new(0, 0),
		ZIndex = opts.z or 2,
	}, { UI.corner(opts.radius or 5), UI.border(opts.borderThickness or 3, opts.border or UI.Colors.PriceBorder) })
	if opts.dark then
		UI.new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.56, Color3.fromRGB(215, 215, 215)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 215, 215)),
			}),
			Parent = button,
		})
	end
	UI.pressable(button)
	if opts.parent then
		button.Parent = opts.parent
	end
	return button
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

-- Green price button: optional Robux icon + price text.
function UI.priceButton(text, robux, opts)
	opts = opts or {}
	local button = UI.button({
		name = "Price",
		color = opts.color or UI.Colors.PriceGreen,
		border = opts.border or UI.Colors.PriceBorder,
		size = opts.size,
		position = opts.position,
		anchor = opts.anchor,
		dark = true,
		parent = opts.parent,
	})
	local x = 0.06
	if robux then
		UI.new("ImageLabel", {
			Name = "Robux",
			BackgroundTransparency = 1,
			Image = "rbxasset://textures/ui/common/robux.png",
			ImageColor3 = UI.Colors.White,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0.12, 0, 0.5, 0),
			Size = UDim2.new(0.62, 0, 0.62, 0),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 3,
			Parent = button,
		})
		x = 0.3
	end
	UI.text(text, {
		name = "Label",
		size = UDim2.new(1 - x - 0.06, 0, 0.7, 0),
		position = UDim2.new(x, 0, 0.15, 0),
		stroke = 2.5,
		z = 3,
		parent = button,
	})
	return button
end

function UI.closeButton(parent)
	local button = UI.button({
		name = "Close",
		color = UI.Colors.CloseRed,
		border = UI.Colors.CloseBorder,
		size = UDim2.new(0, 46, 0, 46),
		anchor = Vector2.new(1, 0.5),
		position = UDim2.new(1, -8, 0.5, 0),
		radius = 3,
		parent = parent,
	})
	UI.text("X", { size = UDim2.new(0.7, 0, 0.7, 0), position = UDim2.new(0.15, 0, 0.15, 0), stroke = 3, z = 3, parent = button })
	return button
end

-- An emoji or image icon. icon = "rbxassetid://..." for an uploaded image, otherwise an emoji.
function UI.icon(icon, opts)
	if string.sub(icon, 1, 13) == "rbxassetid://" then
		return UI.new("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = icon,
			ScaleType = Enum.ScaleType.Fit,
			Size = opts.size,
			Position = opts.position or UDim2.new(0, 0, 0, 0),
			AnchorPoint = opts.anchor or Vector2.new(0, 0),
			ZIndex = opts.z or 2,
			Parent = opts.parent,
		})
	end
	return UI.new("TextLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Text = icon,
		TextScaled = true,
		FontFace = UI.Font,
		TextColor3 = UI.Colors.White,
		Size = opts.size,
		Position = opts.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = opts.anchor or Vector2.new(0, 0),
		ZIndex = opts.z or 2,
		Parent = opts.parent,
	})
end

-- Keeps a 1280x720 layout the same size relative to any screen.
function UI.autoScale(screenGui)
	local scale = UI.new("UIScale", { Parent = screenGui })
	local camera = workspace.CurrentCamera
	local function update()
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.55, 1.6)
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
