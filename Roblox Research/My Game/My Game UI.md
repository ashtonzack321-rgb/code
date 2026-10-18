---
tags: [my-game, gdd, ui]
---
# UI Design

Style follows [[UI Patterns]]: Fredoka One / Luckiest Guy fonts, 3px black UIStroke, saturated gradients, UICorner 12, bounce tweens. **Theme: Wild West.** The palette is wood-brown and sunset-orange panels with rope borders and rarity accents.

## Main HUD
```
┌─────────────────────────────────────────────────────┐
│ [🛒Shop]      ☀️ DAY 2:41 ▓▓▓▓▓▓░░ 🌙      [⚙][🎁]   │
│ [🔄Rebirth]   💰 $4.2B  (+$12.5M/s)                  │
│ [📖Index]                                            │
│ [🐣Breed]       🔥 LEGENDARY STAMPEDE IN 1:30        │
│ [⭐Passes]                                           │
│                                                      │
│                  (3D world)                          │
│                                                      │
│ 🐎 Speed 320                     [🔪Cut] [🪢 THROW]  │
│                                          [⏏ Jump]    │
└─────────────────────────────────────────────────────┘
```
- **Day/night bar** (top centre): a sun-to-moon gradient with a countdown. It flashes red for the last 10 seconds before night.
- **Cash** (top centre): a huge number with $/s below it. A "+$" pops up with a coin-fly animation.
- **Left rail:** square icon buttons with red notification dots.
- **Right thumb zone (mobile):** a big round THROW button with auto-aim to the nearest beast in a cone.

## Tug-of-war popup
```
        THUNDER BISON  [RARE]
   ┌──────────────────────────────┐
   │░░░░░░▓▓▓[███]▓▓▓░░░░░░░░░░░░│  ← green sweet zone moves
   └──────────────────────────────┘
   CATCH ███████████░░░░ 72%
        HOLD / TAP TO PULL!
```
The camera zooms toward the beast, the screen shakes on each pull and a rope-creak sound plays.

## Beast billboard (above every beast)
```
   ✨ Golden Stallion ✨
      LEGENDARY  ⚡Neon
      $4.5M/s
```

## Night raid overlay
- Purple vignette and a "🌙 RAID NIGHT — GATES OPEN! 1:58" banner.
- When something is being stolen from you: red edge flash, "⚠️ Bob is stealing your Storm Griffin!" and an arrow to the thief.
- After the night: a **Raid Report** card showing beasts stolen, beasts defended and the top raider. This card is made to be shared in clips.

## Other screens
- **Shop** (tabs: Lassos, Horses, Pens, Traps, Robux): grid cards with rarity borders and a "BEST VALUE" ribbon.
- **Index:** a silhouette grid of undiscovered beasts with % collected, plus a reward at 25/50/75/100%.
- **Breeding:** two slots, then a heart animation and a timer. Shows the odds of the result.
- **Rebirth:** shows the requirements with checkmarks next to the rewards.
- **Catch reveal** (first-time catch): full-screen rarity flash with "NEW BEAST!" and confetti.

## Thumbnail and icon
Bacon-hair cowboy swinging a lasso at a giant glowing **Inferno Mammoth**, with "$1,250,000,000/s" in huge white stroked text, a rainbow "SECRET" tag, a red arrow and a sunset-orange sky.

Related: [[Core Loop]] · [[Systems and Scripts]]
