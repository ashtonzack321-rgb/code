---
tags: [my-game, gdd, ui]
updated: 2026-10-18
---
# UI Design (v2)

The style follows [[UI Patterns]] and the three reference games: **Luckiest Guy** for titles and numbers, **Fredoka** for labels, a 3–5 px black outline on all text, saturated gradients, chunky buttons with a bottom shadow, red notification dots and huge suffixed numbers (K, M, B, T, Qa). **Theme: Wild West.** Panels are wood-brown, the sky is sunset orange and blue, and rope borders frame the UI. Rarity colours come from [[Areas and Beasts]].

## HUD (always on screen)
```
┌──────────────────────────────────────────────────────────┐
│ [🛒Shop]        💰 $4.2B  (+$12.5M/s)         [🎁][⚙]    │
│ [📖Index]       ☀ 3:12 until SUNDOWN                     │
│ [⭐Spurs]                                    ┌─TAMING──┐  │
│ [💎Passes]   🌈 A SECRET Inferno Mammoth     │Bison 0:42│  │
│                 roams Volcano Ridge!        │Wyrm 21:10│  │
│                                             │[TAME ALL]│  │
│                  (3D world)                  └─────────┘  │
│ 👢 SPEED 1.2M                       [🪤 x3] [WHIP]        │
└──────────────────────────────────────────────────────────┘
```
- **Speed** in the bottom-left with a boot icon (Steal An Egg puts it there).
- **Cash** in the top centre with $/s under it, plus a coin-fly animation and a "+$" pop-up.
- **Sundown timer** under the cash. It flashes orange for the last 10 s.
- **Left rail:** Shop, Index (red dot when there's something to claim), Spurs, Passes.
- **Taming panel** on the right: a countdown per beast and a **TAME ALL** button (Robux).
- **Rare-spawn banner:** slides in from the top. It's rainbow for Secret, pink for Eternal and white-gold for Divine.

## World UI
- **Area sign** at each entrance: a wooden board with the area name and **"⚡ 10K SPEED"**, shown green if you have enough and red if not.
- **Beast tag** above each wild beast: name, rarity in its colour, **weight kg**, mutation and $/s.
- **Lasso prompt:** "HOLD E · LASSO" with a ring that fills (rarer beasts take longer).
- **Alpha:** "zzZ" bubble while asleep. When it wakes, red eyes, a "!" and its name tag turns red.

## Towing state
- A rope from the player to the beast.
- A top bar reading **"TOWING Thunder Bison · 412 kg · SPEED −30%"**.
- A distance meter, **"TOWN 85m"**, with an arrow.
- A red danger edge on the screen while the Alpha chases.
- **DROP (Q)** and **TRAP** buttons.

## Ranch screen
- A grid of pen slots. Each slot shows a beast, a **taming countdown** (or "TAME!" when ready) and its $/s once tamed.
- **Equip Best**, **+1 SLOT**, **TAME ALL**.
- **Gate lock** button with a timer and cooldown.
- **Rustler alert:** a red banner ("⚠ BOB_YT IS RUSTLING YOUR CANYON WYRM!") with an arrow pointing at the rustler.

## Tamed reveal
A full-screen burst in the rarity colour, **"TAMED!"**, the beast with its weight and mutation, and a big $/s figure. Buttons: **Place** and **Index**. The first time you tame a species you also get **"+420 SPEED"**.

## Shop
Tabs: **Treadmills · Spurs · Ranch · Gear · Robux**. Cards have rarity-coloured borders and a "BEST VALUE" ribbon. Robux prices are shown in green with "R$".

## Index
Area tabs with **8 silhouettes each**. Each found beast has a **CLAIM** button (+Speed and cash), **CLAIM ALL**, and an area-completion reward (a weapon).

## Thumbnail
A bacon-hair cowboy towing a giant glowing **Inferno Mammoth** while a red-eyed **Alpha** charges behind. **"$8,000,000/s"** in huge outlined green text, a rainbow **"SECRET"**, a red arrow and a sunset sky.

## Clickable mockup
**[Open the Steal a Beast UI mockup](https://claude.ai/artifact/4ziAJWGDzwJTSY8KVuADkz)**. It has screens for the area map, Town HUD, lassoing a beast, the chase home, the ranch, the tamed reveal, the shop, the Index and the thumbnail. Press Play on a screen to click through it.

Related: [[Core Loop]] · [[Systems and Scripts]]
