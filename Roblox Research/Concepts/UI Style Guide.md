---
tags: [roblox, ui, concept, style]
updated: 2026-10-20
sources: [user screenshots of Steal An Egg (2026-10-20), font renders, web research]
---
# UI Style Guide (Steal An Egg's real look)

How [[Steal An Egg]] actually looks in game, worked out from the user's screenshots on 2026-10-20. [[Steal a Beast - Overview|Steal a Beast]] copies it. The code is in `game/src/StarterPlayer/StarterPlayerScripts/Controllers/UI.lua`.

## Font: Montserrat Black everywhere
- **All UI text uses Montserrat Black (weight 900).** In Roblox that is the **Gotham** family: `Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)`, or `Enum.Font.GothamBlack`. Roblox now draws Gotham with Montserrat.
- **The cash counter uses Montserrat Black *Italic*.** Pass `Enum.FontStyle.Italic` as the third argument to `Font.new`.
- Checked by rendering the real font files next to the screenshots. The slanted 9, 3 and $ of the cash counter only match Montserrat Black Italic, and Fredoka One and Nunito are clearly different. The geometric M and the straight-tailed y in the rail labels match Montserrat Black.

![[font-match-cash.png]]
![[font-match-rail-label.png]]

> [!warning] An older note was wrong
> [[UI Patterns]] used to say the genre uses Fredoka One or Luckiest Guy. Steal An Egg doesn't use either. Its store thumbnail uses Rubik Black, but the in-game UI is Montserrat. Steal a Brainrot's floating names look like Source Sans Bold (fan consensus, medium confidence).

## Text style
- **White text with a thick black outline** (UIStroke about 1/12 of the text height: 3 px on 36 px text, 4 px on big numbers).
- **Coloured text is a white-to-colour gradient**, top to bottom. It's done with a UIGradient (Rotation 90) on a white label, and the black outline stays black.
  - Rail labels: *Featured* yellow→orange, *Speed* white→light cyan, *Money* white→light green, *Stars* white→peach
  - Section titles: `-- FEATURED --` and `-- PASSES --` pale yellow→gold, `-- SPEED --` pale cyan→cyan
- **Highlights inside sentences** are bright green: "Eggs Grow **x2** faster!", "Get **x2** Money!".
- **Cash** is bright green (about RGB 24,255,24), italic, with a black outline and a money-stack icon on its left: `$43,931`. It uses commas, not 43.9K. The store thumbnail shows big values as `$89,121Sp/s` (commas plus a suffix).

## Layout
| Element | Where | Look |
|---|---|---|
| Cash | top left | money-stack icon + green italic number |
| Left rail | left edge, stacked | **icon + label, no button box**: Featured (% price tag), Speed (blue sneaker), Money (cash stack), Stars (smiling star) |
| Speed | bottom left beside a shoe icon (3 guides) | |
| Area / egg name | bottom centre | big yellow-gradient caps, e.g. `HALLOWEEN EGG` |
| Player tags | over heads | round headshot with the username under it |

## Shop window
![[sae-ui-shop.webp]]
- **Header:** a lime-green bar with a light diagonal glass shine and a faint stud pattern. `Shop` sits on the left in white with a thick outline. The close button is a **red square with a white X**.
- **Body:** dark grey (about RGB 58,59,66) with a faint stud pattern. It scrolls through sections: `-- FEATURED --` → `-- PASSES --` → `-- SPEED --` → …
- **Cards (two per row):** a gradient background (rainbow for *x2 Growth*, yellow for *x2 Money*) with a thin dark border. Each has the title on top (`x2 Growth`), a big icon on the left, and a description with green highlights.
- **Card bottom row:** a small **purple gift button** and a wide **lime-green price button** with the Robux icon (`467`, `399`).

## Map look
- Bright **Plastic** colours: lime-green ground, **orange-brown checkered walls** and **purple-grey paths**.
- A **two-tone checkerboard** where every square has classic Roblox **studs**.
- Wooden rail fences with X braces around the pens. Small dark signs (`Upgrade Pen`, `Level 1 > Level 2`, red price `$1M`).
- Our version: `AreasConfig.Style` plus the texture `game/assets/checker_studs.png`, which is mostly see-through so the part colour shows.

![[checker-studs-preview.png]]

## Wording to copy
| Steal An Egg | Steal a Beast |
|---|---|
| `-- FEATURED --` / `-- PASSES --` / `-- SPEED --` | same, plus `-- MONEY --` (pen slots) |
| `x2 Growth`: "Eggs Grow x2 faster!" (467 R$) | `x2 Taming`: "Beasts Tame x2 faster!" (467 R$) |
| `x2 Money`: "Get x2 Money!" (399 R$) | same |
| `A Secret Cosmic Skeleton Boss Egg spawned in Cosmic🌌!` | `A Secret Inferno Mammoth roams Volcano Ridge🌋!` (when herds exist) |
| `ALL EGG RESET!` | `SUNDOWN! ALL HERDS RESTOCKED!` (when Sundown exists) |
| Prompt `Steal Egg` | `Lasso Beast` |

## Screenshots
![[sae-ui-shop-title.png]] ![[sae-ui-left-rail.png]] ![[sae-ui-cash.png]]

## Still to check
- The exact position of the cash counter on the full screen (the crop only shows that it sits over the ground).
- What the Speed counter looks like when you stand on the treadmill, and the `+Speed` popups.
- The floating text over eggs and pets in the pen.
- The notification feed style.

Related: [[UI Patterns]] · [[My Game UI]] · [[Steal An Egg]]
