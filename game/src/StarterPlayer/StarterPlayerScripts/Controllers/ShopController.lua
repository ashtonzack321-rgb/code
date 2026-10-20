--[[
	ShopController: the Shop window, built exactly like the Check-UI kit's Shop menu
	(.claude/skills/check-ui-clean-roblox, examples/ShopMenuExample.luau; the user's reference
	picture is "Pasted image 20261020172519.png" in the vault):
	  * 600 x 415 solid slate-blue window (#3B5866) with a 3.5 px dark outline
	  * 60 px magenta-to-crimson header: pastel top line, fading damier, 2-tier divider,
	    "Shop" title on the left and the 3D beveled [X]
	  * "~Gamepass~" section: 276 x 155 cards (purple, cyan ...) with a sunburst, a fading damier,
	    the icon on the left, the description on the right and a lime Robux buy button
	  * "~Treadmills~", "~Spurs~" and "~Ranch~" sections: 180 x 175 lime product cards, three per
	    row, with the name on top, the icon in the middle and the price button at the bottom
	Opens from the left rail (Featured / Speed / Money jump to their section) or by stepping on
	the glowing ShopPad in Town. Buttons only ask the server (Remotes.Shop); cards update from
	player attributes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local ShopRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop")

local UI = require(script.Parent:WaitForChild("UI"))

local ShopController = {}

local player = Players.LocalPlayer
local gui, window, list, uiScale
local sections = {}   -- [name] = section title label
local cards = {}      -- update functions, called with the player's cash
local busy = false
local toast = function() end

-- Check-UI card themes: gradient top/bottom, inner highlight, damier colour
local THEMES = {
	Purple = { Color3.fromRGB(235, 60, 255), Color3.fromRGB(150, 0, 245), Color3.fromRGB(235, 160, 255), Color3.fromRGB(90, 0, 165) },
	Cyan = { Color3.fromRGB(30, 235, 255), Color3.fromRGB(0, 120, 255), Color3.fromRGB(165, 240, 255), Color3.fromRGB(0, 65, 180) },
	Gold = { Color3.fromRGB(255, 220, 40), Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 240, 170), Color3.fromRGB(176, 96, 0) },
	Pink = { Color3.fromRGB(255, 60, 170), Color3.fromRGB(210, 0, 90), Color3.fromRGB(255, 176, 208), Color3.fromRGB(150, 0, 60) },
	Lime = { Color3.fromRGB(235, 255, 50), Color3.fromRGB(110, 215, 0), Color3.fromRGB(245, 255, 180), Color3.fromRGB(70, 170, 0) },
}
-- Pass card colours (GameConfig.Passes[].card) mapped onto the Check-UI themes
local PASS_THEMES = { Rainbow = "Purple", Gold = "Gold", Purple = "Pink", Blue = "Cyan" }

local function ask(action, arg)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		pcall(function()
			ShopRemote:InvokeServer(action, arg)
		end)
		busy = false
	end)
end

local function owns(spurId)
	return string.find("," .. (player:GetAttribute("OwnedSpurs") or "") .. ",", "," .. spurId .. ",", 1, true) ~= nil
end

----------------------------------------------------------------------------------------------
-- Building blocks (numbers from Check-UI's ShopMenuExample)
----------------------------------------------------------------------------------------------
local function sectionTitle(order, text)
	local label = UI.text("~" .. text .. "~", {
		name = "Section_" .. text,
		size = UDim2.new(1, 0, 0, 24),
		stroke = 2.6,
		parent = list,
	})
	label.LayoutOrder = order
	sections[text] = label
	return label
end

local function grid(order, cellW, cellH)
	return UI.new("Frame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = list,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.new(0, cellW, 0, cellH),
			CellPadding = UDim2.new(0, 16, 0, 12),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

-- The card body every Check-UI card shares: white frame + gradient, black 2.8 px outline,
-- pastel inner line, fading damier and a sunburst.
local function cardBase(parent, order, name, theme, burstSize, burstPos, damierTile, damierFade, damierRotation)
	local frame = UI.new("Frame", {
		Name = name,
		LayoutOrder = order,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 22,
		Parent = parent,
	}, { UI.corner(4), UI.border(2.8, Color3.new(0, 0, 0)) })
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(theme[1], theme[2]), Parent = frame })
	local inner = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -6, 1, -6),
		ZIndex = 27,
		Parent = frame,
	}, { UI.corner(3) })
	UI.new("UIStroke", { Thickness = 1.4, Color = theme[3], ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inner })
	UI.damier(frame, theme[4], damierTile, damierFade, 23, 0.35, damierRotation)
	UI.sunburst(frame, UDim2.new(0, burstSize, 0, burstSize), burstPos, 0.12, 24)
	return frame
