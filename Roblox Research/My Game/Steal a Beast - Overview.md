---
tags: [my-game, gdd]
status: design-v2
working_title: Steal a Beast
updated: 2026-10-18
---
# Steal a Beast 🤠 (Game Design Document v2)

> **One-liner:** Run out from town through areas that get wilder and rarer the further you go. **Lasso a beast** from a herd guarded by a sleeping **Alpha**, then **tow it home** before the Alpha or another player stops you. Tame it on your ranch and it earns $/s. Train **Speed** to reach the next area.

v2 copies the structure of [[Steal An Egg]] (areas in a straight line, speed signs, guarded nests, a chase home, knocking down players who are carrying something, and a 5-minute reset). The research behind it is in [[Steal An Egg]], and the full spec is in [[Core Loop]].

## Copied from Steal An Egg
| Steal An Egg | Steal a Beast |
|---|---|
| Biomes in one straight line out from the bases | **10 areas** in one lane out from **Town**: [[Areas and Beasts]] |
| Speed sign at each biome (a soft gate) | Same. The sign says how fast you must be to **outrun the Alpha** home |
| Eggs in nests guarded by a sleeping guardian | **Wild beasts in herds** guarded by a sleeping **Alpha** |
| Press E "Steal Egg" | Hold E **"Lasso"** (0.5 s for Common, up to 2 s for Divine) |
| Carry the egg; weight slows you | **Tow** the beast on a rope behind you; weight (kg) slows you |
| Guardian wakes and chases; if caught, you drop the egg | Alpha wakes and charges; if caught, you're flung, the rope snaps and the beast bolts |
| Safe once you're back over your perimeter | Safe once you're back over the **Town fence** |
| Bats and bear traps knock carriers, who drop the egg so anyone can grab it | **Whip** and bear traps knock riders, who drop the beast so anyone can lasso it |
| Egg in pen, hatch timer, pet earns $/s | Beast in ranch, **taming timer**, tamed beast earns $/s |
| Treadmill plus trails for Speed | **Treadmill** (wagon wheel) plus **Spurs** for Speed |
| Weight/size and Silver/Golden/Rainbow mutations | Same: `$/s = base × mutation × (kg/baseKg)^0.617` |
| 5-minute reset with a short night (eggs grow 30× faster) | **Sundown** every 5 minutes: everyone is sent back to town, herds restock, taming runs 30× faster |
| Server-wide alert when a Secret, Eternal or Divine egg spawns | Same ("A SECRET Inferno Mammoth roams Volcano Ridge!") |
| Pet Index gives Speed and cash, plus a weapon for each completed world | Beast Index: same, with Western weapons |
| Fuse Machine (3 of the same pet become a re-rolled egg) | **Breeding Barn** (3 of the same beast become a wild calf with a re-rolled kg and mutation) |
| No rebirth; a new biome every week | Same: a **new area each Saturday** plus Admin Abuse |
| 7-player servers | 7-player servers |

## What's ours (the twist)
| Twist | Why |
|---|---|
| 🪢 **Lasso and tow**: the beast runs behind you on a rope instead of being carried | You can see the weight dragging you down, rivals can **cut the rope**, and it makes funny clips |
| 🐄 **Live beasts** instead of eggs, in **Wild West → fantasy** areas | Gives the game its own identity. Players see the beast before they grab it, so choosing which one to lasso becomes the fun |
| 🔥 **Rustling**: beasts still being tamed can be stolen out of your ranch (like [[Steal a Brainrot]]) | Players can steal from your base at any time, the way the original games work. Defend with a **gate lock**, traps and your whip. Branded (tamed) beasts are safe |
| 🐎 **Stampede** event every 30 minutes | A herd of loose rare beasts thunders down the lane and the whole server races for them |

## Removed from v1
The tug-of-war minigame, night-only raids and guard beasts are gone. Stealing now works the way it does in the games you showed me.

## Pages
- [[Core Loop]]: the step-by-step flow, with every rule
- [[Areas and Beasts]]: 10 areas, Alphas, beasts, rarities, weight and mutations
- [[My Game UI]]: every screen, plus the clickable mockup
- [[Systems and Scripts]]: how to build it in Roblox Studio
- [[Monetization and Launch]]

Back to [[00 Index]]
