---
tags: [roblox, ui, design-system, skill]
updated: 2026-10-20
source: https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox
---
# Check-UI Clean Roblox

Design guidance for polished, tactile, responsive simulator and cartoon interfaces in Roblox. Adapt the techniques to the game's established visual identity instead of replacing its palette or theme.

Source inspiration: [Check-UI-Clean-Roblox](https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox) (MIT licensed).

## Design goals

- Give each screen a clear hierarchy, strong contrast, and tactile depth.
- Use solid, intentional modal canvases, dark outer strokes, distinct headers, and two-tier header dividers.
- Build buttons with readable gradients, dark outlines, visible lower bevels, optical highlights, and clear hover/press feedback.
- Preserve an established game's palette, theme, typography, labels, and interactions. Treat the reference palette and five simulator menus as examples, not requirements.
- Keep icons proportional (`ScaleType.Fit`) and text legible with strong outlines.
- Use centered scaling for interaction feedback and responsive sizing based on the viewport. The reference uses a 1050 × 620 baseline, clamped from 0.52 to 1.18.
- Respect touch targets and safe areas on phones and console screens.

## Reference tokens

| Element | Reference |
|---|---|
| Slate modal canvas | `#3B5866` |
| Dark outer stroke | `#181E22` |
| Recessed card | `#1A2C34` |
| Buy, claim, redeem | Lime gradient with dark green bevel |
| Disabled, claimed | Silver gradient with slate bevel |
| Locked | Crimson gradient with burgundy bevel |
| Skip | Amber gradient with dark orange bevel |
| Checkerboard overlay | `rbxassetid://385956923`, vertically faded |
| Optional sunburst | `rbxassetid://130563114903838`, rotate only while its menu is visible |

## Roblox implementation

- Use `Enum.Font.GothamBlack` with an appropriately sized dark `UIStroke` when matching the stock Check-UI look. Retain the game's established font when the art direction calls for one.
- Standard windows use a fully opaque canvas, dark border, rounded corners, a 60px themed header, a thematic dark divider, and a black lower divider.
- The close control is a compact square red face over a burgundy bottom bevel, with a dark outline and centered scale animation.
- Standard buttons use a dark 3px border, vertical gradient, subtle checkerboard fade, three inset highlight strokes, bold outlined text, and a 3px dark bottom extrusion. Keep iconless action buttons square-cornered when following the canonical component.
- Anchor interactive controls at `(0.5, 0.5)` and animate a child `UIScale` (hover about 1.05–1.06, press about 0.94).
- Recalculate window `UIScale` when `CurrentCamera.ViewportSize` changes; clamp to `[0.52, 1.18]` around `1050 × 620`.
- Use only verified asset IDs from the reference. Do not assume the bundled icon registry exists unless its modules have been installed.

## Adaptation checklist

1. Inspect the project's screen hierarchy, scripts, interaction contracts, and design language.
2. Reuse its labels, gameplay states, palette, and controls. Do not replace the game's identity with sample menus.
3. Apply consistent framing, header dividers, button depth, outlined text, and centered interactions.
4. Keep layouts usable on phone, tablet, desktop, and console; preserve safe-area spacing.
5. If the project is a web/HTML visual mockup rather than a Roblox place, translate the visual rules into CSS and distinguish that artifact from an in-game change.
6. Verify the actual target project and inspect the result in context before reporting completion.

## Connection to this vault

The current game's visual direction is documented in [[My Game UI]] and the screen references live in [[UI Mockup]]. This system should add clarity and responsive behavior while retaining the Wild West wood, rope, sunset, and rarity colors already specified there.

The active Codex skill copy is stored at `.agents/skills/check-ui-clean-roblox/SKILL.md` in the vault workspace.
