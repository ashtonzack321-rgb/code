---
tags: [progress, log]
updated: 2026-10-18
---
# Progress Log

## 2026-10-18 (Session 1)
**Done**
- Researched the 3 games: [[Steal a Brainrot]], [[Steal An Egg]] (a full deep dive from 294 sources) and [[Break and Steal an Egg]].
- Designed **Steal a Beast v2**, copying Steal An Egg's lane of areas: [[Steal a Beast - Overview]], [[Core Loop]], [[Areas and Beasts]], [[My Game UI]], [[Systems and Scripts]], [[Monetization and Launch]].
- Built the **clickable UI mockup** (9 screens): https://claude.ai/artifact/4ziAJWGDzwJTSY8KVuADkz. A source copy is in `My Game/UI Mockup/`.
- Wrote the **map design**: [[Map Layout]] (plain words) and `game/MAP_SPEC.md` (exact build spec).
- Set up Obsidian ⇄ GitHub sync, and Claude Code on the PC with the **Roblox_Studio MCP connected**.

**In progress (when you went to bed)**
- The Roblox **map builder** in `game/`: Rojo project, `AreasConfig`, `MapBuilder`, the paste-into-Command-Bar script `game/tools/BuildMap.command.lua`, tests and a top-down preview image. Claude pushes it to GitHub once its tests pass.

**Next steps**
1. On the PC: `git pull` (or Obsidian → Git: Pull).
2. Open Roblox Studio (a Baseplate is fine). In PowerShell in the `code` folder, run `claude`, then say:
   > Read game/README.md and build the map in my open Studio place.
3. Walk the map in Studio and note anything that doesn't feel like Steal An Egg.
4. Then build the gameplay in this order (see [[Systems and Scripts]]): treadmill and Speed → herds and lasso and tow and Alpha chase → whip and traps → taming and rustling → Sundown and rare spawns → UI → shop.

**To decide**
- Your PC Claude merged the gamepass tables and kept 3 old v1 passes in [[Monetization and Launch]]: **Auto-Tug**, **Fast Horse** and **Extra Guard Slot**. In v2 the tug-of-war minigame and guard beasts no longer exist, so Auto-Tug and Extra Guard Slot don't fit any more. Fast Horse could still work with mounts. Keep, change or delete them.

**Notes**
- If Obsidian shows a merge conflict, keep the **GitHub (origin/main)** version of notes Claude wrote, unless you typed something yourself.
