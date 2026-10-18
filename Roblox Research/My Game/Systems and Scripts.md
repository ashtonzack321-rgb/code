---
tags: [my-game, gdd, scripting]
updated: 2026-10-18
---
# Systems and Scripts (Roblox Studio plan, v2)

Builds on [[Technical Architecture]].

```
ReplicatedStorage/
  Config/Areas.lua          -- order, name, speedSign, alpha{chaseSpeed, model}, beastPool
  Config/Beasts.lua         -- id, area, rarity, baseIncome, baseKg, tameSeconds, model
  Config/Treadmills.lua     -- tier, speedPerStep, price
  Config/Spurs.lua          -- multiplier, cash price, robux productId
  Config/Weapons.lua        -- whip/index weapons: force, ragdollTime, range
  Modules/NumberFormat.lua  -- 1.2K 4.5M 3.1B 7.0T 2.2Qa
  Modules/Income.lua        -- base × mutation × (kg/baseKg)^0.617
  Remotes/
ServerScriptService/Services/
  DataService       -- ProfileStore + session lock (cash, speed, pen, index, gear)
  CycleService      -- 5-min clock: Day 4:50 → Sundown 10s (teleport, restock, 30× taming)
  HerdService       -- per-area restock: weighted rarity roll, kg roll, mutation roll, rare-spawn broadcast
  AlphaService      -- guardian AI per area: sleep → wake on lasso → chase at area speed → leash at Town fence
  LassoService      -- validates prompt (distance, area, not already towing), creates RopeConstraint tow
  TowService        -- speed penalty by kg class, drop (Q), knock-loose on hit/trap, loose-beast prompts
  CombatService     -- whip/weapon hits (server raycast + cooldown), bear traps (max 3, not in Town)
  RanchService      -- 7 plots, pen slots, taming timers (os.time), branding, gate lock, rustling rules
  SpeedService      -- treadmill steps (server-side rate limit), spurs multiplier, index claims
  BreedingService   -- 3 same species + fee → wild calf (re-rolled kg/mutation)
  EventService      -- Stampede every 30 min, Admin Abuse
  MarketService     -- gamepasses, ProcessReceipt (Tame All, Instant Tame, speed packs)
StarterPlayerScripts/Controllers/
  HUDController, TowController (rope FX, speed bar, distance meter), AlphaFX (zzZ → red eyes, chase music),
  NotifyController (rare-spawn banner, rustler alert), RanchUI, ShopUI, IndexUI
```

## Important implementation notes
- **The server decides everything.** The client sends only intents (`RequestLasso(beastId)`, `RequestDrop()`, `Swing()`, `TreadmillStep()`). The server checks distance, cooldowns, Safe Zone and ownership. These games are full of exploit scripts, so never trust the client with Speed or cash.
- **Speed → WalkSpeed:** map the huge Speed stat to a capped WalkSpeed curve (for example `16 + 40*log10(speed+1)`). Compare the player's *effective* chase number against each Alpha's chase speed on the server, rather than relying on physics.
- **Alpha chase:** use PathfindingService or simple MoveTo steering. The chase speed is set per area. Leash: stop at the Town fence, or 3 s after the player drops the rope.
- **Towing:** a RopeConstraint from the player's HumanoidRootPart to the beast, with the beast's network owner set to the server. Penalty classes: <100 kg −10%, <1,000 −20%, <10K −30%, more than that −45%.
- **Rustling:** only beasts that are `Taming=true` can be lassoed out of a ranch, and only while the gate is unlocked. Branded beasts reject the prompt.
- **Restock:** spawn the herd models when a player is nearby (StreamingEnabled) and keep each area's state on the server. Broadcast rare spawns only within the server; use MessagingService for cross-server Admin Abuse.
- **Taming timers** use `os.time()`, so they keep running offline. Apply an offline rate on join.

## Build order
1. Town, ranch plot, pen slots, income tick (a playable idle tycoon)
2. Treadmill and Speed, then area 1–3 lanes with signs
3. Herds, lasso, tow and Alpha chase (the core fun, so test it hardest)
4. Whip, traps, knock-loose and loose-beast lasso
5. Taming, tamed reveal, branding and rustling plus the gate lock
6. Sundown cycle, rare-spawn broadcast, Index, Breeding Barn, Sell stand
7. UI polish, shop, monetization, then areas 4–10
8. Weekly content pipeline (new area each Saturday)

Related: [[Core Loop]] · [[My Game UI]]
