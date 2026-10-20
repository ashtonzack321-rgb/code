---
tags: [roblox, ui, concept]
---
# UI Patterns

The genre's UI aims for **mobile-first, readable at a glance and loud**. Over 70% of Roblox players are on phones or tablets.

## HUD layout
```
┌───────────────────────────────────────────┐
│ [Rebirth] [Shop]   💰 $1.2Qa (+$89K/s)   [⚙]│
│ [Index]                         [Speed 450]│
│ [Gifts]                                    │
│                                            │
│            (3D world)                      │
│                                            │
│ [Lock Base 0:42]          [Sprint] [Jump]  │
└───────────────────────────────────────────┘
```
- **Left sidebar:** a vertical stack of square icon buttons (Shop, Rebirth, Index, Gamepasses, Daily gift), each with a red notification dot.
- **Top centre or top left:** currency in a heavy font with a thick black stroke. Steal An Egg uses **Montserrat Black Italic** in bright green (see [[UI Style Guide]]); the old claim here of "Fredoka One or Luckiest Guy" was not supported by any source.
- **Bottom:** context buttons (Lock base, Hatch, Sell) sized for thumbs.

## World UI (BillboardGui)
- Above each unit: name, rarity label in rarity colour (rainbow gradient for Secret), $/s and price.
- Above each base: the owner's name and avatar, plus a lock countdown.
- Biome gates: "Requires 500 Speed" in red or green.

## Popups and feedback
- **Hatch or reveal:** the egg shakes, cracks, a flash in the rarity colour fills the screen, the pet spins in, then you choose "Equip/Place".
- **Theft alert:** red screen-edge flash, "X IS STEALING YOUR <unit>!" and an arrow pointing at the thief.
- **Numbers:** floating "+$12,400" pops, coins flying toward the HUD counter, and TweenService bounce (Back easing) on every change.
- **Shop:** grid cards with a rarity-coloured border, Robux price shown in green, and the best-value item labelled "BEST VALUE" or "-50%".

## Style rules
- Saturated gradients (UIGradient), thick UIStroke (2–4px black), UICorner 8–16px.
- Every button has hover and press scale tweens (1.0 → 1.08 → 0.95) and a click sound.
- Use the rarity colour ladder consistently: grey, green, blue, purple, gold, red, rainbow.
- Use UIScale or UIAspectRatioConstraint so the same layout works on phone and PC.

Related: [[UI Style Guide]] (Steal An Egg's exact fonts and colours) · [[Technical Architecture]] · [[Monetization]]
