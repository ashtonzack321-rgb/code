---
name: check-ui-clean-roblox
description: Build polished, tactile, responsive simulator and cartoon interfaces in Roblox or Roblox-themed mockups. Apply strong outlines, clear depth, deliberate palettes, centered interactions, and device-aware sizing while adapting to an established game's visual identity.
---

# Check-UI Clean Roblox

Use this skill when creating or restyling Roblox simulator UI. The source inspiration is the MIT-licensed [Check-UI-Clean-Roblox repository](https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox).

## Design goals

- Give each screen a clear hierarchy, strong contrast, and tactile depth.
- Use a solid, intentional canvas for modal windows, dark outer strokes, a distinct header, and a two-tier divider.
- Build buttons with a readable gradient, dark outline, visible lower bevel, optical highlight, and clear hover/press feedback.
- Preserve an established game's palette, theme, and typography. Treat the reference palette and five simulator menus as examples, not requirements that override the game.
- Keep icons proportional (`ScaleType.Fit`) and text legible with a strong outline.
- Use centered scaling for interactive feedback and responsive sizing based on the viewport. The reference uses a 1050 x 620 baseline, clamped from 0.52 to 1.18.
- Respect touch targets and safe areas on phones and console screens.

## Reference tokens

- Slate modal canvas `#3B5866`; dark outer stroke `#181E22`; recessed card `#1A2C34`.
- Buy/claim/redeem: lime gradient with dark green bevel.
- Disabled/claimed: silver gradient with slate bevel.
- Locked: crimson gradient with burgundy bevel.
- Skip: amber gradient with dark orange bevel.
- Checkerboard overlay `rbxassetid://385956923`; use a vertical transparency fade and avoid hard cutoffs.
- Optional sunburst `rbxassetid://130563114903838`, rotating only while its menu is visible.

## Roblox implementation guidance

- Use `Enum.Font.GothamBlack` with an appropriately sized dark `UIStroke` when matching the stock Check-UI look. Retain the game's established font when its art direction calls for one.
- Standard windows use a fully opaque canvas, dark border, rounded corners, a 60px themed header, a thematic dark divider and a black lower divider.
- The close control is a compact square red face over a burgundy bottom bevel, with a dark outline and centered scale animation.
- Standard buttons use a dark 3px border, vertical gradient, subtle checkerboard fade, three inset highlight strokes, bold outlined text, and a 3px dark bottom extrusion. Keep iconless action buttons square-cornered when following the canonical component.
- Anchor interactive controls at `(0.5, 0.5)` and animate a child `UIScale` (hover about 1.05–1.06, press about 0.94).
- Recalculate window `UIScale` when `CurrentCamera.ViewportSize` changes; clamp to `[0.52, 1.18]` around `1050 x 620`.
- Use only verified asset IDs from the reference; do not assume the bundled icon registry exists unless its modules have been installed.

## Adaptation checklist

1. Inspect the project's existing screen hierarchy, scripts, interaction contracts, and design language.
2. Reuse its labels, gameplay states, palette, and controls. Do not replace the game's identity with sample menus.
3. Apply consistent framing, header dividers, button depth, outlined text, and centered interactions.
4. Keep layouts usable on phone, tablet, desktop, and console; preserve safe-area spacing.
5. If the project is a web/HTML visual mockup rather than a Roblox place, translate the visual rules into CSS and clearly distinguish that artifact from an in-game change.
6. Verify the actual target project and inspect the result in context before reporting completion.