end

-- ~Gamepass~ card (276 x 155): title on top, icon left, description right, Robux buy button
local function passCard(parent, order, pass)
	local theme = THEMES[PASS_THEMES[pass.card] or "Purple"]
	local frame = cardBase(parent, order, pass.name, theme, 220, UDim2.new(0, 68, 0.5, 12), 22,
		{ { 0, 1 }, { 0.35, 0.6 }, { 1, 0.05 } }, 65)
	UI.text(pass.name, { name = "Title", anchor = Vector2.new(0.5, 0), position = UDim2.new(0.5, 0, 0, 8),
		size = UDim2.new(1, -16, 0, 26), stroke = 2.8, z = 26, parent = frame })
	UI.icon(GameConfig.Icons[pass.icon], { anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 8, 0.5, 12),
		size = UDim2.new(0, 120, 0, 95), z = 25, parent = frame })
	local description = UI.text(UI.highlight(pass.description), { name = "Description", rich = true,
		anchor = Vector2.new(0.5, 0.5), position = UDim2.new(0.72, 0, 0.46, 0), size = UDim2.new(0, 130, 0, 46),
		stroke = 2.4, z = 26, parent = frame })
	description.TextWrapped = true
	local price = UI.priceButton(NumberFormat.commas(pass.robux), true, {
		size = UDim2.new(0, 114, 0, 38),
		position = UDim2.new(0.72, 0, 0.78, 0),
		anchor = Vector2.new(0.5, 0.5),
		parent = frame,
	})
	price.ZIndex = 26
	price.Activated:Connect(function()
		if pass.gamePassId and pass.gamePassId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, pass.gamePassId)
		else
			toast(pass.name .. " is coming soon!", "info")
		end
	end)
end

-- Product card (180 x 175): name on top, small line under it, icon in the middle, price button
local function productCard(parent, order, title, subtitle, icon)
	local frame = cardBase(parent, order, title, THEMES.Lime, 190, UDim2.new(0.5, 0, 0.5, 0), 18,
		{ { 0, 1 }, { 0.35, 0.65 }, { 1, 0.05 } }, 90)
	UI.text(title, { name = "Title", anchor = Vector2.new(0.5, 0), position = UDim2.new(0.5, 0, 0, 8),
		size = UDim2.new(1, -10, 0, 24), stroke = 2.8, z = 26, parent = frame })
	local sub = UI.text(UI.highlight(subtitle), { name = "Subtitle", rich = true, anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 33), size = UDim2.new(1, -14, 0, 18), stroke = 2.2, z = 26, parent = frame })
	UI.icon(icon, { anchor = Vector2.new(0.5, 0.5), position = UDim2.new(0.5, 0, 0.5, 4),
		size = UDim2.new(0, 110, 0, 72), z = 25, parent = frame })
	local price = UI.priceButton("", false, {
		size = UDim2.new(1, -24, 0, 36),
		position = UDim2.new(0.5, 0, 1, -24),
		anchor = Vector2.new(0.5, 0.5),
		parent = frame,
	})
	price.ZIndex = 26
	return price, sub
end

-- Price button text + Check-UI state: lime "buy", cyan "equip", silver "owned", red "poor"
local function setButton(button, text, kind)
	button.Label.Text = text
	UI.setButtonState(button, kind)
end

----------------------------------------------------------------------------------------------
-- Sections
----------------------------------------------------------------------------------------------
local function buildPasses(order)
	local g = grid(order, 276, 155)
	for i, pass in ipairs(GameConfig.Passes) do
		passCard(g, i, pass)
	end
end

