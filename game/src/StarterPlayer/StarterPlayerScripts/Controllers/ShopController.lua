--[[
	ShopController: the Shop window, built like Steal An Egg's:
	  * green header with a glass shine, "Shop" in white on the left, red square X on the right
	  * dark grey body that scrolls through sections: "-- FEATURED --", "-- PASSES --",
	    "-- SPEED --" (treadmills and Spurs) and "-- MONEY --" (pen slots)
	  * two cards per row: gradient background, title, icon, a description with green
	    highlights, a purple gift button and a lime-green price button
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
local Economy = require(Shared:WaitForChild("Economy"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local ShopRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop")

local UI = require(script.Parent:WaitForChild("UI"))

local ShopController = {}

local player = Players.LocalPlayer
local gui, window, list, uiScale
local sections = {}   -- [name] = header label
local cards = {}      -- { update = function() }
local busy = false
local toast = function() end

local CARD_W, CARD_H = 340, 168

-- Card backgrounds (top colour, bottom colour), matching the screenshot's rainbow and gold cards
local CARD_COLORS = {
	Gold = { Color3.fromRGB(255, 246, 140), Color3.fromRGB(255, 196, 20) },
	Purple = { Color3.fromRGB(226, 160, 255), Color3.fromRGB(150, 60, 230) },
	Blue = { Color3.fromRGB(150, 230, 255), Color3.fromRGB(30, 150, 255) },
	Green = { Color3.fromRGB(190, 255, 140), Color3.fromRGB(70, 200, 40) },
	Grey = { Color3.fromRGB(190, 190, 196), Color3.fromRGB(120, 120, 128) },
}

local function rarityGradient(rarityId)
	local rarity = Economy.Rarities[rarityId]
	local c = rarity and UI.rgb(rarity.color) or Color3.fromRGB(150, 150, 150)
	return { c:Lerp(Color3.new(1, 1, 1), 0.45), c }
end

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

----------------------------------------------------------------------------------------------
-- Building blocks
----------------------------------------------------------------------------------------------
local function sectionHeader(order, text, tint)
	local label = UI.text("-- " .. text .. " --", {
		name = "Section_" .. text,
		size = UDim2.new(1, 0, 0, 50),
		stroke = 3,
		parent = list,
	})
	label.LayoutOrder = order
	UI.tint(label, tint)
	sections[text] = label
	return label
end

local function grid(order)
	return UI.new("Frame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = list,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.new(0, CARD_W, 0, CARD_H),
			CellPadding = UDim2.new(0, 16, 0, 14),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

--[[ A shop card. spec = { title, icon, description (may use <green>), colors = {top, bottom} or
	"Rainbow", gift = bool }. Returns the card and its price button. ]]
local function card(parent, order, spec)
	local frame = UI.new("Frame", {
		Name = spec.title,
		LayoutOrder = order,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = parent,
	}, { UI.corner(4), UI.border(3, UI.Colors.CardBorder) })
	local gradient = UI.new("UIGradient", { Rotation = 90, Parent = frame })
	if spec.colors == "Rainbow" then
		gradient.Color = UI.Rainbow
		gradient.Rotation = 0
		gradient.Transparency = NumberSequence.new(0.1)
	else
		gradient.Color = ColorSequence.new(spec.colors[1], spec.colors[2])
	end
	UI.shine(frame, 0.82)

	UI.icon(spec.icon, { size = UDim2.new(0, 104, 0, 104), position = UDim2.new(0, 10, 0, 14), z = 3, parent = frame })
	UI.text(spec.title, {
		name = "Title",
		size = UDim2.new(0, 214, 0, 32),
		position = UDim2.new(0, 118, 0, 8),
		stroke = 3,
		z = 3,
		parent = frame,
	})
	local description = UI.text(UI.highlight(spec.description or ""), {
		name = "Description",
		rich = true,
		size = UDim2.new(0, 214, 0, 66),
		position = UDim2.new(0, 118, 0, 42),
		stroke = 2.5,
		z = 3,
		parent = frame,
	})
	description.TextWrapped = true

	local priceX = 8
	if spec.gift then
		local gift = UI.button({
			name = "Gift",
			color = UI.Colors.GiftPurple,
			border = UI.Colors.GiftBorder,
			size = UDim2.new(0, 64, 0, 44),
			position = UDim2.new(0, 8, 1, -52),
			dark = true,
			z = 3,
			parent = frame,
		})
		UI.icon(GameConfig.Icons.Gift, { size = UDim2.new(0.6, 0, 0.8, 0), position = UDim2.new(0.2, 0, 0.1, 0), z = 4, parent = gift })
		gift.Activated:Connect(function()
			toast("Gifting is coming soon!", "info")
		end)
		priceX = 80
	end
	local price = UI.priceButton("", spec.robux, {
		size = UDim2.new(1, -(priceX + 8), 0, 44),
		position = UDim2.new(0, priceX, 1, -52),
		parent = frame,
	})
	price.ZIndex = 3
	return frame, price, description
end

-- Sets a price button's text and colour (green = buy, blue = equip, grey = owned/locked).
local function setButton(button, text, kind)
	button.Label.Text = text
	local fills = {
		buy = { UI.Colors.PriceGreen, UI.Colors.PriceBorder },
		equip = { UI.Colors.SpeedBlue, Color3.fromRGB(10, 70, 110) },
		owned = { UI.Colors.Grey, Color3.fromRGB(50, 50, 54) },
		poor = { Color3.fromRGB(230, 70, 60), Color3.fromRGB(110, 10, 10) },
	}
	local fill = fills[kind] or fills.buy
	button.BackgroundColor3 = fill[1]
	button:FindFirstChildOfClass("UIStroke").Color = fill[2]
end

----------------------------------------------------------------------------------------------
-- Sections
----------------------------------------------------------------------------------------------
local function buildPasses(order)
	local g = grid(order)
	for i, pass in ipairs(GameConfig.Passes) do
		local colors = pass.card == "Rainbow" and "Rainbow" or CARD_COLORS[pass.card] or CARD_COLORS.Gold
		local _, price = card(g, i, { title = pass.name, icon = pass.icon, description = pass.description,
			colors = colors, gift = true, robux = true })
		price.Label.Text = NumberFormat.commas(pass.robux)
		price.Activated:Connect(function()
			if pass.gamePassId and pass.gamePassId > 0 then
				MarketplaceService:PromptGamePassPurchase(player, pass.gamePassId)
			else
				toast(pass.name .. " is coming soon!", "info")
			end
		end)
	end
end

local function buildSpeed(order)
	local g = grid(order)
	for i, t in ipairs(GameConfig.Treadmill.Tiers) do
		local _, price, description = card(g, i, {
			title = t.name .. " Treadmill",
			icon = GameConfig.Icons.Treadmill,
			description = "<green>+" .. NumberFormat.short(t.speedPerStep) .. "</green> Speed every step!",
			colors = rarityGradient(t.rarity),
		})
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
			description.Text = UI.highlight("<green>+" .. NumberFormat.short(t.speedPerStep) .. "</green> Speed every step!")
		end)
	end
	local base = #GameConfig.Treadmill.Tiers
	for i, spur in ipairs(GameConfig.Spurs) do
		local _, price = card(g, base + i, {
			title = spur.name,
			icon = GameConfig.Icons.Spurs,
			description = "Treadmill Speed <green>x" .. tostring(spur.multiplier) .. "</green>!",
			colors = rarityGradient(spur.rarity),
		})
		price.Activated:Connect(function()
			local owned = string.find("," .. (player:GetAttribute("OwnedSpurs") or "") .. ",", "," .. spur.id .. ",", 1, true)
			if player:GetAttribute("EquippedSpur") == spur.id then
				ask("EquipSpur", "")
			elseif owned then
				ask("EquipSpur", spur.id)
			else
				ask("BuySpur", spur.id)
			end
		end)
		table.insert(cards, function(cash)
			local owned = string.find("," .. (player:GetAttribute("OwnedSpurs") or "") .. ",", "," .. spur.id .. ",", 1, true)
			if player:GetAttribute("EquippedSpur") == spur.id then
				setButton(price, "Equipped", "owned")
			elseif owned then
				setButton(price, "Equip", "equip")
			else
				setButton(price, NumberFormat.cash(spur.price), cash >= spur.price and "buy" or "poor")
			end
		end)
	end
end

local function buildMoney(order)
	local g = grid(order)
	local _, price, description = card(g, 1, {
		title = "Pen Slot",
		icon = GameConfig.Icons.Pen,
		description = "Room for <green>+1</green> beast!",
		colors = CARD_COLORS.Green,
	})
	price.Activated:Connect(function()
		ask("BuyPenSlot")
	end)
	table.insert(cards, function(cash)
		local level = player:GetAttribute("PenLevel") or 1
		local slots = player:GetAttribute("PenSlots") or GameConfig.Pen.StartSlots
		local cost = GameConfig.Pen.UpgradePrices[level]
		if slots >= GameConfig.Pen.MaxSlots or not cost then
			setButton(price, "Maxed", "owned")
			description.Text = UI.highlight("Your pen is <green>full size</green>!")
		else
			setButton(price, NumberFormat.cash(cost), cash >= cost and "buy" or "poor")
			description.Text = UI.highlight("Room for <green>+1</green> beast! (" .. slots .. " \u{2192} " .. (slots + 1) .. ")")
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
	uiScale = UI.autoScale(gui)

	window = UI.new("Frame", {
		Name = "Window",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 10),
		Size = UDim2.new(0, 780, 0, 580),
		Visible = false,
		Parent = gui,
	})

	-- Header: green glass bar
	local header = UI.new("Frame", {
		Name = "Header",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 72),
		ZIndex = 2,
		Parent = window,
	}, { UI.corner(4), UI.border(3, UI.Colors.HeaderBorder) })
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(UI.Colors.HeaderTop, UI.Colors.HeaderBottom), Parent = header })
	UI.shine(header, 0.75)
	UI.text("Shop", {
		name = "Title",
		align = "Left",
		size = UDim2.new(0, 300, 0, 54),
		position = UDim2.new(0, 18, 0, 9),
		stroke = 4,
		z = 3,
		parent = header,
	})
	local close = UI.closeButton(header)
	close.ZIndex = 4
	close.Activated:Connect(function()
		ShopController.close()
	end)

	-- Body: dark grey, scrolling
	local body = UI.new("Frame", {
		Name = "Body",
		BackgroundColor3 = UI.Colors.Body,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 76),
		Size = UDim2.new(1, 0, 1, -76),
		Parent = window,
	}, { UI.corner(4), UI.border(3, UI.Colors.BodyBorder) })

	list = UI.new("ScrollingFrame", {
		Name = "List",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, -12, 1, -12),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(200, 200, 205),
		Parent = body,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 16) }),
	})

	sectionHeader(1, "FEATURED", UI.Tints.Gold)
	sectionHeader(2, "PASSES", UI.Tints.Gold)
	buildPasses(3)
	sectionHeader(4, "SPEED", UI.Tints.Cyan)
	buildSpeed(5)
	sectionHeader(6, "MONEY", UI.Tints.Green)
	buildMoney(7)
