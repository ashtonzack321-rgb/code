# Steal a Beast: Map Spec v1

Build spec for the whole static map: Town, 7 ranch plots and the 10-area lane. The map copies Steal An Egg's (SAE) layout and re-themes it from Wild West to fantasy. Implement it exactly as written. Gameplay rules live in the vault notes (`Roblox Research/My Game/Core Loop.md`, `Areas and Beasts.md`, `Systems and Scripts.md`). The plain-words summary is `Roblox Research/My Game/Map Layout.md`.

Tags used in this document:
- **[SAE]**: copied from the Steal An Egg research (`sae_spec.json` plus the 2026-10-18 map research).
- **[GDD]**: comes from our own design notes.
- **[assumed]**: SAE's version is undocumented, so this is our choice.

---

## 0. Conventions

| Item | Rule |
|---|---|
| Units | Studs |
| Axes | **Y is up.** Ground top surface is **Y = 0** everywhere outside the plots. The **origin (0, 0, 0)** is the centre of Town Square, where the SpawnLocation sits. **The lane runs toward +X.** |
| North / South | North = **+Z**, South = **−Z**. A player running out (facing +X) has **+Z on their right** and **−Z on their left**. |
| Positions | `@(x, y, z)` is the **part centre**. Size is `(X, Y, Z)`. |
| Defaults | Every part is `Anchored = true` and `CanCollide = true`. **nc** means `CanCollide = false`. **invisible** means `Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false`. Trigger and zone volumes are invisible but keep `CanQuery = true`. |
| Decor flags | Decor parts get `CanTouch = false` and `CanQuery = false`. Parts under 3 studs also get `CastShadow = false`. |
| Colours | `r,g,b` means `Color3.fromRGB(r, g, b)`. Materials are `Enum.Material` names. |

**Shape shorthand** (all built from simple parts, no meshes):

| Shorthand | Meaning |
|---|---|
| `Block x×y×z` | `Part`, Shape Block |
| `Ball d` | `Part`, Shape Ball, Size (d, d, d) |
| `VCyl h×d` | `Part`, Shape Cylinder, Size (h, d, d), rotated `CFrame.Angles(0, 0, math.rad(90))` so the axis is **vertical**. Height h, diameter d. |
| `HCylX len×d` | Cylinder, Size (len, d, d), no rotation. The axis runs along **X**. |
| `HCylZ len×d` | Cylinder, Size (len, d, d), rotated Y 90°. The axis runs along **Z**. |
| `Wedge x×y×z` | `WedgePart`. Its slope runs from the low edge at local **−Z** up to the high edge at **+Z**, so the sloped face points toward the LookVector. `rotY 180` flips it. **Check one wedge in Studio first. If the default slope points the other way, add 180° to every wedge yaw in this spec.** |
| `rotX/rotY/rotZ n` | Extra part rotation in degrees, applied after the offset. |
| `T0.3` / `Refl0.2` | Transparency / Reflectance |

**Props** use prop-local offsets: `partCF = CFrame.new(px, 0, pz) * CFrame.Angles(0, yaw, 0) * CFrame.new(offset) * partRotation`. Here `(px, pz)` is the prop's origin on the ground.

---

## 1. Layout at a glance

```
TOWN (top-down, X → right, Z ↑)                                                    LANE →
Z=+129 +=================================================================================+
       | TOWN SQUARE  X -96..64     | RANCH ROW  X 64..400                              |
       | [Clock]  [GENERAL STORE]   | [ P1 ]   [ P2 ]   [ P3 ]   [ P4 ]   :             |
       |          (SHOP ring)  [ev] | [pen ]   [pen ]   [pen ]   [pen ]   :  gate       |
Z=+40  |                            |   ⌂ T      ⌂ T      ⌂ T      ⌂ T    :  plaza      |
Z=+24  | [INDEX]       SPAWN        |=============== MAIN STREET (Safe Zone) ===========|RED   X=432        X=592
Z=-24  | board         @(0,0,0)     |                                         :         |LINE ->|1 PRAIRIE| 2 CANYON | ...
Z=-40  |                            | T ⌂      T ⌂      T ⌂      [TRADING]   :         |X=400  |  arch   |  arch    |
       | [Leaderboards] [FREE       | [ P5 ]   [ P6 ]   [ P7 ]   [Sell|Barn] :         |
       |                 REWARDS]   | [pen ]   [pen ]   [pen ]   [ POST ]    :         |
Z=-129 +=================================================================================+
       X=-96                       X=64                                             X=400
  T = treadmill (on the boardwalk, directly in front of each plot)    ⌂ = plot gate + owner sign

LANE (side view of the sequence; H = herd + sleeping Alpha, ▲ = north/right side, ▼ = south/left side)
X: 400 432   592    784    1008    1264    1552    1872    2224    2608    3024              3600 3632
   |RL|TH|1 PRAIRIE|2 CANYON|3 MINE |4 BAYOU|5 FROST|6 VOLCANO|7 STORM|8 DINO |9 GHOST|  10 COSMIC RIFT  |END|
   |  |  | ▲H 528  |▼H 707  |▲H 918 |▼H 1162|▲H 1437|▼H 1744  |▲H 2083|▼H 2454|▲H 2858|        ▼H 3456   |   |
   RL = red line (Town Gate)   TH = trailhead   END = Frontier End barrier (new areas get appended here)
```

**Overall footprint:** X −98 to 3,634 (about 3,730 studs) and Z ±131. That covers a Town of 496 × 256 studs and a lane 128 wide and 3,200 long.

---

## 2. Speed → WalkSpeed, and why the lane is this long

No source gives SAE's distances in studs or its Speed→movement formula. The **[assumed]** mapping below is the one the lane was sized for:

```lua
WalkSpeed = math.clamp(16 + 12 * math.log10(1 + Speed), 16, 160)
-- towing multiplier (Systems and Scripts weight classes): <100 kg ×0.9, <1,000 ×0.8, <10K ×0.7, otherwise ×0.55
```

- **This replaces the `16 + 40*log10` example in `Systems and Scripts`.** That curve gives WalkSpeed 370 at 700M Speed. A player would cross the whole 3,200-stud lane in under 9 seconds, and StreamingEnabled could not keep up.
- **Escape is decided by stats, not physics** (Systems and Scripts already says this). A towing player escapes when `Speed × towMultiplier ≥ SpeedRequired`. This reproduces the GDD's "aim about 20% above the sign": 1.25× for a mid-weight beast, 1.43× heavy, 1.82× very heavy. That matches SAE guides' "15–20%, or 2–3× for heavy eggs" **[SAE]**.
- Because WalkSpeed is log-scaled, a 20% Speed margin adds only about 1 stud/s. Each server tick, AlphaService sets the Alpha's WalkSpeed to `playerWS × 0.92` when the stat test says the player escapes, or `playerWS × 1.12` when it says they get caught. That way the chase *looks* like what the stat test decided.

| Sign | WalkSpeed | Towing ×0.9 | ×0.8 | ×0.7 | ×0.55 |
|---|---|---|---|---|---|
| 0 | 16.0 | 14.4 | 12.8 | 11.2 | 8.8 |
| 900 | 51.5 | 46.3 | 41.2 | 36.0 | 28.3 |
| 10K | 64.0 | 57.6 | 51.2 | 44.8 | 35.2 |
| 40K | 71.2 | 64.1 | 57.0 | 49.9 | 39.2 |
| 170K | 78.8 | 70.9 | 63.0 | 55.1 | 43.3 |
| 700K | 86.1 | 77.5 | 68.9 | 60.3 | 47.4 |
| 2.5M | 92.8 | 83.5 | 74.2 | 64.9 | 51.0 |
| 17M | 102.8 | 92.5 | 82.2 | 71.9 | 56.5 |
| 150M | 114.1 | 102.7 | 91.3 | 79.9 | 62.8 |
| 700M | 122.1 | 109.9 | 97.7 | 85.5 | 67.2 |
| 2.5B (future) | 128.8 | 115.9 | 103.0 | 90.1 | 70.8 |
| 50B (future) | 144.4 | 129.9 | 115.5 | 101.1 | 79.4 |

**Run times at exactly the sign Speed.** Distance is measured from the red line (X = 400) to the herd centre. "Home" means towing a mid-weight beast at ×0.8.

| # | Area | Distance to herd | Out (no tow) | Home (towing) | Round trip |
|---|---|---|---|---|---|
| 1 | Dusty Prairie | 128 | 8.0 s | 10.0 s | 18 s |
| 2 | Cactus Canyon | 307 | 6.0 s | 7.5 s | 13 s |
| 3 | Gold Rush Mine | 518 | 8.1 s | 10.1 s | 18 s |
| 4 | Bayou Swamp | 762 | 10.7 s | 13.4 s | 24 s |
| 5 | Frost Peak | 1,037 | 13.2 s | 16.5 s | 30 s |
| 6 | Volcano Ridge | 1,344 | 15.6 s | 19.5 s | 35 s |
| 7 | Storm Mesa | 1,683 | 18.1 s | 22.7 s | 41 s |
| 8 | Dino Badlands | 2,054 | 20.0 s | 25.0 s | 45 s |
| 9 | Ghost Town | 2,458 | 21.5 s | 26.9 s | 48 s |
| 10 | Cosmic Rift | 3,056 | 25.0 s | 31.3 s | 56 s |

Escape time climbs from about 8 s near Town to about 31 s at Cosmic Rift. That matches SAE, where Cosmic is "the longest stretch of ground … the escape takes noticeably more time" **[SAE]**. A 4:50 day fits 4–5 far runs. Area 1 is tutorial-length on purpose, because Speed 0 is the default WalkSpeed of 16. Plot gates are 72 studs (P4) to 288 studs (P1) from the red line (see §5.1).

---

## 3. Hierarchy, tags, attributes, collision groups

### 3.1 Instance hierarchy

```
Workspace
  Map (Folder)                    attrs MapVersion=1, TownGateX=400, LaneHalfWidth=64, TrailHalfWidth=20
    Town (Folder)                 attrs = Town lighting profile (§8)
      Ground (Folder)
      Fence (Folder)              Palisade_N/S/W/EN/ES, Post_###, Boundary_N/S/W/EN/ES (invisible)
      Zones (Folder)              SZ_Square, SZ_Street, SZ_Gate, SZ_TradingPost  [SafeZone]; TownBounds [TownBounds]
      TownGate (Model)            RedLine [TownGate], AlphaBlocker, SundownCurtain, GatePostN/S, GateBoard, LanternN/S
      Square (Folder)             SpawnLocation, GeneralStore (Model), IndexBoard (Model), RewardsChest (Model),
                                  SundownClock (Model), Leaderboards (Model), EventPortalSpot, Decor (Folder)
      TradingPost (Folder)        SellStand (Model), BreedingBarn (Model)
      Street (Folder)             Lamps, AlleyBarrels
    Plots (Folder)
      Plot1 … Plot7 (Model)       [Plot]  PrimaryPart = PlotBase
        PlotBase, PlotBounds [PlotBounds], PenArea [PenArea], EntryPath, Threshold, GateRamp
        Fence (Folder)            FenceFrontW/E, FenceLeft/Right/Back, Collider×5, CornerPost×4
        Gate (Model)              GatePostL/R, LanternL/R, GateDoorL/R, GateLock [GateLock], OwnerSign [OwnerSign]
        Pen (Folder)              Slot01 … Slot10 [PenSlot]   (Slot11–19 created by RanchService on pen upgrade)
        Barn (Model)              Body, RoofW, RoofE, Door, Loft
        Treadmill (Model)         [Treadmill]  Base, Belt, Wheel, Hub, RailL, RailR
        PlotSpawn [PlotSpawn], Decor (Folder)
    Lane (Folder)
      Trailhead, Boundaries (Folder: LaneWall_N1/N2/S1/S2 [LaneBoundary]), Waypoints (Folder: WP00…WP11 [LaneWaypoint])
      FrontierEnd (Model) [FrontierEnd], StampedeStart, StampedeEnd
      Areas (Folder)
        Area01_DustyPrairie … Area10_CosmicRift (Model)     attrs §3.3 + lighting profile §8
          Ground (Folder)         TrailStrip, ShoulderN, ShoulderS
          Cliffs (Folder)         WallN, WallS, CrestN, CrestS, ToeN, ToeS
          Entrance (Model)        PostN, PostS, CapN, CapS, SignBoard [AreaSign], EntranceTrigger [AreaEntrance]
          Bounds [AreaBounds]
          Herd (Folder)           HerdZone [HerdZone], HerdSpawn01…08 [HerdSpawn], AlphaSpawn [AlphaSpawn],
                                  AlphaBed, HerdSign (Model) [HerdSign]
          Landmarks (Folder), Props (Folder)
  Runtime (Folder, created by server)   Herds, Alphas, LooseBeasts, PenBeasts, Traps, Stampede
```

### 3.2 CollectionService tags

