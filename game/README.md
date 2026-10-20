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
| **General Store** (`ShopService` + shop UI) | Done. 11 treadmill tiers, 10 Spurs, and pen slots up to 19. Opens from the SHOP button or when you step on the yellow ring in Town. |
| **HUD** | Done. Cash and $/s, Speed and the next area's sign, treadmill popups, toasts. |
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
2. **Scripts:** paste `tools/InstallScripts.command.lua`. Wait for `[InstallScripts] 18 scripts installed ...`.
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
2. Your pen has a Prairie Chick with a tag (`$1/s`), and the cash at the top goes up by 1 each second.
3. Step onto the **treadmill** to the right of your gate. You get `+2 SPEED` popups twice a second,
   the Speed panel at the bottom left goes up, and you walk faster.
4. Walk to the **yellow ring** in front of the General Store (Town Square, north side). The shop opens.
   Buy **Rusty Spurs** ($100). Treadmill popups now say `+3 SPEED (x1.5 SPUR)`.

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
      AreasConfig.lua             areas, beasts, rarities, plots (map + gameplay data)
      GameConfig.lua              economy: treadmill tiers, Spurs, pen prices, walk curve, saving
      Economy.lua                 the rules as pure functions (buy, step, income, save repair)
      NumberFormat.lua            1.2K / 4.5M / 3.1B, commas, m:ss
    ServerScriptService/
      Main.server.lua             starts the services
      Services/                   DataService, RanchService, SpeedService, ShopService,
                                  StatsService, DevService, Remotes, MapUtil
    ServerStorage/MapBuilder/     builds workspace.Map (used by tools/BuildMap.command.lua)
    StarterPlayer/StarterPlayerScripts/
      Main.client.lua             starts the UI
      Controllers/                HUDController, ShopController, UI (style helpers)
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
