# Vendored: Check-UI (MIT)

From https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox (commit 52ac1ed), MIT License, by TemporaryLooker22.
Kept here unchanged for reference, and not synced into the game:

- `CheckUIIcons.luau`: the registry of 1,022 icons already uploaded to Roblox (`rbxassetid://...`). The
  game copies only the ids it uses into `src/ReplicatedStorage/Shared/GameConfig.lua` (`GameConfig.Icons`).
  To find another icon, search this file (for example `grep -n Shoe vendor/CheckUI/CheckUIIcons.luau`).
- `CheckUITheme.luau`: Check-UI's colour tokens and asset ids (checker texture 385956923, sunburst
  130563114903838, Robux 132185731364109). Our versions live in `Controllers/UI.lua`.

The skill itself is installed at `.claude/skills/check-ui-clean-roblox/`.