| Tag | On | Used by |
|---|---|---|
| `SafeZone` | 4 zone volumes | CombatService (weapons off, a warning toast), trap placement |
| `TownBounds` | 1 volume | AlphaService leash, CycleService Sundown teleport, trap placement block |
| `TownGate` | RedLine | goal line, Alpha leash X |
| `Plot` | Plot models | RanchService plot assignment |
| `PlotBounds` | per plot | rustling / PvP-in-yard checks |
| `PenArea` | per plot | "beast is inside the pen" checks |
| `PenSlot` | slot pads | pen placement, income display |
| `GateLock` | per plot | gate lock |
| `OwnerSign` | per plot | owner name and headshot |
| `PlotSpawn` | per plot | respawn and Sundown teleport target |
| `Treadmill` | per plot | SpeedService |
| `ShopPad`, `SellPad`, `BreedingPad`, `IndexPad`, `RewardsPad` | glowing floor rings | open the matching UI on step (SAE's Trails Shop is a glowing floor circle you step on **[SAE]**) |
| `SundownClock`, `Leaderboard`, `EventPortalSpot` | Town fixtures | UI and future event portal |
| `AreaEntrance` | arch trigger | "Entering CACTUS CANYON" banner |
| `AreaBounds` | area volume | current-area lookup, lighting, the "caught in own area → beast bolts home" rule |
| `AreaSign` / `HerdSign` | sign boards | client colours the Speed line green or red |
| `HerdZone` | herd patch | lasso validation, bolt-back target |
| `HerdSpawn` | 8 per area | HerdService |
| `AlphaSpawn` | 1 per area | AlphaService |
| `LaneWaypoint` | 12 points | Alpha chase steering and Stampede route |
| `LaneBoundary`, `FrontierEnd` | invisible walls | anti-exploit position checks |
| `SecretSpot` | reserved markers | future secrets (SAE hides vault parts at its landmarks **[SAE]**) |

### 3.3 Attributes

| Instance | Attributes (type) |
|---|---|
| Area model, EntranceTrigger, Bounds, SignBoard, HerdZone, HerdSpawn, AlphaSpawn, HerdSign | `AreaIndex` (int 1–10), `AreaId` (string), `AreaName` (string), `SpeedRequired` (number) |
| Area model only | `StartX`, `EndX`, `HerdX` (number), `HerdSide` (int +1 north / −1 south), `HerdSpacing` (number) |
| HerdSpawn | `SpawnIndex` (1–8), `PatchIndex` (1–2), `Occupied` (bool, runtime) |
| AlphaSpawn | `AlphaId` (string), `LeashX` (number = 400) |
| Plot model | `PlotIndex` (1–7), `Row` ("North"/"South"), `OwnerUserId` (int, 0 = free), `PenLevel` (int, 1), `GateLocked` (bool) |
| PenSlot | `PlotIndex`, `SlotIndex` (1–19), `Active` (bool), `Occupied` (bool, runtime) |
| GateLock | `PlotIndex`, `Locked` (bool, false) |
| Treadmill | `PlotIndex`, `Tier` (int 1–11, starts 1) |
| SafeZone volume | `ZoneName` (string) |
| LaneWaypoint | `Order` (int 0–11) |
| SecretSpot | `SecretId` (string) |
| ShopPad | `ShopId` ("General") |

### 3.4 Collision groups (registered at server start)

| Group | Collides with |
|---|---|
| `Players` (default for characters) | everything except `Beasts`, `Alphas`, `AlphaBlocker` |
| `Beasts` (herd, towed, loose, pen) | Default only. A towed beast never trips its tower. |
| `Alphas` | Default and `AlphaBlocker`. Catches are decided by distance, not collision. |
| `AlphaBlocker` | `Alphas` only. A physical backup leash at the red line. |
| `GateLock1`…`GateLock7` | `Players` and every `Owner*` group **except** its own `Owner<i>` |
| `Owner1`…`Owner7` | same as `Players`. The owner's character parts go here on spawn. |

That is 18 groups, under the limit of 32.

**Zone test** (use this for every volume; no Touched events needed):

```lua
local function inBox(part: BasePart, pos: Vector3): boolean
	local p = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
end
```

---

## 4. Town (Safe Zone, spawn, shops)

The GDD has two nested zones:
- **TownBounds** is the whole fenced Town. Inside it, Alphas give up, Sundown leaves you alone, and traps can't be placed **[GDD]**.
- **SafeZone** covers the square, the street, the boardwalks, the gate plaza and the Trading Post. Weapons are disabled there **[GDD/SAE]**.

**Plot yards are inside TownBounds but outside SafeZone**, so whips and rustling work in a ranch yard **[GDD twist]**. (In SAE, pens sit inside the Safe Zone **[SAE]**.)

### 4.1 Zones (all invisible volumes, CanQuery true)

| Name | Tag | Centre | Size | Covers |
|---|---|---|---|---|
| `TownBounds` | TownBounds | (152, 40, 0) | (496, 80, 256) | X −96..400, Z ±128 |
| `SZ_Square` | SafeZone | (−16, 30, 0) | (160, 60, 256) | X −96..64 |
| `SZ_Street` | SafeZone | (232, 30, 0) | (336, 60, 80) | street + both boardwalks, X 64..400, Z ±40 |
| `SZ_Gate` | SafeZone | (380, 30, 0) | (40, 60, 128) | gate plaza X 360..400, Z ±64 |
| `SZ_TradingPost` | SafeZone | (328, 30, −80) | (64, 60, 80) | Trading Post lot |

### 4.2 Ground (6 parts, top at Y 0)

| Part | Size | Centre | Material, colour |
|---|---|---|---|
| SquareGround | 160×4×256 | (−16, −2, 0) | Ground 196,164,116 |
| MainStreet | 336×4×48 | (232, −2, 0) | Ground 176,138,96 |
| BoardwalkN | 336×4×16 | (232, −2, 32) | WoodPlanks 150,104,62 |
| BoardwalkS | 336×4×16 | (232, −2, −32) | WoodPlanks 150,104,62 |
| RanchGroundN | 336×4×88 | (232, −2, 84) | Grass 140,160,84 |
| RanchGroundS | 336×4×88 | (232, −2, −84) | Grass 140,160,84 |

### 4.3 Fence and boundary (visible fence + invisible wall, 55 parts)

The visible fence is a log palisade, 12 tall (Wood 120,82,48):

| Part | Size | Centre |
|---|---|---|
| Palisade_N | 496×12×2 | (152, 6, 129) |
| Palisade_S | 496×12×2 | (152, 6, −129) |
| Palisade_W | 2×12×256 | (−97, 6, 0) |
| Palisade_EN | 2×12×64 | (401, 6, 96) |
| Palisade_ES | 2×12×64 | (401, 6, −96) |

**Posts:** 45 × `VCyl 14×3`, Wood 96,64,36, at y 7.
- On Z = ±129, at X = −96, −64, …, 384 (step 32) plus X = 400. That is 17 per side.
- On X = −97, at Z = −96, −64, …, 96 (7 posts).
- On X = 401, at Z = ±64 and ±96 (4 posts).

**Invisible boundary walls** (height 80, centre y 40), 5 parts:

| Part | Size | Centre |
|---|---|---|
| Boundary_N | 500×80×2 | (152, 40, 131) |
| Boundary_S | 500×80×2 | (152, 40, −131) |
| Boundary_W | 2×80×264 | (−99, 40, 0) |
| Boundary_EN | 2×80×66 | (403, 40, 97) |
| Boundary_ES | 2×80×66 | (403, 40, −97) |

The east boundary pieces meet the lane walls at Z ±64.

### 4.4 Town Gate: the red line (8 parts)

SAE marks the edge of its Safe Zone with a **red line on the ground**. Crossing it ends the guardian chase, and it is the goal line for a steal **[SAE]**.

| Part | Spec |
|---|---|
| `RedLine` [TownGate] | `Block 1×0.2×128 @(400, 0, 0)` Neon 255,40,40, **nc**. The goal line. |
| `AlphaBlocker` | `Block 2×60×128 @(400, 30, 0)`, Transparency 1, CanCollide true, group `AlphaBlocker` |
| `SundownCurtain` | `Block 2×40×128 @(399, 20, 0)`, ForceField 255,150,80. Off by default (T1, nc). During Sundown, CycleService sets it to T0.4 with CanCollide true, so the map is closed for 10 s (SAE closes the map for about 10–13 s between cycles **[SAE]**). |
| `GatePostN` / `GatePostS` | `VCyl 30×5 @(404, 15, ±34)` Wood 110,74,42 |
| `GateBoard` | `Block 3×8×76 @(404, 33, 0)` WoodPlanks 176,128,78. The SurfaceGui on its **Left** (−X, read when leaving) says `THE FRONTIER →` / `weapons ON past the red line`. The one on its **Right** (+X, read when returning) says `TOWN · SAFE ZONE`. Font GothamBlack (Montserrat Black, as in Steal An Egg). |
| `LanternN` / `LanternS` | `Ball 2 @(404, 31, ±34)` Neon 255,200,120, PointLight Range 16, Shadows off |

### 4.5 Town Square fixtures (47 parts)

| Fixture | Parts |
|---|---|
| **SpawnLocation** | `Block 20×1×20 @(0, 0.5, 0)`, Orientation (0, −90, 0) so players spawn facing +X down Main Street. Neutral = true, Duration = 0, Slate 150,120,90. |
| **General Store** (Shop: treadmill tiers, Spurs, gear) | facade `Block 44×22×2 @(0, 11, 112)` WoodPlanks 164,112,70 · body `Block 44×18×14 @(0, 9, 120)` Wood 140,96,58 · awning `Block 40×1×8 @(0, 12.5, 107)` Fabric 190,60,50 · awning posts `VCyl 12×1 @(±19, 6, 103.5)` Wood · counter `Block 24×4×4 @(0, 2, 105)` WoodPlanks · sign `Block 30×5×0.6 @(0, 18, 110.7)` WoodPlanks 70,46,30, SurfaceGui Front `GENERAL STORE` · **ShopPad** `VCyl 0.2×18 @(0, 0.1, 90)` Neon 255,200,40 T0.25 nc, `ShopId="General"`, with a BillboardGui `SHOP` at y +4 (SAE's yellow `TRAILS SHOP` floor circle **[SAE]**) |
| **EventPortalSpot** | `Block 12×16×2 @(36, 8, 104)` invisible. Reserved beside the shop for event portals, as in SAE, whose Halloween portal sits beside the Trails Shop **[SAE]**. |
| **Index board** | board `Block 2×22×44 @(−88, 14, 0)` WoodPlanks 176,128,78, SurfaceGui Right (+X) `BEAST INDEX` · posts `VCyl 26×2.5 @(−88, 13, ±23)` Wood · roof cap `Block 4×1.5×48 @(−88, 25.75, 0)` Wood · **IndexPad** `VCyl 0.2×16 @(−70, 0.1, 0)` Neon 60,220,230 T0.25 nc, Billboard `INDEX` |
| **Free Rewards chest** (red and gold like SAE's **[SAE]**) | pedestal `Block 14×1×12 @(0, 0.5, −104)` Marble 220,214,200 · base `Block 8×5×6 @(0, 3.5, −104)` Wood 170,36,36 · lid `HCylX 8×6 @(0, 6, −104)` Wood 170,36,36 · bands `Block 0.8×5.4×6.2 @(±2.5, 3.6, −104)` Foil 255,200,60 · lock `Block 1.6×2×0.4 @(0, 5.2, −100.9)` Neon 255,210,80 · **RewardsPad** `VCyl 0.2×14 @(0, 0.1, −90)` Neon 255,80,80 T0.25 nc, Billboard `FREE REWARDS` |
| **Sundown clock tower** [SundownClock] | tower `Block 12×30×12 @(−56, 15, 80)` Brick 150,84,64 · roof `Wedge 12×6×6 @(−56, 33, 83) rotY 180` and `Wedge 12×6×6 @(−56, 33, 77)` WoodPlanks 96,64,52 · face `Block 0.4×9×9 @(−49.8, 22, 80)` SmoothPlastic 245,240,225, SurfaceGui Right `SUNDOWN IN m:ss` |
| **Leaderboards** [Leaderboard] | base `Block 4×2×42 @(−56, 1, −80)` Wood · boards `Block 1×16×18 @(−56, 10, −70)` (Cash) and `@(−56, 10, −90)` (Speed), SurfaceGui Right |
| **Lamps** ×6 | pole `VCyl 12×1 @(x, 6, z)` Metal 60,56,52 + lamp `Ball 2 @(x, 12.8, z)` Neon 255,210,140, PointLight Range 18, Shadows off, at (±40, ±40) and (−80, ±60) |
| **Troughs and barrels** | trough `Block 8×2.4×3 @(24, 1.2, ±60)` WoodPlanks + water `Block 7.4×0.2×2.4 @(24, 2.35, ±60)` SmoothPlastic 80,150,200 nc · barrels `VCyl 3×2.4 @(30, 1.5, ±64)` Wood 130,90,56 |

### 4.6 Trading Post: south lot X 296..360, Z −120..−40 (15 parts)

SAE puts its Sell stand next to the Fuse Machine **[SAE]**. Ours pairs the Sell stand with the Breeding Barn (our Fuse Machine), right by the gate, so you can sell a beast you're still towing.

| Fixture | Parts |
|---|---|
| **Sell stand** | counter `Block 20×4×4 @(312, 2, −58)` WoodPlanks 164,112,70 · back wall `Block 22×14×2 @(312, 7, −70)` Wood 140,96,58 · awning `Wedge 24×3×12 @(312, 15.5, −64) rotY 180` Fabric 60,140,70 · sign `Block 18×4×0.5 @(312, 19, −68.7)` WoodPlanks, SurfaceGui Back (+Z) `SELL` · coins `Ball 3 @(306, 4.8, −58)` and `Ball 2.4 @(318, 4.6, −58)` Foil 255,200,60 · **SellPad** `VCyl 0.2×14 @(312, 0.1, −50)` Neon 70,220,100 T0.25 nc |
| **Breeding Barn** | body `Block 24×14×22 @(344, 7, −94)` Wood 168,44,38, SurfaceGui Back `BREEDING BARN` · roof `Wedge 22×6×12 @(338, 17, −94) rotY 90` and `Wedge 22×6×12 @(350, 17, −94) rotY −90` WoodPlanks 96,64,52 · door `Block 10×10×0.4 @(344, 6, −82.8)` Wood 236,228,214 · loft `Block 4×3×0.4 @(344, 16.5, −82.8)` SmoothPlastic 40,30,26 · hay `HCylX 5×4 @(334, 2, −76)` and `@(334, 2, −70)` Grass 220,190,100 · **BreedingPad** `VCyl 0.2×14 @(344, 0.1, −72)` Neon 255,110,200 T0.25 nc |

### 4.7 Street furniture (32 parts)

- **Lamps** ×10: `VCyl 12×1` + `Ball 2` (as in the square) at X = 72, 148, 220, 292, 368 and Z = ±25 (the street edge of each boardwalk). These X values avoid every treadmill and PlotSpawn.
- **Alley barrels** ×12: `VCyl 3×2.4` Wood 130,90,56 at y 1.5. They sit in the 8-wide alleys between plots (X = 148, 220, 292), at Z = ±60 and ±100.

---

## 5. Ranch plots (7)

### 5.1 Arrangement: two facing rows on Main Street [assumed]

**No source describes SAE's base layout** (single row, facing rows, or arc). Here is what the research does give:
- Servers have 7 players, each with their own plot, "distributed evenly".
- Every base empties onto the same biome path. Players ambush "outside rival pens" and in the corridors between bases and nests.
- Each treadmill sits "directly in front of" its base.
- The map is "one long, narrow" track.
- Fan-made SAE map kits have 7 plots, and one measures about **110 × 930 studs**. A strip that narrow only fits 7 plots as two facing rows along a central road. (Those kits are fan-made and **not official** **[SAE, weak]**.)

So: **4 plots on the north side and 3 on the south side** face a shared **Main Street** that runs straight into the lane. The south row's 4th slot is the Trading Post. The plot pitch is 72 (64-wide plot, 8-wide alley). From each plot gate to the red line is 72 to 288 studs. Plots nearer the gate are closer to the herds but also the first ones passing rustlers reach, so the distance gap partly balances out. **RanchService assigns a random free plot [assumed]**, so whoever joins first doesn't always get the best one.

### 5.2 World placement

The template is built once, facing local −Z (its gate is on the −Z side), and cloned with `PivotTo`:

| Plot | Row | Pivot CFrame | Gate (front centre) | Treadmill centre | PlotSpawn |
|---|---|---|---|---|---|
| Plot1 | North | `CFrame.new(112, 0, 80)` | (112, 40) | (130, 0.5, 32) | (94, 0.5, 32) |
| Plot2 | North | `CFrame.new(184, 0, 80)` | (184, 40) | (202, 0.5, 32) | (166, 0.5, 32) |
| Plot3 | North | `CFrame.new(256, 0, 80)` | (256, 40) | (274, 0.5, 32) | (238, 0.5, 32) |
| Plot4 | North | `CFrame.new(328, 0, 80)` | (328, 40) | (346, 0.5, 32) | (310, 0.5, 32) |
| Plot5 | South | `CFrame.new(112, 0, −80) * CFrame.Angles(0, math.pi, 0)` | (112, −40) | (94, 0.5, −32) | (130, 0.5, −32) |
| Plot6 | South | `CFrame.new(184, 0, −80) * CFrame.Angles(0, math.pi, 0)` | (184, −40) | (166, 0.5, −32) | (202, 0.5, −32) |
| Plot7 | South | `CFrame.new(256, 0, −80) * CFrame.Angles(0, math.pi, 0)` | (256, −40) | (238, 0.5, −32) | (274, 0.5, −32) |

North plots cover X ±32 around their centre and Z 40..120; south plots are mirrored to Z −120..−40. The treadmill and PlotSpawn sit on the boardwalk, which is SafeZone. That makes training AFK safe, just as SAE's treadmill sits in front of the base **[SAE]**.

### 5.3 Plot template, local coordinates (54 parts per plot; 148 since the Steal An Egg-style base in section 13)

The pivot is at (0, 0, 0) at ground level. Local −Z is the front, facing the street. The footprint is X ±32, Z ±40. The plot platform is raised 1 stud, so its top is at y = 1.

| Group | Part | Spec |
|---|---|---|
| Platform | `PlotBase` | `Block 64×1×80 @(0, 0.5, 0)` Grass 124,160,76 |
| | `EntryPath` | `Block 12×0.2×14 @(0, 1.0, −33)` Ground 170,132,90, nc |
| | `Threshold` | `Block 16×0.2×1 @(0, 1.0, −39.5)` Neon 255,170,40, nc. The amber strip means "leaving the Safe Zone, PvP is on in this yard". |
| | `GateRamp` | `Wedge 16×1×4 @(0, 0.5, −42)`, rising toward the plot, WoodPlanks 150,104,62 |
| Fence (Wood 150,100,60, height 1..6) | `FenceFrontW` / `FenceFrontE` | `Block 24×5×1 @(∓20, 3.5, −39.5)` |
| | `FenceLeft` / `FenceRight` | `Block 1×5×80 @(∓31.5, 3.5, 0)` |
| | `FenceBack` | `Block 64×5×1 @(0, 3.5, 39.5)` |
| | `Collider` ×5 | same X/Z footprint as the five fences, Size Y 14, y 8, invisible but **CanCollide true**. You can't jump the fence; the gate is the only way in. |
| | `CornerPost` ×4 | `VCyl 7×2 @(±31.5, 4.5, ±39.5)` Wood 110,76,46 |
| Gate | `GatePostL` / `GatePostR` | `VCyl 16×2 @(∓9, 9, −39.5)` Wood 110,76,46 |
| | `LanternL` / `LanternR` | `Ball 1.6 @(∓9, 17.8, −39.5)` Neon 255,200,120, PointLight Range 12, Shadows off |
| | `OwnerSign` [OwnerSign] | `Block 20×4×1 @(0, 14, −39.5)` WoodPlanks 190,140,80. SurfaceGui **Front** shows `<DisplayName>'s Ranch` plus a headshot ImageLabel, or `FREE RANCH` when unowned. |
| | `GateDoorL` / `GateDoorR` | `Block 8×4×0.6 @(∓12.5, 3, −38.6)` Wood 120,84,52, nc (decorative, standing open) |
| | `GateLock` [GateLock] | `Block 16×14×1 @(0, 8, −39.5)` ForceField 255,60,60. **Disabled by default:** T1, nc. See §5.5. |
| Pen | `Slot01`…`Slot10` [PenSlot] | `Block 10×0.4×10` at y 1.1, nc. See §5.4. |
| | `PenArea` [PenArea] | `Block 60×12×52 @(0, 7, 0)`, invisible |
| | `PlotBounds` [PlotBounds] | `Block 64×40×80 @(0, 20, 0)`, invisible |
| Barn | `Body` | `Block 32×12×12 @(0, 7, 33)` Wood 168,44,38 |
| | `RoofW` / `RoofE` | `Wedge 12×7×16 @(−8, 16.5, 33) rotY 90` and `@(8, 16.5, 33) rotY −90`, WoodPlanks 96,64,52. The ridge runs front to back. |
| | `Door` | `Block 10×9×0.4 @(0, 5.5, 26.8)` Wood 236,228,214 |
| | `Loft` | `Block 4×3×0.4 @(0, 15.5, 26.8)` SmoothPlastic 40,30,26 |
| Treadmill [Treadmill] | `Base` | `Block 18×1×10 @(18, 0.5, −48)` Wood 110,76,46 |
| | `Belt` | `Block 14×0.2×7 @(18, 1.1, −48)` Fabric 45,45,48. Scroll a Texture on the client while someone is running on it. |
| | `Wheel` | `HCylX 1×10 @(27.5, 5.5, −48)` Wood 130,92,56 (the "wagon-wheel treadmill" **[GDD]**) |
| | `Hub` | `Ball 2 @(28.2, 5.5, −48)` Foil 230,190,90 |
| | `RailL` / `RailR` | `Block 14×0.5×0.5 @(20, 4, −51.75)` and `@(20, 4, −44.25)` Metal 90,90,96 |
| | (tier display) | BillboardGui on Base: tier name + `+N / step` |
| Spawn | `PlotSpawn` [PlotSpawn] | `Block 6×1×6 @(−18, 0.5, −48)`, invisible, facing local −Z (toward the street) |
| Decor | hay ×2 | `HCylX 5×4 @(−24, 3, 29)` and `@(−24, 3, 33.5)` Grass 220,190,100 |
| | trough | `Block 8×2×3 @(24, 2, 32)` WoodPlanks + water `Block 7.4×0.2×2.4 @(24, 3.05, 32)` SmoothPlastic 80,150,200, nc |

The treadmill sits on the boardwalk, **directly in front of the plot** and offset to the right of the gate so it never blocks the entrance.

### 5.4 Pen slots

The pen starts with **10 slot pads, and slots 1–7 are active**. Pens upgrade up to 19 slots **[GDD/SAE]**. Each pad's `Attachment "BeastPivot"` sits at the top centre, y 1.3.

| Slots | Local z | Local x |
|---|---|---|
| 1, 2, 3, 4, 5 (built) | −20 | −24, −12, 0, 12, 24 |
| 6, 7, 8, 9, 10 (built) | −7 | −24, −12, 0, 12, 24 |
| 11–15 (reserved, created on upgrade) | +6 | −24, −12, 0, 12, 24 |
| 16–19 (reserved) | +19 | −24, −12, 12, 24 (the middle is left clear for the barn door) |

- **Active** pads: Sand 222,196,120.
- **Locked** pads: SmoothPlastic 120,120,120 T0.5, with a padlock BillboardGui. `Active = SlotIndex <= 7` at PenLevel 1.
- World position: north plots `(Xc + x, 1.1, 80 + z)`, south plots `(Xc − x, 1.1, −80 − z)`.

### 5.5 Gate lock

When the lock is on:
- `GateLock.Locked = true`, Transparency 0.35, CanCollide true, CollisionGroup `GateLock<i>`.
- The owner's character is already in `Owner<i>`, so only the owner can walk through. This copies Steal a Brainrot's owner-only laser gate, which our GDD adopts.

When it turns off, revert to T1 and nc. Durations (60 s + 10 s per pen level, 30 s on join) live in RanchService **[GDD]**. SAE itself has no base lock **[SAE]**.

---

## 6. The lane

### 6.1 Global lane parts (25 parts)

| Part | Spec |
|---|---|
| `Trailhead` | `Block 32×4×128 @(416, −2, 0)` Ground 176,138,96. X 400..432 is neutral ground (AreaIndex 0) between the red line and Area 1. |
| `LaneWall_N1` / `LaneWall_S1` [LaneBoundary] | `Block 1616×200×4 @(1208, 100, ±66)`, invisible but **CanCollide true**. Covers X 400..2016. |
| `LaneWall_N2` / `LaneWall_S2` [LaneBoundary] | `Block 1616×200×4 @(2824, 100, ±66)`, invisible, CanCollide true. Covers X 2016..3632. |
| `FrontierEnd` [FrontierEnd] | ground `Block 32×4×128 @(3616, −2, 0)` Slate 40,32,60 · barrier `Block 2×40×128 @(3631, 20, 0)` ForceField 255,150,220 T0.1 · collider `Block 4×200×136 @(3634, 100, 0)` invisible, CanCollide true · posts `VCyl 26×4 @(3612, 13, ±30)` Glass 120,90,220 · board `Block 1.5×10×68 @(3612, 31, 0)` SmoothPlastic 24,18,40. The board's SurfaceGui Left reads `SAKURA SPRINGS · 2.5B SPEED · COMING SATURDAY`. |
| `WP00`…`WP11` [LaneWaypoint] | `Block 2×1×2` invisible, at `(X, 0.5, 0)` for X = 400, 432, 592, 784, 1008, 1264, 1552, 1872, 2224, 2608, 3024, 3600 (`Order` 0–11) |
| `StampedeStart` / `StampedeEnd` | `Block 4×1×4` invisible at (2608, 0.5, 0) and (440, 0.5, 0). The Stampede herd runs from the start of Ghost Town down to the trailhead in 60 s (about 36 studs/s) **[GDD]**. |

**Lane cross-section** (the same in every area):
- The trail strip is 40 wide (Z ±20), the walkable route.
- Shoulders run from Z 20 to 64 on each side and hold the herds, scenery and landmarks.
- Cliffs start at Z ±64.
- Invisible walls are at Z ±64..68.

SAE biomes have perimeter or boundary walls **[SAE]**; ours are themed cliffs.

### 6.2 Area table

The 10 areas run in fixed order, each farther from Town than the last, and new ones are added at the far end **[SAE]**. Lengths grow by 32 studs per area, and **Cosmic Rift is the longest** at 576 **[SAE: Cosmic is the longest stretch]**. Area 9 (Ghost Town) is ours; it sits in the slot between SAE's Prehistoric and Cosmic.

| # | Area (AreaId) | SAE slot | Sign | SpeedRequired | StartX | EndX | Length | CentreX | Alpha (AlphaId) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Dusty Prairie (`DustyPrairie`) | Forest | `0 SPEED` | 0 | 432 | 592 | 160 | 512 | Ol' Stompy (`OlStompy`) |
| 2 | Cactus Canyon (`CactusCanyon`) | Lake | `900 SPEED` | 900 | 592 | 784 | 192 | 688 | Rattlesnake King (`RattlesnakeKing`) |
| 3 | Gold Rush Mine (`GoldRushMine`) | Desert | `10K SPEED` | 10,000 | 784 | 1008 | 224 | 896 | Big Digger (`BigDigger`) |
| 4 | Bayou Swamp (`BayouSwamp`) | Jungle | `40K SPEED` | 40,000 | 1008 | 1264 | 256 | 1136 | Croc King (`CrocKing`) |
| 5 | Frost Peak (`FrostPeak`) | Snow | `170K SPEED` | 170,000 | 1264 | 1552 | 288 | 1408 | Yeti Moose (`YetiMoose`) |
| 6 | Volcano Ridge (`VolcanoRidge`) | Volcano | `700K SPEED` | 700,000 | 1552 | 1872 | 320 | 1712 | Magma Ox (`MagmaOx`) |
| 7 | Storm Mesa (`StormMesa`) | Abyss Ocean | `2.5M SPEED` | 2,500,000 | 1872 | 2224 | 352 | 2048 | Storm Griffin (`StormGriffin`) |
| 8 | Dino Badlands (`DinoBadlands`) | Prehistoric | `17M SPEED` | 17,000,000 | 2224 | 2608 | 384 | 2416 | Rodeo Rex (`RodeoRex`) |
| 9 | Ghost Town (`GhostTown`) | (ours) | `150M SPEED` | 150,000,000 | 2608 | 3024 | 416 | 2816 | Phantom Steed (`PhantomSteed`) |
| 10 | Cosmic Rift (`CosmicRift`) | Cosmic | `700M SPEED` | 700,000,000 | 3024 | 3600 | 576 | 3312 | Cosmic Kraken-Cow (`CosmicKrakenCow`) |

The lane totals 3,168 studs of areas, plus the 32-stud trailhead and the 32-stud Frontier End.

### 6.3 Common build for every area (29 fixed parts)

With `S` = StartX, `E` = EndX, `L` = Length, `C` = CentreX, `H` = cliff height, and `σ` = HerdSide (+1 north, −1 south):

| Group | Part | Spec |
|---|---|---|
| Ground | `TrailStrip` | `Block L×4×40 @(C, −2, 0)`, area trail material |
| | `ShoulderN` / `ShoulderS` | `Block L×4×44 @(C, −2, ±42)`, area shoulder material |
| Cliffs | `WallN` / `WallS` | `Block L×H×12 @(C, H/2, ±70)`. The inner face is at Z ±64. |
| | `CrestN` | `Block 0.4L×0.5H×10 @(S+0.3L, 1.25H, 71)`, the silhouette bump |
| | `CrestS` | `Block 0.4L×0.5H×10 @(S+0.7L, 1.25H, −71)` |
| | `ToeN` | `Wedge L×0.4H×6 @(C, 0.2H, 61)`, slope facing the trail (rotY 0) |
| | `ToeS` | `Wedge L×0.4H×6 @(C, 0.2H, −61) rotY 180` |
| Entrance arch | `PostN` / `PostS` | `VCyl 26×4 @(S, 13, ±30)` |
| | `CapN` / `CapS` | `Ball 5 @(S, 38.5, ±30)` |
| | `SignBoard` [AreaSign] | `Block 1.5×10×68 @(S, 31, 0)`. SurfaceGui **Left** (−X, read when running out), 20 px/stud: line 1 is the area name in caps (for example `CACTUS CANYON`), line 2 is the sign (for example `900 SPEED`). SurfaceGui **Right** (+X): `← TOWN`. On the client, the Speed line turns green when your Speed ≥ SpeedRequired × 1.25 and red otherwise. |
| | `EntranceTrigger` [AreaEntrance] | `Block 2×60×128 @(S, 30, 0)`, invisible, CanQuery true |
| Bounds | `Bounds` [AreaBounds] | `Block L×120×128 @(C, 60, 0)`, invisible, CanQuery true |
| Herd | `HerdZone` [HerdZone] | `Block (2(s+4)+s+10)×0.2×(s+10) @(HerdX, 0, 28σ)`, nc, in the area's herd material |
| | `HerdSpawn01–08` [HerdSpawn] | `Block 2×1×2`, invisible, see §6.4 |
| | `AlphaSpawn` [AlphaSpawn] | `Block 8×1×8 @(HerdX, 0.5, σ(42 + s/2))`, invisible, faces the trail (rotY 0 north, 180 south) |
| | `AlphaBed` | `VCyl 0.3×bedD @(HerdX, 0.05, σ(42 + s/2))`, nc |
| | `HerdSign` post + board [HerdSign] | post `VCyl 8×1 @(HerdX+18, 4, AlphaZ)` · board `Block 8×3.5×0.5 @(HerdX+18, 9, AlphaZ)`, SurfaceGui facing the trail (Front if north, Back if south): `<ALPHA NAME>` / `<sign> SPEED`. This copies SAE's recommended-Speed sign that stands **next to the guardian** **[SAE]**. |

Signs are soft gates only, with no barrier, as in SAE **[SAE]**. Arch fonts are Enum.Font.GothamBlack (Montserrat Black, Steal An Egg's UI font), white with a black outline (changed 2026-10-20; was LuckiestGuy).

**Cliff numbers per area:**

| # | Cliff H | Walls @ / size | CrestN @ / size | CrestS @ / size | Toes y / size |
|---|---|---|---|---|---|
| 1 | 18 | (512, 9, ±70) / 160×18×12 | (480, 22.5, 71) / 64×9×10 | (544, 22.5, −71) / 64×9×10 | 3.6 / 160×7.2×6 |
| 2 | 32 | (688, 16, ±70) / 192×32×12 | (650, 40, 71) / 77×16×10 | (726, 40, −71) / 77×16×10 | 6.4 / 192×12.8×6 |
| 3 | 36 | (896, 18, ±70) / 224×36×12 | (851, 45, 71) / 90×18×10 | (941, 45, −71) / 90×18×10 | 7.2 / 224×14.4×6 |
| 4 | 28 | (1136, 14, ±70) / 256×28×12 | (1085, 35, 71) / 102×14×10 | (1187, 35, −71) / 102×14×10 | 5.6 / 256×11.2×6 |
| 5 | 40 | (1408, 20, ±70) / 288×40×12 | (1350, 50, 71) / 115×20×10 | (1466, 50, −71) / 115×20×10 | 8 / 288×16×6 |
| 6 | 44 | (1712, 22, ±70) / 320×44×12 | (1648, 55, 71) / 128×22×10 | (1776, 55, −71) / 128×22×10 | 8.8 / 320×17.6×6 |
| 7 | 40 | (2048, 20, ±70) / 352×40×12 | (1978, 50, 71) / 141×20×10 | (2118, 50, −71) / 141×20×10 | 8 / 352×16×6 |
| 8 | 44 | (2416, 22, ±70) / 384×44×12 | (2339, 55, 71) / 154×22×10 | (2493, 55, −71) / 154×22×10 | 8.8 / 384×17.6×6 |
| 9 | 36 | (2816, 18, ±70) / 416×36×12 | (2733, 45, 71) / 166×18×10 | (2899, 45, −71) / 166×18×10 | 7.2 / 416×14.4×6 |
| 10 | 48 | (3312, 24, ±70) / 576×48×12 | (3197, 60, 71) / 230×24×10 | (3427, 60, −71) / 230×24×10 | 9.6 / 576×19.2×6 |

### 6.4 Herds: 8 HerdSpawn points + AlphaSpawn

The research says each SAE biome has **several nests**, each holding **several eggs side by side**, with the **guardian asleep right beside the nests** and a Speed sign next to it. Counts and arrangement are not documented **[SAE]**. Our version **[assumed numbers]**:
- 8 points per area, split into **2 patches ("nests") of 4**. Each patch is a 2×2 grid with spacing `s`.
- The patches sit side by side along the lane, with an 8-stud gap between them.
- The **Alpha sleeps on the cliff side of the herd, centred between the two patches**, so you lasso from the trail side with the Alpha right behind the beasts.
- **Herds alternate sides** (north for odd areas, south for even areas) so the trail stays clear for players running farther out **[assumed]**.
- The herd centre sits at 60% of the area's length, or 75% in Cosmic Rift, where SAE's best Cosmic nest is at the far end **[SAE]**.

HerdService fills 5–8 of the 8 points per restock **[GDD]**. It gives each beast a random yaw of ±35° around "facing the trail". Bigger beasts in later areas get wider spacing `s`.

```lua
-- authoritative formula (y = 0.5; beasts are pivoted so their feet touch y = 0)
local function herdPoints(a) -- a.HerdX, a.HerdSide (σ), a.HerdSpacing (s)
	local pts, s, side = {}, a.HerdSpacing, a.HerdSide
	for _, patch in ipairs({-1, 1}) do                       -- PatchIndex 1 = toward Town, 2 = away
		local px = a.HerdX + patch * (s + 4)
		for _, zr in ipairs({28 - s/2, 28 + s/2}) do          -- trail-side row first
			for _, dx in ipairs({-s/2, s/2}) do
				table.insert(pts, Vector3.new(px + dx, 0.5, side * zr))
			end
		end
	end
	return pts                                               -- SpawnIndex 1..8 in this order
end
-- AlphaSpawn = Vector3.new(a.HerdX, 0.5, side * (28 + s/2 + 14))
```

| # | HerdX | σ | s | HerdZone @ / size | AlphaSpawn | AlphaBed | HerdSign X | Prop exclusion |
|---|---|---|---|---|---|---|---|---|
| 1 | 528 | +1 | 10 | (528, 0, 28) / 48×0.2×20 | (528, 0.5, 47) rotY 0 | d 16 | 546 | X 480–576, north |
| 2 | 707 | −1 | 10 | (707, 0, −28) / 48×0.2×20 | (707, 0.5, −47) rotY 180 | d 16 | 725 | X 659–755, south |
| 3 | 918 | +1 | 10 | (918, 0, 28) / 48×0.2×20 | (918, 0.5, 47) rotY 0 | d 16 | 936 | X 870–966, north |
| 4 | 1162 | −1 | 12 | (1162, 0, −28) / 54×0.2×22 | (1162, 0.5, −48) rotY 180 | d 16 | 1180 | X 1114–1210, south |
| 5 | 1437 | +1 | 12 | (1437, 0, 28) / 54×0.2×22 | (1437, 0.5, 48) rotY 0 | d 16 | 1455 | X 1389–1485, north |
| 6 | 1744 | −1 | 12 | (1744, 0, −28) / 54×0.2×22 | (1744, 0.5, −48) rotY 180 | d 16 | 1762 | X 1696–1792, south |
| 7 | 2083 | +1 | 14 | (2083, 0, 28) / 60×0.2×24 | (2083, 0.5, 49) rotY 0 | d 16 | 2101 | X 2035–2131, north |
| 8 | 2454 | −1 | 14 | (2454, 0, −28) / 60×0.2×24 | (2454, 0.5, −49) rotY 180 | d 22 | 2472 | X 2406–2502, south |
| 9 | 2858 | +1 | 14 | (2858, 0, 28) / 60×0.2×24 | (2858, 0.5, 49) rotY 0 | d 16 | 2876 | X 2810–2906, north |
| 10 | 3456 | −1 | 16 | (3456, 0, −28) / 66×0.2×26 | (3456, 0.5, −50) rotY 180 | d 22 | 3474 | X 3408–3504, south |

**HerdSpawn points as (x, z)**, SpawnIndex 1–8 in order:

| # | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| 1 | (509, 23) | (519, 23) | (509, 33) | (519, 33) | (537, 23) | (547, 23) | (537, 33) | (547, 33) |
| 2 | (688, −23) | (698, −23) | (688, −33) | (698, −33) | (716, −23) | (726, −23) | (716, −33) | (726, −33) |
| 3 | (899, 23) | (909, 23) | (899, 33) | (909, 33) | (927, 23) | (937, 23) | (927, 33) | (937, 33) |
| 4 | (1140, −22) | (1152, −22) | (1140, −34) | (1152, −34) | (1172, −22) | (1184, −22) | (1172, −34) | (1184, −34) |
| 5 | (1415, 22) | (1427, 22) | (1415, 34) | (1427, 34) | (1447, 22) | (1459, 22) | (1447, 34) | (1459, 34) |
| 6 | (1722, −22) | (1734, −22) | (1722, −34) | (1734, −34) | (1754, −22) | (1766, −22) | (1754, −34) | (1766, −34) |
| 7 | (2058, 21) | (2072, 21) | (2058, 35) | (2072, 35) | (2094, 21) | (2108, 21) | (2094, 35) | (2108, 35) |
| 8 | (2429, −21) | (2443, −21) | (2429, −35) | (2443, −35) | (2465, −21) | (2479, −21) | (2465, −35) | (2479, −35) |
| 9 | (2833, 21) | (2847, 21) | (2833, 35) | (2847, 35) | (2869, 21) | (2883, 21) | (2869, 35) | (2883, 35) |
| 10 | (3428, −20) | (3444, −20) | (3428, −36) | (3444, −36) | (3468, −20) | (3484, −20) | (3468, −36) | (3484, −36) |

### 6.5 Prop placement (deterministic)

**Landmarks** use the exact world coordinates given in §7 and are placed first. **Scattered props** use a seeded scatter, so every build is identical:

```lua
-- per area a, per recipe r (RecipeIndex = order listed in §7), count n, radius rr
local rng = Random.new(a.AreaIndex * 100 + r.RecipeIndex)
for i = 1, r.Count do
	for try = 1, 60 do
		local x = rng:NextNumber(a.StartX + 14, a.EndX - 14)
		local side = (rng:NextInteger(0, 1) == 0) and -1 or 1
		local z = side * rng:NextNumber(r.BandMin or 26, r.BandMax or 56)
		local blocked = (side == a.HerdSide and math.abs(x - a.HerdX) < 48)
			or tooClose(x, z, rr)            -- any placed prop/landmark closer than rr + rOther + 2
		if not blocked then
			place(r, x, z, r.FixedYaw or rng:NextNumber(0, 360)); break
		end
	end
end
```

The default band keeps props on the shoulders (|Z| 26–56) and never on the trail. A few recipes use their own placement rule, stated with the recipe.

---

## 7. Areas 1–10: themes, materials, props

**SAE gives no text description of what most biomes look like.** Ground, sky, props and art style are undocumented, so **every theme detail below is [assumed]**. The only exceptions are the landmarks marked **[SAE]**, which copy layout facts found in vault-part and secret guides.

Every area has the 29 fixed parts from §6.3 plus its props. Recipe lines read `shape @(offset) Material r,g,b`; "r" is the spacing radius.

### Area 1: Dusty Prairie · `0 SPEED` · Alpha Ol' Stompy (Bull) · herd north (SAE: Forest)

Sunny open range: dry golden grass, a few oaks, hay and split-rail fences. It's the tutorial area, wide and readable.

- **Ground:** trail Ground 170,132,90 · shoulders Grass 150,172,88
- **Cliffs (H 18, low bluffs):** wall Ground 182,146,100 · crest Grass 120,150,70 · toe Ground 170,134,92
- **Arch:** posts Wood 122,84,50 · caps Ball Wood 122,84,50 · board WoodPlanks 176,128,78, text 60,36,20
- **Herd:** HerdZone Grass 176,196,104 (pasture) · AlphaBed Grass 220,190,100 (hay)

Props:
1. **Oak tree** ×6 (3 parts, 18 total; r 7): `VCyl 10×2.5 @(0,5,0)` Wood 110,76,48 · `Ball 11 @(0,13,0)` LeafyGrass 88,140,60 · `Ball 8 @(3,16,2)` LeafyGrass 104,156,70
2. **Hay bale** ×8 (1, 8; r 3): `HCylX 5×4 @(0,2,0)` Grass 220,190,100
3. **Split-rail fence** ×6 (4, 24; r 7): posts `VCyl 4×0.8 @(±6,2,0)` Wood 120,84,52 · rails `Block 13×0.5×0.4 @(0,1.5,0)` and `@(0,3,0)` Wood 120,84,52
4. **Wildflower clump** ×10 (2, 20; r 2; nc): `Ball 1.6 @(0,0.6,0)` SmoothPlastic 250,210,60 · `Ball 1.4 @(1.2,0.5,0.8)` SmoothPlastic 240,120,160
5. **Boulder** ×5 (2, 10; r 5): `Ball 6 @(0,1.5,0)` Slate 130,124,116 · `Ball 3.5 @(3,1,1.5)` Slate 140,134,126
6. **Tumbleweed** ×6 (1, 6; r 2; nc): `Ball 3 @(0,1.5,0)` Grass 170,140,90 T0.1
7. **Landmark: windmill** ×1 (8) at world **(472, 0, −44)**, fan facing +Z: tower `Block 3×20×3 @(0,10,0)` Wood 130,92,56 · hub `HCylZ 2×2 @(0,20,2)` Metal 150,150,155 · blades `Block 1×7×0.3 @(0,23.5,3.2)`, `@(0,16.5,3.2)`, `Block 7×1×0.3 @(±3.5,20,3.2)` SmoothPlastic 230,225,210 · tail `Block 0.3×3×5 @(0,20,−3)` Metal · tank `VCyl 4×6 @(6,2,0)` CorrodedMetal 120,110,100
8. **Landmark: covered wagon** ×1 (7) at world **(542, 0, −40)**: body `Block 10×3×5 @(0,3,0)` WoodPlanks 150,104,62 · bonnet `HCylX 10×6 @(0,5,0)` Fabric 236,228,208 · wheels `HCylZ 0.6×4 @(±3.5,2,±2.8)` Wood 90,60,36

Props total 101; area total 130.

### Area 2: Cactus Canyon · `900 SPEED` · Rattlesnake King · herd south (SAE: Lake)

A red-rock slot canyon with saguaros, hoodoos and bleached skulls. A small spring-fed oasis nods to SAE's Lake.

- **Ground:** trail Ground 196,138,92 · shoulders Sand 226,170,112
- **Cliffs (H 32):** wall Sandstone 196,104,64 · crest Sandstone 222,142,92 · toe Sandstone 170,90,56
- **Arch:** posts Sandstone 186,104,70 · caps Ball Marble 240,232,214 · board WoodPlanks 160,110,70
- **Herd:** HerdZone Sand 232,196,140 · AlphaBed Slate 150,120,96

Props:
1. **Saguaro** ×8 (6, 48; r 5): trunk `VCyl 14×3 @(0,7,0)` · top `Ball 3 @(0,14,0)` · arm `Block 2.5×1.8×1.8 @(−2.4,6,0)` + `VCyl 5×1.8 @(−3.6,8.5,0)` · arm `Block 2.5×1.8×1.8 @(2.4,8.5,0)` + `VCyl 4×1.8 @(3.6,10.5,0)`, all Grass 74,128,64
2. **Barrel cactus** ×10 (2, 20; r 2): `Ball 3 @(0,1.2,0)` Grass 90,140,70 · flower `Ball 0.9 @(0,2.7,0)` SmoothPlastic 255,90,140
3. **Hoodoo pillar** ×4 (3, 12; r 4): `VCyl 10×6 @(0,5,0)` Sandstone 200,120,80 · `VCyl 5×4.5 @(0,12.5,0)` Sandstone 220,150,100 · `Ball 6 @(0,15.5,0)` Sandstone 180,100,70
4. **Cattle skull** ×3 (4, 12; r 2): `Ball 2.4 @(0,1,0)` · snout `Block 1.4×1×1.8 @(0,0.8,1.4)` · horns `HCylX 2.5×0.5 @(±1.8,1.6,0)`, all Marble 240,232,214
5. **Mesa boulder** ×5 (2, 10; r 5): `Ball 7 @(0,2,0)` Sandstone 190,110,72 · `Ball 4 @(3.5,1.2,−1.5)` Sandstone 205,125,85
6. **Wanted poster** ×2 (3, 6; r 3): posts `VCyl 6×0.6 @(±2,3,0)` Wood 110,76,46 · board `Block 5×3.5×0.3 @(0,4.5,0)` WoodPlanks 214,186,140, SurfaceGui both faces `WANTED · RATTLESNAKE KING` (SpecialElite)
7. **Tumbleweed** ×6 (1, 6): as in Area 1
8. **Landmark: oasis spring** ×1 (6) at world **(642, 0, 42)**: pool `VCyl 0.4×18 @(0,0.05,0)` SmoothPlastic 70,160,200 T0.25 Refl0.2 nc · wet rim `VCyl 0.3×21 @(0,0.02,0)` Sand 170,130,90 nc · 2 palms: trunk `VCyl 12×1.6 @(±7,6,5)` Wood 140,100,60 + fronds `Ball 6 @(±7,12.5,5)` LeafyGrass 80,150,60

Props total 120; area total 149.

### Area 3: Gold Rush Mine · `10K SPEED` · Big Digger (giant mole) · herd north (SAE: Desert)

A rocky gulch dug into an open-pit gold mine: timber frames, minecarts on rails, glinting ore and a boarded mine mouth.

- **Ground:** trail Ground 120,98,78 · shoulders Pebble 128,112,96
- **Cliffs (H 36):** wall Slate 92,84,80 · crest Rock 110,100,92 · toe Pebble 110,98,86
- **Arch:** posts Wood 110,78,46 · caps Ball Neon 255,190,90 (lanterns) · board WoodPlanks 130,92,56
- **Herd:** HerdZone Ground 150,120,90 · AlphaBed Mud 110,84,60

Props:
1. **Timber frame** ×6 (3, 18; r 7): posts `Block 1.5×12×1.5 @(±5,6,0)` · beam `Block 12×1.5×1.5 @(0,12.75,0)`, Wood 110,78,46
2. **Minecart** ×4 (6, 24; r 4): tub `Block 5×3×3.5 @(0,2.5,0)` CorrodedMetal 110,96,86 · ore `Ball 3.6 @(0,3.8,0)` Foil 240,190,60 · wheels `HCylZ 0.4×1.6 @(±1.7,0.8,±1.9)` Metal 60,60,64
3. **Rail track** ×3 (3, 9; r 12; **FixedYaw 0** so it runs along X; band 30–50): rails `Block 24×0.3×0.4 @(0,0.15,±1.6)` Metal 90,90,96 · bed `Block 24×0.1×4.4 @(0,0.05,0)` WoodPlanks 110,80,56
4. **Gold ore cluster** ×8 (3, 24; r 3): `Ball 3 @(0,1,0)` Foil 255,196,40 · `Ball 2 @(1.5,0.8,1)` Neon 255,210,80 · `Ball 4 @(−1.4,1.2,−0.8)` Slate 100,92,86
5. **Lantern post** ×6 (3, 18; r 2): pole `VCyl 8×0.6 @(0,4,0)` Wood · arm `Block 1.6×0.3×0.3 @(0.8,7.8,0)` Wood · lantern `Ball 1.2 @(1.6,7.2,0)` Neon 255,180,80 + PointLight Range 14, Brightness 1.5, Shadows off
6. **Dynamite crate** ×4 (3, 12; r 2): `Block 3×2.4×2.4 @(0,1.2,0)` WoodPlanks 160,112,64 · sticks `HCylX 2.6×0.6 @(0,2.7,±0.5)` SmoothPlastic 200,40,40
7. **Rock pile** ×5 (2, 10; r 4): `Ball 5 @(0,1.5,0)` Slate 100,92,86 · `Ball 3 @(2.4,1,1)` Pebble 128,112,96
8. **Landmark: mine mouth** ×1 (6), against the south cliff, in world coordinates: opening `Block 14×12×1 @(844, 6, −56)` SmoothPlastic 20,18,16 · posts `Block 1.6×13×1.6 @(836.2, 6.5, −55)` and `@(851.8, 6.5, −55)` Wood · lintel `Block 17×1.6×1.6 @(844, 13.3, −55)` Wood · sign `Block 8×2×0.3 @(844, 15, −54.8)` WoodPlanks, SurfaceGui Back `BIG DIGGER MINE CO.` · rail spur `Block 4×0.3×10 @(844, 0.15, −49)` Metal 90,90,96

Props total 121; area total 150.

### Area 4: Bayou Swamp · `40K SPEED` · Croc King · herd south (SAE: Jungle)

A misty swamp crossed by a plank causeway: cypress trees, green pools, fireflies and a shack on stilts.

- **Ground:** trail WoodPlanks 116,90,60 (causeway) · shoulders Mud 84,74,50
- **Cliffs (H 28, a wall of foliage):** wall LeafyGrass 52,78,44 · crest LeafyGrass 40,64,36 · toe Mud 70,62,44
- **Arch:** posts Wood 90,70,50 · caps Ball LeafyGrass 70,100,50 · board WoodPlanks 100,80,56
- **Herd:** HerdZone Grass 70,100,56 · AlphaBed Mud 70,60,44

Props:
1. **Cypress** ×8 (4, 32; r 7): flare `VCyl 3×5 @(0,1.5,0)` · trunk `VCyl 16×2.6 @(0,9,0)` Wood 92,74,54 · canopy `Ball 12 @(0,18,0)` LeafyGrass 60,92,50 · moss `Block 0.4×6×6 @(0,13,0)` Grass 110,130,80 T0.2 nc
2. **Swamp pool** ×5 (2, 10; r 9; nc): water `VCyl 0.4×16 @(0,0.05,0)` SmoothPlastic 60,92,70 T0.2 Refl0.15 · rim `VCyl 0.3×18 @(0,0,0)` Mud 70,62,44
3. **Lily pads** ×5 (3, 15; nc; **one per pool**, at pool origin + (3, 0, 2)): `VCyl 0.2×2.4 @(0,0.15,0)`, `@(1.8,0.15,1)`, `@(−1.5,0.15,1.6)` LeafyGrass 80,140,60
4. **Reed clump** ×8 (3, 24; r 2; nc): `VCyl 4×0.3 @(0,2,0)` · `VCyl 3.4×0.3 @(0.6,1.7,0.4)` Grass 110,130,70 · cattail `VCyl 1×0.6 @(0,4.3,0)` SmoothPlastic 100,70,40
5. **Fallen log** ×4 (2, 8; r 6): `HCylX 10×2.2 @(0,1,0)` Wood 90,70,50 · moss `Block 5×0.4×2 @(1,2.1,0)` Grass 90,120,60
6. **Firefly cluster** ×6 (3, 18; nc; no shadows): `Ball 0.4` Neon 210,255,120 at `(0,3,0)`, `(1.5,4,1)`, `(−1,5,−1.2)`
7. **Croc-snout rock** ×3 (3, 9; r 4): `Block 6×1×2 @(0,0.3,0)` Grass 70,90,50 · eyes `Ball 0.8 @(−2.2,0.9,±0.6)` Neon 255,220,60
8. **Landmark: stilt shack** ×1 (9) at world **(1078, 0, 46)**, door facing −Z: stilts `VCyl 6×1 @(±5,3,±4)` Wood 90,70,50 · floor `Block 12×1×10 @(0,6.5,0)` WoodPlanks 116,90,60 · walls `Block 10×6×8 @(0,10,0)` Wood 110,86,60 · roof `Wedge 12×3×5 @(0,14.5,2.5) rotY 180` and `Wedge 12×3×5 @(0,14.5,−2.5)` WoodPlanks 80,64,48 · door `Block 2.4×4×0.2 @(0,9,−4.1)` SmoothPlastic 30,24,20

Props total 125; area total 154.

### Area 5: Frost Peak · `170K SPEED` · Yeti Moose · herd north (SAE: Snow)

A snowy mountain pass with tiered pines, ice crystals, snowmen and an igloo. **Ice and Glacier are slippery** (Roblox's default friction), so they are used only on decor and on the two frozen ponds, which are slippery on purpose.

- **Ground:** trail Snow 204,212,222 · shoulders Snow 236,240,246
- **Cliffs (H 40):** wall Rock 150,160,175 · crest Snow 240,244,250 · toe Snow 225,232,240
- **Arch:** posts Ice 170,210,240 T0.1 · caps Ball Ice · board WoodPlanks 120,86,56, plus **1 extra part**: snow cap `Block 1.8×1×68 @(1264, 36.5, 0)` Snow
- **Herd:** HerdZone Snow 250,252,255 · AlphaBed Glacier 200,225,245

Props:
1. **Tiered pine** ×10 (4, 40; r 6): trunk `VCyl 4×1.6 @(0,2,0)` Wood 90,64,44 · tiers `VCyl 4×12 @(0,5,0)` and `VCyl 4×9 @(0,9,0)` LeafyGrass 40,84,60 · top tier `VCyl 4×6 @(0,13,0)` Snow 240,244,250
2. **Snow boulder** ×6 (2, 12; r 4): `Ball 7 @(0,2,0)` Rock 160,168,180 · cap `Ball 6 @(0,3.4,0)` Snow
3. **Ice crystal** ×8 (3, 24; r 3): `Block 2×8×2 @(0,4,0) rotZ 15` · `Block 1.4×5×1.4 @(1.4,2.5,0.8) rotZ −20` · `Block 1.2×4×1.2 @(−1,2,−1) rotX 25`, Ice 160,220,255 T0.2
4. **Snowman** ×3 (5, 15; r 3): `Ball 5 @(0,2.5,0)` · `Ball 3.6 @(0,6.3,0)` · `Ball 2.6 @(0,9.2,0)` Snow · nose `HCylZ 1.2×0.4 @(0,9.2,1.6)` SmoothPlastic 255,140,40 · hat `VCyl 1.6×2 @(0,11,0)` SmoothPlastic 25,25,30
5. **Log pile** ×4 (3, 12; r 4): `HCylX 6×1.4 @(0,0.7,±0.75)` and `@(0,1.9,0)` Wood 110,80,54
6. **Snow drift** ×6 (1, 6; r 5): `Ball 8 @(0,−2,0)` Snow
7. **Frozen pond** ×2 (1, 2; r 10; band 30–50): `VCyl 0.3×20 @(0,0.1,0)` Glacier 180,215,240 (CanCollide true, slippery)
8. **Landmark: igloo** ×1 (3) at world **(1324, 0, −44)**, entrance facing +Z: dome `Ball 16 @(0,0,0)` Snow (half buried, so it reads as a dome) · tunnel `HCylZ 5×6 @(0,1.5,8)` Snow · door `Block 3×3.5×0.2 @(0,1.75,10.6)` SmoothPlastic 20,20,24

Props total 114; area total 144 (including the snow cap).

### Area 6: Volcano Ridge · `700K SPEED` · Magma Ox · herd south (SAE: Volcano)

Black basalt and glowing cracked-lava ground, with charred trees, lava pools and lava falls down the cliffs. All lava is **decorative and does no damage [assumed]**.

- **Ground:** trail CrackedLava 90,60,50 · shoulders Basalt 58,52,52
- **Cliffs (H 44):** wall Basalt 50,44,44 · crest Rock 70,60,58 · toe Basalt 44,40,40
- **Arch:** posts Basalt 60,50,50 · caps Ball Neon 255,110,30 · board Slate 60,50,48, text 255,150,60
- **Herd:** HerdZone Ground 80,64,58 · AlphaBed CrackedLava 120,60,40

Props:
1. **Landmark: stepped mini-volcano** ×1 (7) at world **(1712, 0, 40)**. This is **[SAE]**: SAE's Volcano has "a small volcano-like structure on the right side [of the centre] with boiling lava on top", built from stepped blocks you can climb. Parts: `VCyl 6×30 @(0,3,0)` Basalt 56,48,48 · `VCyl 6×22 @(0,9,0)` Basalt 66,56,54 · `VCyl 6×14 @(0,15,0)` Rock 80,64,60 · lava `VCyl 0.6×10 @(0,18.1,0)` Neon 255,110,30 · bubbles `Ball 2 @(2,18.4,1)`, `Ball 1.6 @(−2,18.4,−1.5)` Neon 255,170,60 · `SmokeVent` `Block 2×2×2 @(0,20,0)` invisible + ParticleEmitter (smoke). The 6-stud steps are jumpable. SAE's version is hollow inside; ours is solid, with a hollow interior reserved for a later secret (`SecretSpot` "VolcanoCore", added when that secret is built).
2. **Lava pool** ×5 (2, 10; r 7; nc): `VCyl 0.4×12 @(0,0.05,0)` Neon 255,100,20 · rim `VCyl 0.5×14 @(0,0,0)` Basalt 40,36,36
3. **Obsidian spike** ×8 (2, 16; r 3): `Block 2.5×9×2.5 @(0,4.5,0) rotZ 10` · `Block 1.6×6×1.6 @(1.6,3,0.8) rotZ −15`, Glass 30,20,40 Refl0.2
4. **Charred tree** ×6 (3, 18; r 4): `VCyl 12×1.6 @(0,6,0)` · `Block 5×0.8×0.8 @(1.8,9,0) rotZ 30` · `Block 4×0.7×0.7 @(−1.6,10.5,0) rotZ −35`, Wood 40,34,30
5. **Magma rock** ×8 (2, 16; r 4): `Ball 6 @(0,1.8,0)` CrackedLava 70,50,44 · `Ball 3 @(2.6,1,1.4)` Basalt 58,52,52
6. **Lava fall** ×4 (2, 8; fixed): fall `Block 6×30×1` Neon 255,120,30 T0.1 nc at `(X, 15, ±63.4)`, plus splash `VCyl 0.4×8` Neon at `(X, 0.05, ±54)` nc. Placed at X = 1592 (N), 1672 (S), 1772 (N), 1842 (S).
7. **Ember brazier** ×4 (3, 12; r 3): stand `VCyl 3×1 @(0,1.5,0)` · bowl `VCyl 1.5×4 @(0,3.75,0)`, Metal 60,56,56 · fire `Ball 2.6 @(0,5,0)` Neon 255,140,40 + Fire + PointLight Range 16, Shadows off
8. **Ash dune** ×4 (1, 4; r 6): `Ball 10 @(0,−3,0)` Ground 90,80,76

Props total 91; area total 120.

### Area 7: Storm Mesa · `2.5M SPEED` · Storm Griffin · herd north (SAE: Abyss Ocean)

A high, wind-swept mesa under a permanent thunderstorm: stacked rock spires, lightning rods, cyan storm crystals and low clouds.

- **Ground:** trail Ground 128,116,104 · shoulders Slate 112,112,122
- **Cliffs (H 40):** wall Slate 84,86,98 · crest Rock 100,102,116 · toe Slate 96,96,108
- **Arch:** posts Slate 90,92,104 · caps Ball Neon 120,220,255 · board Metal 80,84,92, text 255,230,90
- **Herd:** HerdZone Grass 110,124,104 · AlphaBed Wood 110,86,60 (stick nest)

Props:
1. **Rock spire** ×6 (3, 18; r 6): `VCyl 12×8 @(0,6,0)` Slate 100,100,112 · `VCyl 10×5.5 @(0,17,0)` Slate 116,116,128 · `VCyl 6×3 @(0,25,0)` Slate 130,130,140
2. **Lightning rod** ×6 (3, 18; r 2): base `Block 2×1×2 @(0,0.5,0)` · pole `VCyl 14×0.6 @(0,7,0)`, Metal 150,150,160 · tip `Ball 1.2 @(0,14.4,0)` Neon 140,230,255
3. **Storm crystal** ×8 (2, 16; r 3): `Block 1.8×6×1.8 @(0,3,0) rotZ 15` Neon 120,210,255 T0.15 · `Block 1.2×4×1.2 @(1.2,2,0.6) rotZ −20` Glass 180,230,255
4. **Storm cloud** ×6 (3, 18; nc; no shadows; **origin y 60**, X anywhere in the area, Z random ±40): `Ball 18 @(0,0,0)` · `Ball 14 @(10,−2,3)` · `Ball 12 @(−9,−1,−4)` SmoothPlastic 90,94,108 T0.15
5. **Windswept tree** ×5 (3, 15; r 4): trunk `VCyl 10×1.4 @(0,5,0) rotZ 12` · `Block 5×0.6×0.6 @(1.5,8,0) rotZ 25` · `Block 4×0.5×0.5 @(−1.2,9.5,0.5) rotZ −30`, Wood 96,84,72
6. **Boulder** ×6 (2, 12; r 5): `Ball 7 @(0,2,0)` Slate 100,100,112 · `Ball 4 @(3,1.2,1)` Rock 110,110,120
7. **Landmark: cave hole in the right wall** ×1 (5). This is **[SAE]**: in Abyss Ocean you "go through a small hole on the right side" to reach a hidden lab. World parts: opening `Block 8×9×1 @(1960, 4.5, 57)` SmoothPlastic 12,12,16 · frame `Ball 4 @(1955.5, 2, 57.5)` and `@(1964.5, 2, 57.5)` Slate 84,86,98 · lintel `Ball 5 @(1960, 9, 57.5)` Slate · `SecretSpot` `Block 4×4×4 @(1960, 2, 55)` invisible, `SecretId="StormVault"`. The interior is not built yet; the opening stays solid until then.
8. **Landmark: broken windmill** ×1 (4) at world **(2132, 0, −44)**: tower `Block 3×18×3 @(0,9,0) rotZ 6` Wood 96,80,66 · hub `HCylZ 2×2 @(0,18,2)` Metal 150,150,155 · two blades only (`Block 1×7×0.3 @(0,21.5,3.2)`, `Block 7×1×0.3 @(−3.5,18,3.2)`) SmoothPlastic 200,196,186

Props total 106; area total 135. Client weather: rain, plus a lightning flash (ColorCorrection Brightness +0.3 for 0.1 s) every 8–15 s.

### Area 8: Dino Badlands · `17M SPEED` · Rodeo Rex (T-Rex) · herd south (SAE: Prehistoric)

Red badlands with pockets of prehistoric jungle: giant ferns, cycads, fossil bones, tar pits and steam geysers, plus a huge ribcage arching over the trail.

- **Ground:** trail Ground 156,104,70 · shoulders Grass 112,140,64
- **Cliffs (H 44):** wall Sandstone 170,96,66 · crest Sandstone 196,128,86 · toe Ground 150,100,70
- **Arch:** posts Marble 236,226,200 (giant bones) · caps Ball Marble · board WoodPlanks 120,86,56
- **Herd:** HerdZone LeafyGrass 92,132,56 · AlphaBed Grass 120,150,70 (d 22, for the big Rex)

The herd is on the **left (south)** on purpose. In SAE's Prehistoric, "the big T-Rex [is] on the left", sleeping in "a grass and bush clearing" with "green platforming blocks" near its head **[SAE]**.

Props:
1. **Giant fern** ×10 (4, 40; r 4): 4 × `Wedge 1.5×5×5` LeafyGrass 70,130,50, each with its slope facing outward: `@(0,2.5,2.5) rotY 180`, `@(0,2.5,−2.5)`, `@(2.5,2.5,0) rotY −90`, `@(−2.5,2.5,0) rotY 90`
2. **Cycad palm** ×6 (4, 24; r 5): trunk `VCyl 8×2.2 @(0,4,0)` Wood 110,86,56 · 3 fronds `Wedge 1.5×3×7` LeafyGrass 80,140,60 at `(3.5cosθ, 9, 3.5sinθ)` for θ = 0°, 120°, 240°, each yawed so the low edge points outward
3. **Fossil bone** ×5 (3, 15; r 4): `HCylX 6×1 @(0,0.5,0)` · knobs `Ball 1.6 @(±3,0.6,0)`, Marble 236,226,200
4. **Tar pit** ×3 (2, 6; r 7; nc): `VCyl 0.4×12 @(0,0.05,0)` SmoothPlastic 20,18,22 Refl0.3 · bubble `Ball 1.5 @(2,0.3,1)` SmoothPlastic 30,28,32
5. **Steam geyser** ×3 (3, 9; r 4): mound `VCyl 1.5×6 @(0,0.75,0)` Rock 130,110,90 · vent `VCyl 0.3×2 @(0,1.6,0)` SmoothPlastic 20,20,20 · `Block 1×1×1 @(0,2,0)` invisible + ParticleEmitter (steam)
6. **Boulder** ×6 (2, 12; r 5): `Ball 7 @(0,2,0)` Sandstone 170,96,66 · `Ball 4 @(3,1.2,1)` Sandstone 196,128,86
7. **Landmark: green step blocks + bush clearing** ×1 (9) **[SAE]**, in world coordinates:
   - step blocks `Block 6×1.5×6` Grass 90,170,70 at (2414, 2, −40), (2406, 5, −44), (2398, 8, −50), (2404, 11, −55), (2412, 14, −56)
   - `SecretSpot` `Block 2×2×2 @(2412, 16, −56)` invisible, `SecretId="RexLookout"`
   - bushes `Ball 5` LeafyGrass 70,120,50 at (2442, 1.8, −58), (2454, 1.8, −60), (2466, 1.8, −58), behind the sleeping Alpha
8. **Landmark: ribcage over the trail** ×1 (7): 6 ribs `Block 1.5×31×1.5` Marble 236,226,200 at X = 2514, 2524, 2534 and Z = ±12, y 12, each leaning its top toward Z = 0 by 40° (`rotX −40` for +Z ribs, `rotX 40` for −Z ribs). Spine `Block 26×1.5×1.5 @(2524, 24.5, 0)`. Rib feet land at |Z| about 22 (just off the trail), and the clear height over the trail is about 24.

Props total 122; area total 151.

### Area 9: Ghost Town · `150M SPEED` · Phantom Steed · herd north (ours; between SAE's Prehistoric and Cosmic)

An abandoned frontier town at eternal midnight: false-front buildings lining both shoulders (a spooky echo of our own Main Street), Boot Hill graveyard, green ghost lanterns and drifting wisps. It borrows the mood of SAE's Halloween Dimension.

- **Ground:** trail Ground 110,100,92 · shoulders Grass 74,80,68 (dead grass)
- **Cliffs (H 36):** wall Rock 60,58,66 · crest Slate 70,66,80 · toe Ground 70,66,62
- **Arch:** posts Wood 70,60,56 · caps Ball Neon 110,255,170 · board WoodPlanks 90,80,70, text 170,255,210, font Creepster
- **Herd:** HerdZone Ground 100,96,90 · AlphaBed Slate 60,70,70

Props:
1. **False-front building** ×6 (4, 24; **fixed slots, facing the trail**: rotY 0 on the north side, 180 on the south side; |Z| 50): facade `Block 16×16×1 @(0,8,0)` WoodPlanks 110,96,82 · body `Block 14×10×10 @(0,5,5.5)` Wood 90,80,70 · window `Block 4×3×0.2 @(−4,9,−0.6)` Neon 120,255,180 T0.4 · door `Block 3×6×0.2 @(3,3,−0.6)` SmoothPlastic 20,20,20. Facade SurfaceGui Front names: SALOON, BANK, JAIL, HOTEL, ASSAY OFFICE, BARBER. Slots (X, side): (2650, N), (2712, N), (2800, S), (2860, S), (2920, S), (2980, S).
2. **Landmark: Boot Hill graveyard** ×1 (20) at world **(2716, 0, −44)**: 8 tombstones `Block 2.4×3.2×0.6` Slate 110,110,116 and 4 crosses (`Block 0.5×4×0.5 @(·,2,·)` + `Block 2.4×0.5×0.5 @(·,3,·)` Wood 80,72,66) on a 4×3 grid at local X −9, −3, 3, 9 and Z −6, 0, 6 (crosses on the 4 corners) · picket fence `Block 26×3×0.4 @(0,1.5,±10)` and `Block 0.4×3×20 @(±13,1.5,0)` Wood 80,72,66
3. **Dead tree** ×6 (4, 24; r 4): `VCyl 14×1.6 @(0,7,0)` · `Block 5×0.7×0.7 @(1.8,10,0) rotZ 35` · `Block 4×0.6×0.6 @(−1.5,11.5,0.4) rotZ −40` · `Block 3×0.5×0.5 @(0.6,13,−1) rotX 30`, Wood 54,48,46
4. **Ghost lantern post** ×6 (3, 18; r 2): pole `VCyl 9×0.5 @(0,4.5,0)` Wood 54,48,46 · arm `Block 1.6×0.3×0.3 @(0.8,8.8,0)` · lantern `Ball 1.2 @(1.6,8.2,0)` Neon 110,255,170 + PointLight Range 14, Color 110,255,170, Shadows off
5. **Broken wagon** ×2 (4, 8; r 5): body `Block 8×2×4 @(0,1.5,0) rotZ 8` WoodPlanks 90,80,70 · 3 wheels (one missing) `HCylZ 0.6×4 @(−3,2,2.3)`, `@(3,2,2.3)`, `@(−3,2,−2.3)` Wood 60,52,48
6. **Wisp** ×8 (1, 8; nc; no shadows; y 3–8): `Ball 1.4` Neon 170,255,220 T0.3; the client bobs them up and down
7. **Tumbleweed** ×6 (1, 6): `Ball 3` Grass 110,100,80
8. **Landmark: water tower** ×1 (6) at world **(2938, 0, 48)**: legs `Block 1×16×1 @(±4,8,±4)` Wood 80,70,62 · tank `VCyl 8×10 @(0,20,0)` WoodPlanks 90,80,70 · roof `VCyl 1×11 @(0,24.5,0)` Wood 60,52,48

Props total 114; area total 143.

### Area 10: Cosmic Rift · `700M SPEED` · Cosmic Kraken-Cow · herd south, far end (SAE: Cosmic)

The prairie torn open into space: dark violet rock, glowing rift cracks, crystal pillars, floating islands, ringed planets and an aurora. It's the **longest area** (576), and the herd sits at **75%**, near the far end **[SAE]**: Cosmic is the longest stretch, and its Huge egg nest is at the far end under a 700M signpost.

- **Ground:** trail Slate 56,46,92 · shoulders Slate 46,36,76
- **Cliffs (H 48):** wall Basalt 34,28,54 · crest Glass 110,80,200 T0.1 · toe Slate 40,32,64
- **Arch:** posts Glass 120,90,220 · caps Ball Neon 200,140,255 · board SmoothPlastic 24,18,40, text 200,160,255, font Michroma
- **Herd:** HerdZone Slate 80,60,130 · AlphaBed Neon 140,90,255 T0.4 (d 22)

Props:
1. **Floating island** ×6 (3, 18; nc; origin y 30–50, Z ±40): `Ball 14 @(0,0,0)` Slate 60,48,96 · top `Block 12×2×12 @(0,6,0)` LeafyGrass 110,90,200 · `Block 1.5×5×1.5 @(2,9,1)` Neon 220,160,255
2. **Crystal pillar** ×10 (3, 30; r 4): `Block 3×14×3 @(0,7,0) rotZ 8` Glass 150,110,255 T0.1 · `Block 2×9×2 @(2,4.5,1) rotZ −12` Neon 200,150,255 · `Block 1.6×6×1.6 @(−1.6,3,−1)` Glass 150,110,255
3. **Rift crack** ×8 (1, 8; nc; **band |Z| 0–56, so cracks may cross the trail**): `Block 24×0.2×1.2 @(0,0.02,0)` Neon 180,90,255
4. **Planet** ×3 (2, 6; nc; fixed, outside the walls): `Ball 60` SmoothPlastic + ring `VCyl 0.5×100 rotX 20` Neon 255,220,160 T0.5 at (3144, 170, 260) colour 220,120,90, (3354, 200, −300) colour 90,160,255, and (3544, 150, 220) colour 255,200,120
5. **Star mote** ×12 (1, 12; nc; no shadows; y 10–40): `Ball 0.8` Neon 255,255,255
6. **Glowing crater** ×4 (3, 12; r 9): rim `VCyl 1×18 @(0,0.3,0)` Basalt 40,34,60 · glow `VCyl 1.2×12 @(0,0.3,0)` Neon 255,120,60 · meteor `Ball 4 @(2,1.5,0)` CrackedLava 80,50,60
7. **Aurora ribbon** ×3 (1, 3; nc; no shadows; fixed): `Block 120×30×0.5` Neon 90,255,200 T0.7 at (3144, 90, 40), (3312, 95, 0) rotY 10, and (3480, 90, −40)
8. **Cosmic boulder** ×6 (2, 12; r 5): `Ball 8 @(0,2.5,0)` Slate 60,50,90 · `Ball 4 @(3,1.5,1)` Glass 150,110,255
9. **Landmark: Rift Gate** ×1 (9; all nc) over the trail at the far end. It's a glowing octagon you run through, and it marks where new areas attach. SAE's Angels and Demons is reached "through the portal" at the end of the track **[SAE; its look is undocumented]**. Build it as:
   - for k = 0..7: `CFrame.new(3584, 18, 0) * CFrame.Angles(math.rad(45*k), 0, 0) * CFrame.new(0, 14, 0)`, Size (1.5, 1.5, 11.6), Neon 200,140,255
   - disc `Cylinder 0.3×26×26 @(3584, 18, 0)` (axis X) Neon 160,80,255 T0.6

Props total 110; area total 139.

---

## 8. Lighting profiles (client-side)

Lighting is global in Roblox. A client `AreaLightingController` checks every 0.25 s which `AreaBounds` (or Town) contains the HumanoidRootPart, then tweens `Lighting.Atmosphere` and a `ColorCorrectionEffect` to that area's profile over 1.5 s. Store each profile as attributes on the Area model (or the Town folder): `AtmDensity`, `AtmHaze`, `AtmColor`, `AtmDecay`, `AtmGlare`, `CCTint`, `CCSaturation`, `CCContrast`, `CCBrightness`, `ClockOverride` (−1 = none), `Weather`. Sundown (CycleService) overrides ClockTime for its 10 s. Weather particles come from one camera-following emitter part on the client, which doesn't count toward the part budget. No source describes per-biome lighting in SAE, so these profiles are **[assumed]**.

Base Lighting: ClockTime 14.5, Brightness 2.5, Ambient 90,80,70, OutdoorAmbient 140,130,120, Technology ShadowMap, plus a BloomEffect at Intensity 0.4 (1.2 in Cosmic Rift).

| Zone | Density | Haze | Atm colour | Decay | Glare | CC tint | Sat | Contrast | Bright | Clock | Weather |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Town | 0.25 | 0.6 | 210,180,140 | 120,110,100 | 0 | 255,246,232 | 0.05 | 0 | 0 | — | none |
| 1 Prairie | 0.25 | 0.5 | 199,170,135 | 106,112,125 | 0 | 255,248,235 | 0.10 | 0 | 0 | — | none |
| 2 Canyon | 0.30 | 1.6 | 230,180,130 | 150,100,70 | 0.4 | 255,236,214 | 0.15 | 0.05 | 0 | — | dust |
| 3 Mine | 0.35 | 1.0 | 170,150,120 | 90,80,70 | 0 | 255,236,200 | 0 | 0.10 | −0.03 | — | dust |
| 4 Bayou | 0.45 | 2.0 | 120,150,110 | 60,80,60 | 0 | 225,255,225 | −0.05 | 0 | −0.02 | — | fireflies |
| 5 Frost | 0.40 | 1.2 | 220,230,245 | 150,170,200 | 0.6 | 235,245,255 | −0.10 | 0 | 0.05 | — | snow |
| 6 Volcano | 0.45 | 2.2 | 255,140,90 | 120,50,30 | 0.2 | 255,225,205 | 0.10 | 0.12 | 0 | — | embers |
| 7 Storm Mesa | 0.50 | 2.4 | 130,145,170 | 70,80,100 | 0 | 215,225,255 | −0.25 | 0.10 | −0.05 | — | rain + lightning |
| 8 Dino | 0.40 | 1.8 | 200,190,140 | 110,120,80 | 0 | 245,255,225 | 0.15 | 0 | 0 | — | none |
| 9 Ghost Town | 0.55 | 2.6 | 90,140,120 | 40,70,60 | 0 | 200,255,225 | −0.35 | 0.15 | 0 | 0 (night) | wisps |
| 10 Cosmic Rift | 0.35 | 1.2 | 150,110,255 | 40,20,90 | 1.0 | 230,215,255 | 0.20 | 0.15 | 0 | 0 (night) | star motes |

---

## 9. Runtime hooks the map supports

| System | How it uses the map |
|---|---|
| **Safe Zone** | CombatService: a whip or weapon hit is cancelled with a "Safe Zone" toast if the attacker **or** the target is `inBox` of any `SafeZone`. Bear traps can't be placed in any `SafeZone` **or** inside `TownBounds` **[GDD]**. |
| **Goal line / leash** | A chase ends when the towing player's X < 400 (`TownGate`). The Alpha then walks back to its `AlphaSpawn` along the `LaneWaypoint`s. `AlphaBlocker` backs this up physically **[SAE: the red line ends the chase]**. |
| **Beast bolt rule** | Caught while inside the Alpha's own `AreaBounds` → the beast returns to a free `HerdSpawn` in that area. Caught elsewhere → it stays loose where you fell **[GDD]**. |
| **Sundown (every 5 min)** | At 4:50: enable `SundownCurtain`, then teleport every character **outside `TownBounds`** to their `PlotSpawn` (or the SpawnLocation if they own no plot), restock herds and set taming to 30×. At 5:00: disable the curtain. In SAE, everyone outside the Safe Zone is teleported to spawn when the timer hits zero **[SAE]**. |
| **Plot yard** | Inside a rival's `PlotBounds`: weapons work, and you can rustle beasts that are still taming if `GateLock.Locked == false` **[GDD]**. |
| **Treadmill** | SpeedService counts steps while a character stands on `Belt` (zone test on a 14×4×7 box above it) and isn't towing **[GDD]**. |
| **Herds** | HerdService spawns beast models at `HerdSpawn` pivots when any player is within 400 studs of the area (or always, if under the beast budget). It keeps state on the server and sets the `Occupied` attribute. |
| **Streaming** | `Workspace.StreamingEnabled = true`, `StreamingMinRadius = 256`, `StreamingTargetRadius = 1024`. Area models use `ModelStreamingMode = Atomic` and `LevelOfDetail = StreamingMesh`, so far areas render as low-detail imposters. Town and the Plots are `Persistent`. |

---

## 10. Part budget (static map; target under about 3,000)

| Section | Parts |
|---|---|
| Town ground (6) + fence and boundary (55) + Town Gate (8) | 69 |
| Town Square fixtures | 47 |
| Trading Post | 15 |
| Street lamps and alley barrels | 32 |
| Zones (4 SafeZone + TownBounds) | 5 |
| Plots: 148 × 7 (section 13: rail fence, pen circle, gym treadmill and Upgrade Pen sign; no barn, decor, gate posts or lanterns) | 1,036 |
| **Town subtotal** | **1,204** |
| Lane globals (trailhead, walls, Frontier End, waypoints, Stampede markers) | 25 |
| Area fixed parts: 29 × 10, + 1 snow cap | 291 |
| Area props: 101 + 120 + 121 + 125 + 114 + 91 + 106 + 122 + 114 + 110 | 1,124 |
| **Lane subtotal** | **1,440** |
| **Total static map** | **2,644** |
| Headroom to 3,000 | about 350 (two weekly areas). Raise the target to about 4,000 when more areas arrive. StreamingEnabled keeps far areas unloaded, and anchored single-material parts batch well. |

Runtime models (herd beasts, Alphas, pen beasts, traps) are **not** in this budget. Keep each beast model at 30 parts or fewer and each Alpha at 60 or fewer. Lights: 34 PointLights (16 town lamps, 2 gate lanterns, 6 mine lanterns, 4 braziers, 6 ghost lanterns), all with `Shadows = false`.

---

## 11. Adding areas later (the weekly update rule)

New areas are appended at the far end, exactly as SAE adds biomes "onto the end of the track" **[SAE]**:
1. Set the new `StartX` to 3600 (later, the previous EndX). Choose a length of at least 576 (Cosmic Rift stays the longest of the launch set; later areas may be longer).
2. Move `FrontierEnd` to the new end, and extend `LaneWall_*2` (or add `LaneWall_*3` once you pass 2,048 studs per part).
3. Add `WPnn`, continue the herd side alternation (area 11 is north), and add the lighting profile and a prop set of about 170 parts or fewer.

The planned areas **[GDD]**:
- **Sakura Springs (2.5B):** a waterfall wall plus a tree-shaped incubator at the back of the area, matching SAE, whose Sakura Incubator sits at the back of Cherry Blossom **[SAE]**.
- **Titan Canyon (7B)**
- **Heaven & Hell Ranch (20B):** entered through a portal at the end of Titan Canyon; its form flips each Sundown.
- **Enchanted Frontier (50B)**

---

## 12. Assumptions (SAE unknowns we decided)

| Topic | Our choice | Why |
|---|---|---|
| Base arrangement | 4 + 3 plots facing each other across Main Street, which feeds straight into the lane | It's the genre standard, it matches 7-plot fan kits on a narrow (about 110-wide) strip, and every base empties onto one path |
| Safe Zone shape | Square, street, boardwalks, gate plaza and Trading Post. Plot yards excluded (GDD rustling twist). | SAE documents only the red line |
| Lane start | The centre of Town's east edge, via Main Street | Undocumented |
| Biome transitions | An arch with a sign at each area start, plus cliff and material changes; no gate barrier | SAE documents only Speed signs, perimeter walls and soft gates |
| Distances / WalkSpeed | §2 curve; 32-stud length steps; Cosmic Rift longest | No studs or formula published; Cosmic is the longest stretch |
| Nests | 2 patches × 4 points, Alpha on the cliff side, herd sign by the Alpha, herds alternating sides | SAE: several nests, several eggs each, guardian beside them, sign by the guardian. Counts unknown. |
| Visual themes | Everything in §7 except the [SAE] landmarks | No text source describes SAE biome visuals |
| Lava, tar and water | Decorative only, no damage | Undocumented |
| Plot assignment | Random free plot | Undocumented |
| Night closure | A 10 s Sundown curtain at the red line plus a teleport | SAE: map closed for about 10–13 s, with a teleport at zero |

---

## 13. Look: Steal An Egg's studded checkerboard (added 2026-10-20)

After building, `MapBuilder.applyStyle` restyles 109 parts using `AreasConfig.Style`:
- **Ground (top face):** SquareGround, RanchGroundN/S (green 118,214,38), MainStreet, BoardwalkN/S, Trailhead (path 128,118,140), PlotBase ×7 (104,198,30), and each area's TrailStrip and ShoulderN/S.
- **Walls (all faces):** the Town palisade (orange 205,120,55) and each area's WallN/S and CrestN/S. ToeN/S get studs and colour only.
- **Every restyled part:** Material Plastic and **Studs** surfaces (the top for ground, all six faces for walls). Colours come from `Style.Town`, `Style.AreaOverrides[i]` (area 1 = SAE's Forest: green with orange walls), or the area theme colour with saturation ×1.35 and brightness ×1.12.
- **Checkerboard:** once `Style.CheckerTexture`, or the workspace attribute `CheckerTexture`, holds an uploaded `game/assets/checker_studs.png`, each restyled face gets a `Texture` (StudsPerTileU/V = 8, Color3 black). That's 269 textures. The image is see-through apart from the dark squares and the stud shading, so the part colour shows through.
- Fonts on signs are GothamBlack. Text is white with a black outline (`strokeFor` gives a white outline only to very dark text).
- **Plot fence (replaces the 5 board fences and 4 round corner posts of section 5.3):** Steal An Egg's wooden rail fence. There are five runs (FrontW, FrontE, Left, Right, Back) along the old board lines. Each run has:
  - posts every 8 studs: `Block 1.2×6×1.2`, Wood 88,56,40, standing on the plot floor. The side runs skip their end posts, because the corners already have one.
  - two rails across the whole run at y 2.0 and 5.6: `Block len×0.5×0.4`, Wood 198,96,40.
  - an **X brace in every bay**: two `Block diag×0.45×0.3` pieces tilted ±atan(3.6/8) in the fence plane.

  That's 113 parts per plot, with names Post*/Rail*/Brace*. The five invisible colliders stay as they were.
- **Upgrade Pen sign** [UpgradeSign] (2 parts per plot, plot-local): post `Block 0.6×3.4×0.6 @(−17, 2.7, −37)` SmoothPlastic 30,30,36, and board `Block 6×3.6×0.4 @(−17, 5.8, −37)` SmoothPlastic 22,30,54 (navy). The board has a SurfaceGui Front with the lines `Upgrade Pen` / `Level 1 > Level 2` / price. RanchService fills them in and adds the ProximityPrompt (`Upgrade` / `Pen`), which only the owner can use.
- **Gate doors** (changed for the open rail fence): `GateDoorL/R` are now `Block 0.6×4×8 @(∓8.5, 3, −35)`, swung open into the pen so they don't show through the rails. The **Upgrade Pen sign** moved outside the fence onto the boardwalk at z −41.5 (post `0.6×4.4×0.6 @(−17, 2.2, −41.5)`), so you can read it from the street.
- **Steal An Egg-style base** (user screenshot, 2026-10-20). The plot now matches Steal An Egg's bases:
  - **Removed:** the barn (5 parts), the hay and trough decor (4), the gate posts and lanterns (4, so 14 fewer PointLights) and the gate doors (2). The entrance is just the gap in the fence.
  - **Pen floor:** `PenRing` `VCyl 0.2×60 @(0, 1.02, 0)` Neon white, under `PenFloor` `VCyl 0.3×57 @(0, 1.08, 0)` Glass 70,235,60 T0.1, both nc. Slot pads are invisible (T1); locked ones keep their LOCKED billboard.
  - **OwnerSign** is now an invisible `2×2×2` anchor at the pen centre. Its BillboardGui `OwnerTag` floats a round headshot and the username 22 studs up.
  - **Treadmill** is a grey gym treadmill: Base (150,150,160), Belt (40,40,44), UprightL/R `0.8×6×0.8` at x 26, RailL/R `12×0.5×0.5` at y 4.5, and Console `1.2×3×9.2 @(26.2, 7.6, −48)` rotZ 20 (28,28,32).