local function buildTreadmills(order)
	local g = grid(order, 180, 175)
	for i, t in ipairs(GameConfig.Treadmill.Tiers) do
		local price = productCard(g, i, t.name, "<green>+" .. NumberFormat.short(t.speedPerStep) .. "</green> Speed / step",
			GameConfig.Icons.Treadmill)
		price.Activated:Connect(function()
			ask("BuyTreadmill", t.tier)
		end)
		table.insert(cards, function(cash)
			local current = player:GetAttribute("TreadmillTier") or 1
			if t.tier == current then
				setButton(price, "Equipped", "owned")
			elseif t.tier < current then
				setButton(price, "Owned", "owned")
			elseif t.tier == current + 1 then
				setButton(price, NumberFormat.cash(t.price), cash >= t.price and "buy" or "poor")
			else
				setButton(price, "Locked", "owned")
			end
		end)
	end
end

local function buildSpurs(order)
	local g = grid(order, 180, 175)
	for i, spur in ipairs(GameConfig.Spurs) do
		local price = productCard(g, i, spur.name, "Treadmill <green>x" .. tostring(spur.multiplier) .. "</green>",
			GameConfig.Icons.Spurs)
		price.Activated:Connect(function()
			if player:GetAttribute("EquippedSpur") == spur.id then
				ask("EquipSpur", "")
			elseif owns(spur.id) then
				ask("EquipSpur", spur.id)
			else
				ask("BuySpur", spur.id)
			end
		end)
		table.insert(cards, function(cash)
			if player:GetAttribute("EquippedSpur") == spur.id then
				setButton(price, "Equipped", "owned")
			elseif owns(spur.id) then
				setButton(price, "Equip", "equip")
			else
				setButton(price, NumberFormat.cash(spur.price), cash >= spur.price and "buy" or "poor")
			end
		end)
	end
end

local function buildRanch(order)
	local g = grid(order, 180, 175)
	local price, sub = productCard(g, 1, "Pen Slot", "Room for <green>+1</green> beast", GameConfig.Icons.Pen)
	price.Activated:Connect(function()
		ask("BuyPenSlot")
	end)
	table.insert(cards, function(cash)
		local level = player:GetAttribute("PenLevel") or 1
		local slots = player:GetAttribute("PenSlots") or GameConfig.Pen.StartSlots
		local cost = GameConfig.Pen.UpgradePrices[level]
		if slots >= GameConfig.Pen.MaxSlots or not cost then
			setButton(price, "Maxed", "owned")
			sub.Text = UI.highlight("<green>" .. slots .. "</green> slots (max)")
		else
			setButton(price, NumberFormat.cash(cost), cash >= cost and "buy" or "poor")
			sub.Text = UI.highlight(slots .. " \u{2192} <green>" .. (slots + 1) .. "</green> slots")
		end
	end)
end

local function updateCards()
	if not window or not window.Visible then
		return
	end
	local cash = player:GetAttribute("Cash") or 0
	for _, update in ipairs(cards) do
		update(cash)
	end
end

----------------------------------------------------------------------------------------------
-- Window
----------------------------------------------------------------------------------------------
local function build()
	gui = UI.screen("Shop", 5)
	uiScale = UI.autoScale(gui, 1050, 620, 0.52, 1.18) -- Check-UI's responsive baseline

	window = UI.new("Frame", {
		Name = "ShopFrame",
		BackgroundColor3 = Color3.fromRGB(59, 88, 102),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 600, 0, 415),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	}, { UI.corner(4), UI.border(3.5, Color3.fromRGB(24, 30, 34)) })

	-- Header: magenta -> crimson, pastel top line, fading damier, 2-tier divider
	local header = UI.new("Frame", {
		Name = "Header",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 60),
		ZIndex = 21,
		Parent = window,
	}, { UI.corner(4) })
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 20, 150), Color3.fromRGB(225, 0, 25)), Parent = header })
	UI.new("Frame", { Name = "TopHighlight", BackgroundColor3 = Color3.fromRGB(255, 200, 225), BackgroundTransparency = 0.3,
		BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2), ZIndex = 22, Parent = header })
	UI.damier(header, Color3.fromRGB(150, 0, 20), 26, nil, 22, 0.35)
	UI.new("Frame", { Name = "DivDark", BackgroundColor3 = Color3.fromRGB(125, 0, 18), BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 3), ZIndex = 23, Parent = header })
	UI.new("Frame", { Name = "DivBlack", BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3), ZIndex = 23, Parent = header })
	UI.text("Shop", {
		name = "Title",
		align = "Left",
		anchor = Vector2.new(0, 0.5),
		position = UDim2.new(0, 18, 0.5, -2),
		size = UDim2.new(0, 180, 0, 44),
		stroke = 3.2,
		z = 24,
		parent = header,
	})
	local close = UI.closeButton(header)
	close.Size = UDim2.new(0, 38, 0, 38)
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Position = UDim2.new(1, -34, 0.5, -2)
	close.ZIndex = 25
	close.Activated:Connect(function()
		ShopController.close()
	end)

	list = UI.new("ScrollingFrame", {
		Name = "ContentScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 60),
		Size = UDim2.new(1, 0, 1, -60),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 7,
		ScrollBarImageColor3 = Color3.fromRGB(210, 225, 235),
		ScrollBarImageTransparency = 0.3,
		ZIndex = 21,
		Parent = window,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 14) }),
	})

	sectionTitle(1, "Gamepass")
	buildPasses(2)
	sectionTitle(3, "Treadmills")
	buildTreadmills(4)
	sectionTitle(5, "Spurs")
	buildSpurs(6)
	sectionTitle(7, "Ranch")
	buildRanch(8)
