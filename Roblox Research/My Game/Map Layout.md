---
tags: [my-game, gdd, map]
status: design-v1
updated: 2026-10-18
---
# Map Layout 🗺️

![[map-preview.png]]

> **In one line:** Town (spawn, shops and the 7 ranches) sits at one end. From the Town gate, **one long lane of 10 areas** runs straight out. Each area is farther away, needs more Speed, has rarer beasts and makes the run home longer. It's the same shape as [[Steal An Egg]], re-themed from Wild West to fantasy.

The exact build spec for scripting (every coordinate, part, tag and attribute) is in the repo at `game/MAP_SPEC.md`. This page is the plain-words version.

## Top-down sketch

```
                 TOWN (fenced; everything inside is safe from Alphas)                         THE LANE  →  (gets wilder and rarer)
+-----------------------------------------------------------------------------+
| TOWN SQUARE                | RANCH ROW                                       |
| [Clock]  [GENERAL STORE]   |  [Ranch 1] [Ranch 2] [Ranch 3] [Ranch 4]        |
|          (shop ring)       |     T         T         T         T             |
| [INDEX]      SPAWN         | ============ MAIN STREET (Safe Zone) ========== RED  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |   10    |END|
| board                      |     T         T         T                       LINE |   |   |   |   |   |   |   |   |   |         |   |
| [Leaderboards] [FREE       |  [Ranch 5] [Ranch 6] [Ranch 7] [TRADING POST]   |
|                 REWARDS]   |                                [Sell | Barn]   |
+-----------------------------------------------------------------------------+
  T = treadmill in front of each ranch        Herds sit on alternating sides: right in odd areas, left in even areas
```

## How the map works

- **Town** is where you spawn, and it's the Safe Zone. Weapons don't work on the square, Main Street, the boardwalks or at the Trading Post. Shops are glowing rings on the floor that open their menu when you step on them, like SAE's yellow `TRAILS SHOP` circle:
  - the **General Store** (treadmill tiers, Spurs, gear)
  - the **Beast Index** board
  - the red-and-gold **Free Rewards chest**
  - the **Sell stand** and **Breeding Barn** together at the Trading Post, next to the gate
- **Ranches** are 4 on one side of Main Street and 3 on the other, all facing the street. Each has:
  - a fenced pen with **10 slot pads** (7 open at the start)
  - a barn
  - a gate with an owner sign
  - a **treadmill right out front** on the boardwalk, so training is safe
  - **The yard behind the gate is not safe:** whips work there and rivals can rustle beasts that are still taming, unless you lock the gate.
