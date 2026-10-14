# Painted Prophet

Recolours the boss fight against Rodin Karnak, Prophet of Decay, in **Spillway** (the finale of
Terror In The Depths). The fight reads as two colours, and the mod gives each its own settings group:

- **Nurgle (green)**: the dance rings on the floor, the walls, the teeth indicator, the green
  projectile and its burst.
- **Warp (red)**: the shockwave indicator, the barrier ring, the red projectile, its burst and impact.

It is client-side: only you see the colours, and it changes nothing about the fight itself.
Nothing is ever hidden, because these effects are the boss's attack telegraphs.

## Settings

Open the mod options and pick a group. Each has:

- **Colour**: Base (the game's own colour), Set colour, or Rainbow.
- **Set colour**: the colour picker used by Set colour.
- **Brightness**: 1 to 15, where 8 is the game's normal brightness.

A colour change shows on each effect the next time it appears; the dance rings follow it at once.
Rainbow cycles on the rings while they exist and picks a hue for everything else as it appears.

## What changes colour

**Yes** means it has been seen recoloured in game. **Expected** means it is built and wired but has
not been looked at in the fight yet.

| What you see | Family | Recolours? |
|---|---|---|
| Dance rings on the floor (the four rings and the centre) | Nurgle | Expected (confirmed by a direct test, not yet in the fight) |
| Ember sparks on the ring slices | Nurgle | Yes |
| Big green splash of the ring slices | Nurgle | Not yet |
| Green gas over the rings, spores on the teeth indicator | Nurgle | Partly: it can only shift between red and green |
| Green core of the teeth indicator, its burst, the green projectile and its burst | Nurgle | Expected |
| Walls (second dance phase) | Nurgle | Yes |
| Green projectile dense cloud | Nurgle | Yes |
| Shockwave indicator pulse | Warp | Yes |
| Shockwave indicator floor light | Warp | No |
| Red projectile outer clouds | Warp | Yes |
| Red projectile core and inner glow | Warp | Not yet |
| Red projectile burst cloud | Warp | Yes |
| Red projectile burst body | Warp | Expected |
| Red projectile burst spark shower and lights | Warp | No |
| Red projectile impact cloud | Warp | Yes |
| Barrier ring smoke (second dance phase) | Warp | Yes |
| Barrier ring flames | Warp | No |
| The force-push shockwave itself | Warp | Not yet |
| Teeth, screen effects, light glows | either | No |

The shockwave pulse, the red burst body and the green cores rely on one patched game file that the
mod serves through `bin\asset-redirect.dll`. Everything else is coloured directly.

## After a game update

The mod checks the game's files before serving its patched file. If an update changed them, the
pulse, the red burst body and the green cores go back to the game's colours until the mod is
updated, and `/pp_check` says so. Everything else keeps working.

## Troubleshooting

Type `/pp_check` in chat. It reports the state of the patched file, your current colours, and how
many effects were seen and coloured. A per-effect breakdown goes to the console log. Turn on **Debug
logging** in the mod options to write the same report at launch.

The patched file's state is one of:

- **pending**: the mod is still checking the patched file. This takes a moment after launch.
- **armed**: installed, the game has not read it yet. Normal before your first mission.
- **active**: the game has read it.
- **refused**: a game update changed the original file, so the mod leaves it alone. See After a game
  update.
- **stale**: the mod was added or updated by reloading mods while the game already had the original
  file loaded. A notice in chat says so. Restarting the game clears it; loading another mission
  should too, though that has not been measured.
- **restart**: the check did not finish in time at launch, so the pulse, the red burst body and the
  green cores keep the game's colours this session. A notice in chat says so. Restarting the game
  clears it.

## Install

Unzip into your `mods` folder so that you have `mods/Painted Prophet/Painted Prophet.mod`, then add
`Painted Prophet` to `mod_load_order.txt` (or let your mod manager do it). If you also use
Polychromatic, list Painted Prophet above it.

Nexus: https://www.nexusmods.com/warhammer40kdarktide/mods/1385
Source: https://github.com/Wobin/Painted-Prophet