end

-- section: "Gamepass" (top), "Treadmills", "Spurs" or "Ranch"
function ShopController.open(section)
	window.Visible = true
	updateCards()
	-- Check-UI pop-in: centred scale from 0.85 with Back easing
	local pop = window:FindFirstChild("WindowScale") or UI.new("UIScale", { Name = "WindowScale", Parent = window })
	pop.Scale = 0.85
	local title = sections[section or "Gamepass"]
	if title then
		task.defer(function()
			-- Absolute positions include both the screen scale and the pop-in scale
			local scale = (uiScale and uiScale.Scale or 1) * pop.Scale
			local y = (title.AbsolutePosition.Y - list.AbsolutePosition.Y) / scale + list.CanvasPosition.Y
			list.CanvasPosition = Vector2.new(0, math.max(0, y - 6))
		end)
	end
	TweenService:Create(pop, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function ShopController.close()
	window.Visible = false
end

function ShopController.toggle(section)
	if window.Visible then
		ShopController.close()
	else
		ShopController.open(section)
	end
end

-- Opens the shop once each time you step onto a ShopPad (not every frame you stand on it).
local function watchPads()
	local wasOn = false
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local on = false
		for _, pad in ipairs(CollectionService:GetTagged("ShopPad")) do
			if pad:IsA("BasePart") then
				local offset = root.Position - pad.Position
				local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flat <= pad.Size.Y / 2 and math.abs(offset.Y) < 8 then
					on = true
				end
			end
		end
		if on and not wasOn then
			ShopController.open("Gamepass")
		end
		wasOn = on
	end)
end

-- Which prices the player can afford, as a string (it only changes when a button would)
local function affordKey(cash)
	local bits = {}
	for _, t in ipairs(GameConfig.Treadmill.Tiers) do
		table.insert(bits, cash >= t.price and "1" or "0")
	end
	for _, spur in ipairs(GameConfig.Spurs) do
		table.insert(bits, cash >= spur.price and "1" or "0")
	end
	for _, price in ipairs(GameConfig.Pen.UpgradePrices) do
		table.insert(bits, cash >= price and "1" or "0")
	end
	return table.concat(bits)
end

function ShopController.start(hud)
	build()
	if hud then
		toast = hud.toast
		local rail = hud.railButtons or {}
		local jumps = { Featured = "Gamepass", Speed = "Treadmills", Money = "Ranch" }
		for name, section in pairs(jumps) do
			if rail[name] then
				rail[name].Activated:Connect(function()
					ShopController.open(section)
				end)
			end
		end
		if rail.Index then
			rail.Index.Activated:Connect(function()
				toast("The Beast Index is coming soon!", "info")
			end)
		end
	end
	for _, name in ipairs({ "TreadmillTier", "OwnedSpurs", "EquippedSpur", "PenLevel", "PenSlots" }) do
		player:GetAttributeChangedSignal(name):Connect(updateCards)
	end
	local lastKey = nil
	player:GetAttributeChangedSignal("Cash"):Connect(function()
		local key = affordKey(player:GetAttribute("Cash") or 0)
		if key ~= lastKey then
			lastKey = key
			updateCards()
		end
	end)
	watchPads()
end

return ShopController