end

-- section: "FEATURED" (top), "SPEED" or "MONEY"
function ShopController.open(section)
	window.Visible = true
	updateCards()
	local header = sections[section or "FEATURED"]
	if header then
		task.defer(function()
			local scale = uiScale and uiScale.Scale or 1
			local y = (header.AbsolutePosition.Y - list.AbsolutePosition.Y) / scale + list.CanvasPosition.Y
			list.CanvasPosition = Vector2.new(0, math.max(0, y - 6))
		end)
	end
	local scale = window:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = window })
	scale.Scale = 0.85
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
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
			ShopController.open("FEATURED")
		end
		wasOn = on
	end)
end

function ShopController.start(hud)
	build()
	if hud then
		toast = hud.toast
		local rail = hud.railButtons or {}
		if rail.Featured then
			rail.Featured.Activated:Connect(function()
				ShopController.toggle("FEATURED")
			end)
		end
		if rail.Speed then
			rail.Speed.Activated:Connect(function()
				ShopController.open("SPEED")
			end)
		end
		if rail.Money then
			rail.Money.Activated:Connect(function()
				ShopController.open("MONEY")
			end)
		end
		if rail.Index then
			rail.Index.Activated:Connect(function()
				toast("The Beast Index is coming soon!", "info")
			end)
		end
	end
	for _, name in ipairs({ "Cash", "TreadmillTier", "OwnedSpurs", "EquippedSpur", "PenLevel", "PenSlots" }) do
		player:GetAttributeChangedSignal(name):Connect(updateCards)
	end
	watchPads()
end

return ShopController
