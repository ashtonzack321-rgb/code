# Steal a Beast: the Roblox game

The game from the vault notes (`Roblox Research/My Game/`), written in Luau as a Rojo project.
The map follows `MAP_SPEC.md`. The rules follow `Core Loop.md` and `Systems and Scripts.md`.

## What works so far

| Part | Status |
|---|---|
| **Map**: Town, 7 ranch plots, the 10-area lane | Done. Built once in Studio by `tools/BuildMap.command.lua`. |
| **Saving** (`DataService`) | Done. DataStore with a session lock, autosave, save on leave and on shutdown. |
| **Ranch** (`RanchService`) | Done. You get a random free plot with your name and headshot on the sign, you spawn there, the pen shows your beasts with name tags, and the pen earns $/s. |
| **Treadmill + Speed** (`SpeedService`) | Done. Stand on your own treadmill belt to train (AFK works). Speed sets your WalkSpeed using the MAP_SPEC §2 curve. |
| **Shop** (`ShopService` + shop UI) | Done. Built like Steal An Egg's: sections `-- PASSES --`, `-- SPEED --` (11 treadmills, 10 Spurs), `-- MONEY --` (pen slots up to 19). Opens from the left rail or the yellow ring in Town. Gamepasses say "Coming soon!" until their ids are set in `GameConfig.Passes`. |
| **HUD** | Done, in Steal An Egg's style: green italic cash with a money stack, a left rail (Featured, Speed, Money, Index), Speed with a shoe at the bottom left, `+2 Speed` popups, toasts, and the area name in yellow when you enter an area. |
| **Look** | Steal An Egg's: Montserrat Black (Roblox's Gotham) with black outlines everywhere, headshot name tags over players, X-brace pen fences, an Upgrade Pen sign, and a bright studded checkerboard map. Icons, 3D buttons and the checker texture come from the Check-UI kit, already uploaded, so nothing to upload. |
| Herds, lasso, tow, Alpha chase | Next (build order step 3). |
| Whip, traps, taming, rustling, Sundown, Index, Breeding | Later (steps 4–6). |

New players start with $100 and a tamed Prairie Chick (+$1/s), so the pen pays from the first second.
Until herds exist, the only way to get more beasts is the Studio dev commands below.

## Install it in Roblox Studio (on the PC)

**One-time setup:** add the Roblox Studio MCP to Claude Code for *all* folders (user scope):

```
claude mcp add --scope user --transport stdio Roblox_Studio -- "cmd.exe" "/c" "cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat"
```

Then, in PowerShell in the `code` folder: `git pull`, open the place in Studio, run `claude` and say:

> Read game/README.md, then build the map and install the scripts in my open Studio place.

Or do it by hand. Each step pastes a file into **View → Command Bar** and presses Enter:

1. **Map:** paste `tools/BuildMap.command.lua`. Wait for `[MapBuilder] Built workspace.Map ...`.
   Skip this if the place already has `workspace.Map` and the map hasn't changed.
2. **Scripts:** paste `tools/InstallScripts.command.lua`. Wait for `[InstallScripts] 20 scripts installed ...`.
   It creates or updates every script under ReplicatedStorage, ServerScriptService, ServerStorage and
   StarterPlayerScripts. Run it again after every `git pull`.
3. **Save** the place (Ctrl+S).
4. To test saving in Studio: **Game Settings → Security → Enable Studio Access to API Services**
   (the place must be published). Without it, you play on an unsaved session and the Output says so.

**For Claude with the Studio MCP:** both files are self-contained Lua. Run each file's full contents as
one Studio command (map first). Don't edit the generated files. Edit `src/`, then run `npm run build`.

**Rojo** also works: `rojo serve` in `game/` uses `default.project.json`. The map is still built from
the Command Bar, because it is static geometry, not a script.

## Playtest checklist

1. Press **Play**. You spawn on the boardwalk in front of a ranch whose sign shows your name.
2. Your pen has a Prairie Chick with a tag (`$1/s`), and the green cash at the top left goes up by 1 each second.
3. Step onto the **treadmill** to the right of your gate. You get `+2 Speed` popups twice a second,
   the Speed number by the shoe at the bottom left goes up, and you walk faster.
4. Click **Speed** on the left rail (or walk onto the **yellow ring** in front of the General Store). The shop opens.
   Buy **Rusty Spurs** ($100). Treadmill popups now say `+3 Speed (x1.5)`.
5. Walk past the red line into the lane. `DUSTY PRAIRIE` shows in big yellow letters.

### The studded checkerboard

Steal An Egg's map is bright Plastic with a two-tone checkerboard and a stud on every stud. The map
builder does all of it, with **nothing to upload**:
- the colours and **Studs** surfaces
- a checker Texture on every ground and wall face. It uses the Check-UI kit's already-uploaded 2×2 checker
  tile (`rbxassetid://385956923`), drawn black at 85% see-through, so every other 4×4-stud square is a
  shade darker.

