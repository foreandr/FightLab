# FightLab — Fire vs Water

An automatic **elemental arena fight** in Godot 4.6 stable, built for Windows 11
and the Compatibility renderer on integrated graphics.

The male fighter uses fire. The female fighter uses water. Both run, leap, dash,
perform skeletal backflips, cast while airborne and react to actual spell hits.
Each has a health bar; a knockout awards the round, followed by an automatic rematch.

## Launch

Double-click `C:\Users\forea\FightLab\Play.bat`, or run the current local files:

```powershell
Set-Location C:\Users\forea\FightLab
.\run.ps1
```

Both fighters are autonomous. Space toggles slow motion, R restarts and Esc quits.
Godot 4.6 is found automatically, or supply `GODOT_PATH` / `-GodotPath`.
All required models, animations and third-party license notices are in Git.

## Combat and movement

- Reused Quaternius sprint, jump anticipation, tucked flight and landing motion.
- A separate arms-back dash, real ballistic jumps (~3 m), lateral evasions,
  short air-dash bursts and a complete skeletal somersault/backflip.
- Ground and airborne versions of the ten casting gestures, blended between states.
  Air casts keep bent legs; the chest aims up/down toward elevated opponents.
- Physical CharacterBody3D movement, gravity, floor and body collision. Animated
  head/torso hurtboxes follow the bones through flips and aerial casting.
- Predictively aimed projectiles that can miss. Swept Godot shape queries decide
  projectile hits; rays decide channels; expanding shapes decide area spells.
- Firebolts, cleaves, lances, a channel and a nova for the man. The woman uses
  reflective animated water orbs, darts, water lances, a torrent and ground surge,
  with falling droplets and splashes rather than rising fire embers.
- Opposing projectiles can collide into a steam clash. Impact flashes, expanding
  rings and short motion trails emphasize connections without hiding the fighters.
- Health, stagger, limited recovery spells, knockout scoring and automatic rounds.
- A damped action camera orbits the fight and adjusts its distance for separation
  and jumps. The HUD keeps fire/water identity, health and round score visible.

This is a first dynamic combat prototype inspired by fast aerial arena fighters.
It does not claim the animation polish, content or combat depth of commercial anime
fighting games. There is no player control, melee combo system, active ragdoll or
fluid simulation yet. Fire/water effects are stylized lightweight geometry/shaders.

## Checks and recorded debugging

```powershell
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 55
```

Validation runs 120 simulated seconds of the fight, checks both fighters' running,
jumps/flips, air casts, damage, bounded health, HUD agreement, KOs/rematches,
separation, camera coverage and effect cleanup. It disables all hurtboxes to reject
proximity damage, moves a target out of a launched spell's path, and checks a real
opposing-projectile clash. Movement sampling verifies sprint strides, an inverted
skeletal flip and tucked legs on both character rigs.

The video helper writes a native 30 FPS AVI and a JSON action/cast/hit timeline to
ignored `builds/review-*`. Review consecutive frames around jump, flip, release,
impact and landing timestamps. Encoding speed is not live gameplay performance.
See [elemental-duel validation](docs/elemental-duel.md).

After normal asset import, rebuild movement and aerial casting clips with:

```powershell
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_duel_clips.gd
```

## Sources and checkpoints

Characters and base locomotion are **Quaternius CC0**. The flip choreography and
clothing are **Clint Christopher Canada / 3D Fighter, CC BY 4.0**. Existing MIT
skeletal composition helpers are reused. Full credits: [asset notices](assets/combat/NOTICE.md).
No assets were extracted from Naruto, Jujutsu Kaisen, or proprietary games.

The static ten-spell study remains in `scenes/spell_study.tscn`; earlier striking
sparring remains in `scenes/sparring.tscn`. Their regression checks are retained.
