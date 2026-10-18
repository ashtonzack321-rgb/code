---
tags: [roblox, scripting, architecture, concept]
---
# Technical Architecture (how you'd build one)

> This is my reconstruction based on the genre and common Roblox practice. I haven't seen these games' source code.

## Folder layout
```
ReplicatedStorage/
  Shared/Config/Units.lua      -- name, rarity, baseIncome, price, model
  Shared/Config/Rebirths.lua
  Remotes/ (RemoteEvents/Functions)
  Assets/UnitModels/
ServerScriptService/
  Services/DataService        -- ProfileStore / DataStore session locking
  Services/BaseService        -- assigns plot per player, slots, lock timer
  Services/SpawnService       -- conveyor / biome / egg spawns, weighted RNG
  Services/StealService       -- pickup, carry, deliver, return-on-hit
  Services/IncomeService      -- tick every 1s: cash += Σ unit income × multipliers
  Services/MarketService      -- ProcessReceipt, gamepass checks
StarterPlayerScripts/
  Controllers/UIController, HatchController, NotificationController
```

## Key systems
- **Data:** use ProfileStore (or ProfileService) with session locking to stop item duplication. Save: cash, units (id, mutation, slot), rebirths, speed, pickaxe tier, and gamepass flags. Store big numbers as doubles or in mantissa/exponent form, and format them as K/M/B/T/Qa.
- **Server authority:** the server decides everything about cash, spawns and theft. The client only sends requests such as `RequestBuy(unitId)` and `RequestSteal(plotId, slot)`, and the server validates distance, cooldowns and ownership. This matters because these games attract exploit scripts.
- **Weighted RNG spawns:** use a rarity table with weights, plus guaranteed timed spawns (os.time() % 300 == 0 → Legendary). Broadcast them to every server with MessagingService for "God spawns" or admin events.
- **Stealing:** weld the model to the thief's back, apply a WalkSpeed debuff and disable tools. A `Humanoid` hit returns the unit. Delivering it into the thief's own base zone transfers ownership. Use ProximityPrompt for the interactions.
- **Base lock:** a server-side timer per plot that enables a CanCollide barrier and a ForceField visual. Replicate the time remaining via attributes.
- **Offline earnings:** on join, `min(now - lastSeen, cap) × income × offlineRate`.
- **Breaking eggs (Break & Steal):** eggs have an HP attribute and pickaxe damage per swing, with server-side swing cooldowns. Use particles, sound and camera shake on the client.
- **Guardians (Steal An Egg):** an NPC with PathfindingService that targets whoever carries an egg in its biome.

## Performance
- Use StreamingEnabled and keep part counts low. Most models are blocky voxel or low-poly, which is cheap.
- Batch income updates (every 1s, one remote call) instead of per-unit.
- Small server sizes (7–8) keep the replication load small.

Related: [[UI Patterns]] · [[Build Your Own Checklist]]
