# Check-UI skill: source and how it applies here

- Copied unchanged from https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox (commit 52ac1ed, MIT License, by TemporaryLooker22) on 2026-10-20.
- The icon registry is kept for reference at `game/vendor/CheckUI/CheckUIIcons.luau`. The game copies the ids it uses into `GameConfig.Icons`.

**How to use it in Steal a Beast:** use Check-UI's components, asset ids and icons:
- the 3D beveled buttons, the [X] close button, damier (checkerboard) overlays, sunbursts and the button state triad
- the icons in CheckUIIcons
- the checker texture rbxassetid://385956923

Where Check-UI's colours differ from Steal An Egg's real UI, **Steal An Egg wins**. That covers Montserrat Black italic cash, the green shop header, the dark grey body and the left rail of icons with gradient labels. See `Roblox Research/Concepts/UI Style Guide.md`. The style kit in code is `game/src/StarterPlayer/StarterPlayerScripts/Controllers/UI.lua`.