- **The red line** across the Town gate is the goal line. Get a towed beast over it and the Alpha gives up and walks home. At **Sundown** (every 5 minutes), anyone outside Town is sent back to their ranch, and a glowing curtain keeps the lane closed for 10 seconds while the herds restock.
- **The lane** is 128 studs wide, with cliffs on both sides and a 40-wide trail down the middle. Every area starts with a big **arch and sign** showing its name and the Speed you need, for example **CACTUS CANYON / 900 SPEED**. Nothing physically stops you; the sign tells you whether you'll outrun the Alpha on the way home.
- **Herds:** each area has 8 grazing spots in two little groups (like SAE's "nests"). The **Alpha sleeps right beside them**, with a small sign next to it repeating the Speed. Herds alternate between the right and left side of the trail, so runners heading farther out always have a clear path.
- **Lengths grow outward**, and Cosmic Rift is the longest. At exactly the sign's Speed while towing, the run home takes about **8 s near Town and 31 s from Cosmic Rift**.

## The 10 areas

| # | Area | Speed sign | Length (studs) | Theme | Alpha | Replaces SAE's |
|---|---|---|---|---|---|---|
| 1 | Dusty Prairie | 0 | 160 | Sunny open range with oaks, hay and a windmill | Ol' Stompy (Bull) | Forest |
| 2 | Cactus Canyon | 900 | 192 | Red-rock canyon with saguaros, hoodoos, skulls and an oasis | Rattlesnake King | Lake |
| 3 | Gold Rush Mine | 10K | 224 | Mining gulch with minecarts, rails, gold ore and a boarded mine mouth | Big Digger (giant mole) | Desert |
| 4 | Bayou Swamp | 40K | 256 | Misty swamp with a plank causeway, cypress, fireflies and a stilt shack | Croc King | Jungle |
| 5 | Frost Peak | 170K | 288 | Snowy pass with pines, ice crystals, snowmen and an igloo | Yeti Moose | Snow |
| 6 | Volcano Ridge | 700K | 320 | Basalt and lava, with a small stepped volcano and lava falls | Magma Ox | Volcano |
| 7 | Storm Mesa | 2.5M | 352 | Thunderstorm mesa with rock spires, lightning rods and a cave in the right wall | Storm Griffin | Abyss Ocean |
| 8 | Dino Badlands | 17M | 384 | Red badlands and ferns, a giant ribcage over the trail and green step blocks | Rodeo Rex (T-Rex) | Prehistoric |
| 9 | Ghost Town | 150M | 416 | Abandoned town at midnight with Boot Hill graveyard and ghost lanterns | Phantom Steed | *(our extra area)* |
| 10 | Cosmic Rift | 700M | 576 | Space torn open: crystals, floating islands, planets and a Rift Gate | Cosmic Kraken-Cow | Cosmic |

New areas each Saturday (Sakura Springs 2.5B, Titan Canyon 7B, Heaven & Hell Ranch 20B, Enchanted Frontier 50B) get **added onto the far end**, just as SAE adds biomes. The beasts and Alphas for every area are in [[Areas and Beasts]].

**Size:** Town is 496 × 256 studs and the 10 areas are 3,168 studs long, about 3,700 studs end to end. The whole static map is about **2,000 parts**, under the 3,000 budget, which leaves room for four more areas.

## How it mirrors Steal An Egg

| Steal An Egg | Steal a Beast | Research source |
|---|---|---|
| Biomes in **one fixed line**, each farther from the bases; new ones go on the far end | 10 areas in one lane from the Town gate; new areas are appended at the end | [fandom Zones](https://stealanegg.fandom.com/wiki/Zones), [games.gg biomes](https://games.gg/roblox/guides/steal-an-egg-biomes-guide/), [allthings.how](https://allthings.how/steal-an-egg-angels-vs-demons-update-luminous-egg-and-new-biome/) |
| **Speed sign** at each biome; soft gate, no wall | An arch and sign at every area start; nothing blocks you | [games.gg](https://games.gg/roblox/guides/steal-an-egg-biomes-guide/), [Nerdschalk 700M signpost](https://nerdschalk.com/how-to-steal-the-huge-cosmic-egg-in-steal-an-egg-at-low-speed/) |
| Guardian **sleeps next to the nests**, with a Speed sign beside it | Alpha sleeps beside the herd, with a herd sign next to it | [rblxguide](https://rblxguide.com/games/steal-an-egg/mechanics/eggs-and-guardians), [wotpack.ru](https://wotpack.ru/kak-vorovat-yaytsa-v-ukradi-yaytso-iz-biomov-i-u-drugih-igrokov/) |
| Several nests per biome, several eggs side by side in each | 2 herd groups of 4 grazing spots | [games.gg mutations](https://games.gg/roblox/guides/steal-an-egg-mutations-guide/) |
| A **red line** marks the Safe Zone; crossing it ends the chase | Red line across the Town gate | [RobloxDen](https://robloxden.com/game-guides/steal-an-egg/how-to-give-eggs-and-pets-in-steal-an-egg), [stealanegg.pro](https://stealanegg.pro/guide/how-to-steal-eggs) |
| **Treadmill directly in front of your base** | Treadmill in front of each ranch | [allthings.how](https://allthings.how/steal-an-egg-how-to-get-speed-quickly/) |
| Shops at spawn (glowing Trails Shop floor circle, red-and-gold Free Rewards chest, Sell stand next to the Fuse Machine, Index) | General Store floor ring, Free Rewards chest, Sell stand + Breeding Barn, Index board | [stealegg.wiki](https://stealegg.wiki/guides/getting-started/), [allthings.how trails](https://allthings.how/steal-an-egg-how-to-get-and-equip-trails/) |
| Halloween portal beside the Trails Shop | A reserved event-portal spot beside the General Store | [TechWiser](https://techwiser.com/steal-an-egg-halloween-dimension/) |
| **Cosmic is the longest stretch**; its best nest is at the far end | Cosmic Rift is the longest area, with its herd near the far end | [allthings.how](https://allthings.how/steal-an-egg-every-biome-and-its-minimum-speed-requirement/), [Nerdschalk](https://nerdschalk.com/how-to-steal-the-huge-cosmic-egg-in-steal-an-egg/) |
| Prehistoric: **big T-Rex on the left**, in a grass and bush clearing, with green platform blocks | Dino Badlands: Rodeo Rex's herd on the left, a bush clearing, green step blocks | [TechWiser](https://techwiser.com/steal-an-egg-drone-parts-vault-secret/), [allthings.how lost parts](https://allthings.how/steal-an-egg-all-lost-part-locations-for-the-stolen-experiment-vault/) |
| Volcano: **small stepped volcano right of centre** with lava on top | The same, in Volcano Ridge | [allthings.how lost parts](https://allthings.how/steal-an-egg-all-lost-part-locations-for-the-stolen-experiment-vault/), [ProGameGuides](https://progameguides.com/roblox/all-5-vault-part-locations-in-steal-an-egg-drone-lost-parts/) |
| Abyss Ocean: **small hole in the right wall** to a secret lab | Storm Mesa: a cave hole in the right wall (secret saved for later) | [TechWiser](https://techwiser.com/steal-an-egg-drone-parts-vault-secret/) |
| Everyone outside the Safe Zone is **teleported at night**, and the map closes for about 10–13 s | Sundown teleport plus a 10 s curtain at the red line | [GameBoost](https://gameboost.com/blog/steal-an-egg-glitches-and-hacks), [allthings.how](https://allthings.how/steal-an-egg-glitches-that-still-work-in-roblox/) |
| The later biome is reached "through the portal" at the end of the track | A Rift Gate at the end of Cosmic Rift, where future areas attach | [allthings.how](https://allthings.how/steal-an-egg-angels-vs-demons-update-luminous-egg-and-new-biome/) |

## What we had to guess

The research couldn't pin these down, so the spec marks them **[assumed]**:
- **How SAE arranges the 7 bases.** No source, screenshot or diagram describes it. We used two rows facing a main street that leads into the lane. That's the genre standard, it fits fan-made 7-plot SAE map kits on a narrow (about 110-stud-wide) strip ([BuiltByBit](https://builtbybit.com/resources/steal-an-egg-map.126235/), which is not official), and it means every base empties onto the same path, which is where guides say ambushes happen. Ranches nearer the gate are closer to the herds but also first in line for passing rustlers. Plots are handed out at random.
- **Safe Zone shape.** Only SAE's red line is documented. Our ranch yards sit outside the Safe Zone on purpose (the rustling twist in [[Core Loop]]); in SAE, pens are safe.
- **Distances and speed.** No studs or Speed→WalkSpeed formula is published anywhere. We use `WalkSpeed = 16 + 12 × log10(1 + Speed)` (max 160) and decide escapes by comparing stats. **This replaces the `40×` example in [[Systems and Scripts]]**, which would make players cross the whole lane in about 9 seconds.
- **Herd layout:** the number of grazing spots, two groups, and herds alternating sides.
- **What every area looks like.** No written source describes SAE's biome visuals (ground, sky, props or art style), so all themes are ours. Only the landmarks in the table above are copied.
- Lava, tar and water are harmless decoration.

Related: [[Steal a Beast - Overview]] · [[Core Loop]] · [[Areas and Beasts]] · [[Systems and Scripts]] · [[My Game UI]] · [[Steal An Egg]] · [[00 Index]]
