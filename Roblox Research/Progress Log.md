---
tags: [progress, log]
updated: 2026-10-20
---
# Progress Log

## 2026-10-20 (Session 2, part 2): Steal An Egg look
**Done**
- Your screenshots settled the font: **Montserrat Black** everywhere, which Roblox ships as Gotham. The cash counter uses **Montserrat Black Italic**. Both were checked by rendering the real font files next to your screenshots. Details are in [[UI Style Guide]].
- **New UI in Steal An Egg's style:**
  - green italic `$43,931`-style cash with a money stack
  - a left rail of icon buttons with gradient labels (Featured / Speed / Money / Index)
  - Speed with a shoe at the bottom left
  - `+2 Speed` popups and yellow area-name banners
  - headshot name tags over players
- **New Shop**, like theirs: a green header with `Shop` and a red X, a dark scrolling body with `-- PASSES --`, `-- SPEED --` and `-- MONEY --` sections, gradient cards, purple gift buttons and lime price buttons.
- **The map is now bright studded Plastic:** green ground, orange walls and purple-grey paths. The checkerboard texture is drawn (`game/assets/checker_studs.png`); you upload it once.
- All signs and beast tags now use the same font, in white with black outlines.

- Copied more from your Steal An Egg screenshots:
  - X-brace wooden pen fences
  - an **Upgrade Pen** sign with an E prompt at every ranch
  - pet labels: rarity on top, the name in the mutation's colour, green `$11/s`
  - `+$11` floating off every beast each second
- Added the **Check-UI kit** you linked (MIT). It's installed as a skill, and the game uses its icons, which are already uploaded to Roblox, plus its 3D buttons, beveled X, checker overlays and sunbursts. Its checker texture now gives the map its checkerboard, so **nothing needs uploading**. See [[UI Style Guide]].

**Next steps**
1. On the PC: `git pull`, then have Claude rebuild the map and reinstall the scripts. That's the same prompt as before.
2. Press Play and check the look. If an icon shows as an emoji, that image didn't load. Tell me which one.
3. Send screenshots of anything that still looks different from Steal An Egg.
4. Then build herds, lasso and the Alpha chase.

## 2026-10-20 (Session 2)
**Done**
- Finished the **map builder** (all 38 map tests pass) and wrote `game/README.md`, which has the install steps, a playtest checklist and dev commands.
- Built **step 1–2 of the game** (see [[Systems and Scripts]]): a playable idle tycoon with treadmill training.
  - **Saving:** DataStore with a session lock, autosave and a save on leave.
  - **Ranch:** you get a random plot with your name and headshot, spawn at it, and see your pen beasts with name tags; the pen pays $/s. You start with $100 and a tamed Prairie Chick.
  - **Treadmill:** stand on your belt (AFK works) for +Speed. Speed makes you walk faster (the MAP_SPEC curve).
  - **General Store:** 11 treadmill tiers (Wooden +2 … Astral +3K/step), 10 Spurs (1.5x … 20x) and pen slots up to 19. It opens from the SHOP button or the yellow ring in Town.
  - **HUD:** cash and $/s, Speed and the next area, `+SPEED` popups and toasts.
- New one-paste installer `game/tools/InstallScripts.command.lua` puts every script into Studio (no Rojo needed).
- 81 automated tests pass, and every file compiles with the real Luau compiler.

**Next steps**
1. On the PC: run the Roblox MCP command from `game/README.md` once with `--scope user`. Your first try saved it only for the `C:\WINDOWS\System32` folder.
2. `git pull`, open Studio, run `claude` in the `code` folder and say:
   > Read game/README.md, then build the map and install the scripts in my open Studio place.
3. Press Play and follow the **Playtest checklist** in `game/README.md`. Note anything that's broken or feels off.
4. Next to build: **herds, lasso, tow and Alpha chase** (step 3, the core fun).

**To decide** (still open)
- The leftover v1 gamepasses (Auto-Tug, Extra Guard Slot, Fast Horse); see Session 1 below.
- Economy numbers are first guesses (`game/src/ReplicatedStorage/Shared/GameConfig.lua`). Treadmill and Spur prices copy Steal An Egg; pen prices and the starter beast are ours.


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
