--[[
	UI: small helpers that build the cartoon style from the UI mockup in code
	(Luckiest Guy text with a dark outline, chunky rounded panels, inset button shadow).
]]

local UI = {}

UI.Colors = {
	Outline = Color3.fromRGB(26, 15, 5),
	Wood = Color3.fromRGB(138, 84, 38),
	WoodDark = Color3.fromRGB(107, 63, 31),
	Cream = Color3.fromRGB(255, 244, 220),
	Cash = Color3.fromRGB(110, 255, 120),
	Speed = Color3.fromRGB(80, 200, 255),
	Gold = Color3.fromRGB(255, 208, 46),
	Red = Color3.fromRGB(255, 70, 60),
	Green = Color3.fromRGB(60, 190, 80),
	Grey = Color3.fromRGB(120, 120, 120),
}

function UI.new(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function UI.corner(radius)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 14) })
end

function UI.stroke(thickness, color)
	return UI.new("UIStroke", {
		Thickness = thickness or 4,
		Color = color or UI.Colors.Outline,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- Outlined cartoon text. props are applied on top of the defaults.
function UI.text(text, props)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.LuckiestGuy,
		Text = text,
		TextScaled = true,
		TextColor3 = UI.Colors.Cream,
		Size = UDim2.new(1, 0, 1, 0),
	})
	UI.new("UIStroke", { Thickness = 2.5, Color = UI.Colors.Outline, Parent = label })
	for key, value in pairs(props or {}) do
		label[key] = value
	end
	return label
end

function UI.panel(props)
	local frame = UI.new("Frame", {
		BackgroundColor3 = UI.Colors.Wood,
		BorderSizePixel = 0,
	}, { UI.corner(16), UI.stroke(4) })
	for key, value in pairs(props or {}) do
		frame[key] = value
	end
	return frame
end

function UI.button(text, color, props)
	local button = UI.new("TextButton", {
		BackgroundColor3 = color or UI.Colors.Green,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Text = "",
	}, { UI.corner(12), UI.stroke(3) })
	-- inset shadow along the bottom, like the mockup's buttons
	UI.new("Frame", {
		Name = "Shade",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0.22, 0),
		ZIndex = 1,
		Parent = button,
	}, { UI.corner(12) })
	local label = UI.text(text, {
		Name = "Label",
		Size = UDim2.new(0.9, 0, 0.7, 0),
		Position = UDim2.new(0.05, 0, 0.1, 0),
		ZIndex = 2,
	})
	label.Parent = button
	for key, value in pairs(props or {}) do
		button[key] = value
	end
	return button
end

function UI.rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

return UI