If the studs don't show in your Studio, swap in our own tile, which has the studs drawn on:
1. Publish the place, then **View → Asset Manager → Bulk Import** and pick `game/assets/checker_studs.png`.
2. Right-click it in **Images**, then choose **Copy ID to Clipboard**.
3. In the Command Bar: `workspace:SetAttribute("CheckerTexture", "rbxassetid://<your id>")`
4. Run `tools/BuildMap.command.lua` again and save. The id stays in the place.

Colours live in `AreasConfig.Style`. The tile's source is `tools/make_checker_texture.py`.

### Check-UI (icons and components)

The UI uses the MIT-licensed **Check-UI** kit by TemporaryLooker22
(https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox):
- its icons, already uploaded to Roblox, listed in `GameConfig.Icons` with an emoji fallback for any image that fails to load
- its 3D buy and close buttons, checker overlays and rotating sunbursts, in `Controllers/UI.lua`
- its skill, installed at `.claude/skills/check-ui-clean-roblox/` (Claude Code uses it automatically)

The full icon list (1,022 icons) is in `vendor/CheckUI/CheckUIIcons.luau`. Where Check-UI and Steal
An Egg disagree, Steal An Egg wins (see `.claude/skills/check-ui-clean-roblox/SOURCE.md`).

### Dev commands (Studio only)

While playing, switch to the server view (**Test → Current: Client** toggles to **Server**), then run these in the Command Bar:

```lua
game.ServerStorage.DevCommands:Invoke("cash", 1e9)                         -- +$1B for every player
game.ServerStorage.DevCommands:Invoke("speed", 10000)                      -- +10K Speed
game.ServerStorage.DevCommands:Invoke("beast", "GoldenGoose", 12, "Golden") -- id, kg, mutation
game.ServerStorage.DevCommands:Invoke("reset")                             -- fresh save
```

Add a player name as the last argument to change only that player. Beast ids are in
`src/ReplicatedStorage/Shared/AreasConfig.lua`. Mutations are `None`, `Silver`, `Golden` and `Rainbow`.

## Layout

```
game/
  default.project.json            Rojo project
  MAP_SPEC.md                     exact map build spec
  src/
    ReplicatedStorage/Shared/
      AreasConfig.lua             areas, beasts, rarities, plots, map Style (map + gameplay data)
      GameConfig.lua              economy: treadmill tiers, Spurs, pen prices, passes, icons, saving
      Economy.lua                 the rules as pure functions (buy, step, income, save repair)
      NumberFormat.lua            1.2K / 4.5M / 3.1B, commas, m:ss
    ServerScriptService/
      Main.server.lua             starts the services
      Services/                   DataService, RanchService, SpeedService, ShopService,
                                  StatsService, NameTagService, DevService, Remotes, MapUtil
    ServerStorage/MapBuilder/     builds workspace.Map (used by tools/BuildMap.command.lua)
    StarterPlayer/StarterPlayerScripts/
      Main.client.lua             starts the UI
      Controllers/                HUDController, ShopController, UI (the Steal An Egg style kit)
  assets/checker_studs.png        optional studded checker tile (made by tools/make_checker_texture.py)
  vendor/CheckUI/                 Check-UI's icon registry and theme, for reference (MIT)
  tools/
    BuildMap.command.lua          GENERATED: paste to build the map
    InstallScripts.command.lua    GENERATED: paste to install all scripts
    build_command_bar.js, build_install.js
  tests/                          Lua tests (fengari + a strict Roblox mock)
```

## How the code fits together

- **The server decides everything.** The client only sends shop requests (`Remotes.Shop`). Treadmill
  steps are detected on the server from your position, so there is no "step" remote to spam.
- Services share one save table per player (`DataService.get`). After changing it they call
  `DataService.changed(player)`. `StatsService` then copies it to **player attributes** (`Cash`, `Speed`,
  `Income`, `TreadmillTier`, `OwnedSpurs` …) and `leaderstats`, and the client UI reads those.
- All rules live in `Shared/Economy.lua` as pure functions, so `tests/economy_tests.lua` tests them
  without Roblox. `GameConfig.lua` holds the tuning numbers.

## Developing (cloud or PC)

```
cd game
npm install
npm test        # rebuilds both generated files, then runs every test
```

The tests:
- syntax-check every `.lua` file
- check both generated files are current
- build the whole map twice against a strict Roblox mock
- test the economy rules
- if `luau-compile` is on PATH, or `LUAU_BIN` points at its folder, compile every file with the real
  Luau compiler (download it from https://github.com/luau-lang/luau/releases)

Files under `src/ServerScriptService` and `src/StarterPlayer` only run in Roblox, so they may use
`task.*`, `typeof` and `math.clamp`. Everything else must stay valid Lua 5.3 too, because the tests
run it.
