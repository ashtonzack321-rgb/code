# Check-UI skill: source and how it applies here

- Copied unchanged from https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox (commit 52ac1ed, MIT License, by TemporaryLooker22) on 2026-10-20.
- The icon registry is kept for reference at `game/vendor/CheckUI/CheckUIIcons.luau`. The game copies the ids it uses into `GameConfig.Icons`.

**How to use it in Steal a Beast (the user's choice, 2026-10-20):** menus and windows look **exactly like Check-UI**: the slate canvas, coloured headers with damier and 2-tier divider, the [X], `~Section~` titles, gradient cards with sunbursts and the button state triad. The user's reference picture is `Pasted image 20261020172519.png` in the vault root. The HUD keeps Steal An Egg's layout: italic green cash, the left rail of icons with gradient labels, and Speed with a shoe (see `Roblox Research/Concepts/UI Style Guide.md`). Montserrat Black (GothamBlack) everywhere. The code is in `game/src/StarterPlayer/StarterPlayerScripts/Controllers/UI.lua` and `ShopController.lua`.
