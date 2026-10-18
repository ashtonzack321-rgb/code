---
tags: [my-game, gdd, scripting]
---
# Systems and Scripts (Roblox Studio plan)

Builds on [[Technical Architecture]].

```
ReplicatedStorage/
  Config/Beasts.lua         -- id, rarity, strength, income, biome, model
  Config/Lassos.lua         -- tier, sweetZoneSize, throwRange, price
  Config/Rebirths.lua
  Modules/NumberFormat.lua  -- 1.2K, 4.5M, 3.1B, 7.0T, 2.2Qa
  Remotes/
ServerScriptService/Services/
  DataService      -- ProfileStore, session lock
  CycleService     -- day/night clock, sets workspace attribute "Phase"
  StampedeService  -- spawns herds per biome, weighted rarity, path along splines
  LassoService     -- validates throw (range, LOS), runs tug state server-side
  CarryService     -- rope constraint drag, cut-rope, carry/steal, drop on hit
  RanchService     -- plots, pens, gates (open at night), 2-loss-per-night cap
  DefenseService   -- guard beast AI, traps
  BreedingService  -- os.time() timers, result roll
  IncomeService    -- 1s tick, offline earnings
  MarketService    -- gamepasses, ProcessReceipt
StarterPlayerScripts/Controllers/
  HUDController, TugController, CycleFXController (Lighting tweens), NotifyController
```

## Important implementation notes
- **Tug-of-war is anti-cheat sensitive.** The client sends inputs only ("pull pressed/released"), and the server simulates the marker and decides the result. Inputs above ~15/s are rejected.
- **Day/night:** a single server clock stored as an attribute. Clients tween Lighting (ClockTime, Ambient, ColorCorrection) themselves.
- **Rope:** use a RopeConstraint between the HumanoidRootPart and the beast, and set the beast's network owner to the server.
- **Stampedes:** move beasts along predefined paths with tweens or AlignPosition (cheap), rather than full pathfinding, so it scales.
- **Raid cap:** count losses per ranch per night server-side.
- Use **StreamingEnabled** with server size 8.

## Build order
1. Plot and pen and income (playable tycoon)
2. Stampede and lasso and tug
3. Carry and cut rope
4. Day/night and raids
5. Rebirth, Index, Breeding
6. UI polish, monetization, launch
