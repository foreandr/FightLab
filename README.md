# FightLab — Fire vs Water

An automatic **elemental arena fight** in Godot 4.6 stable, built for Windows 11
and the Compatibility renderer on integrated graphics.

The male fighter uses fire. The female fighter uses water. Both run, leap, dash,
perform skeletal backflips, cast while airborne and react to actual spell hits.
Each has a health bar; a knockout awards the round, followed by an automatic rematch.
Both can raise directional energy shields, absorb spells, strafe, backpedal,
quick-step backward and perform a backward ground roll while facing the rival.
Mana, stamina and distance now drive their tactics: depleted casters close in
with jabs, crosses and hooks, then make space for magic as their mana recovers.

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
- Facing-preserving sideways steps, guarded forward/backward walking, a quick
  backward dodge and a reversed skeletal ground roll. Retreats are physical moves,
  so an incoming spell may still catch the fighter.
- Two shield gestures (one palm and two-handed brace), block recoil, lowering and
  guard-break recovery. The pale GUARD bar shows shield energy. A forward
  shield consumes energy, allows rear/flank hits, breaks under pressure and recharges.
- Purple MANA pays for released spells and shield creation/upkeep. Green STAMINA
  pays for punches, sprints, jumps, dashes and rolls. Both recover over time, with
  delays after spending. Exhausted fighters back off or hold guard to catch breath.
- Low mana switches to closing distance and fistfighting; recovered mana switches
  back to spacing for spells. Very close enemies can provoke melee even with mana.
  Left/right jabs, crosses and hooks sweep the animated fist through real hurtboxes.
  Missed, evaded or out-of-range punches do no damage. Retreats stay in the meadow.
- Ground and airborne versions of the ten casting gestures, blended between states.
  Air casts keep bent legs; the chest aims up/down toward elevated opponents.
- Physical CharacterBody3D movement, gravity, floor and body collision. Animated
  head/torso hurtboxes follow the bones through flips and aerial casting.
- Separate head, chest, pelvis, upper/lower arm and thigh/calf hurtboxes.
  Contact point and momentum drive constrained spring-joint recoil: torso torque,
  head/neck motion, struck-limb deflection, balance loss and physical root shove.
  These dynamics blend over locomotion and casting rather than choosing one generic flinch.
- Predictively aimed projectiles that can miss. Swept Godot shape queries decide
  projectile hits; rays decide channels; expanding shapes decide area spells.
- Firebolts, cleaves, lances, a channel and a nova for the man. The woman uses
  reflective animated water orbs, darts, water lances, a torrent and ground surge,
  with falling droplets and splashes rather than rising fire embers.
- Opposing projectiles can collide into a steam clash. Impact flashes, expanding
  rings and short motion trails emphasize connections without hiding the fighters.
- Kenney CC0 flame/smoke/spark/slash textures, flowing tapered ribbons, animated
  water surfaces, foam/spray, layered flame heads, smoke and textured impact bursts.
  Hex-pattern curved shields light up with a ripple when a spell is absorbed.
- Health, stagger, limited recovery spells, knockout scoring and automatic rounds.
- A damped action camera orbits the fight and adjusts its distance for separation
  and jumps. The HUD keeps fire/water identity, health and round score visible.

This is a first dynamic combat prototype inspired by fast aerial arena fighters.
It does not claim the animation polish, content or combat depth of commercial anime
fighting games. There is no player control, grappling, active ragdoll or
fluid simulation yet. Fire/water effects use lightweight textured particles and shaders.

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
Defense checks verify actual projectile interception, guard spending, damage
overflow on break, rear bypass, recovery, physical footwork and bounded particles.
Both rigs are also checked for lateral foot motion, roll inversion and distinct
shield hand poses.
Resource checks verify costs, delayed regeneration, stamina-gated actions,
low-mana pursuit, returning to ranged spacing, real fist contacts/misses on both
characters, resource/HUD bounds and pool resets between rounds.
Impact checks verify actual head/torso/leg projectile contacts on both rigs,
mirrored side torque, speed-dependent momentum, leg support loss, shield impulse
transfer, settling and matching dynamics at 30/60 FPS.

The video helper writes a native 30 FPS AVI and a JSON action/cast/hit timeline to
ignored `builds/review-*`. Review consecutive frames around jump, flip, release,
impact and landing timestamps. Encoding speed is not live gameplay performance.
See [localized impact physics](docs/impact-physics.md), or the earlier
[mana, stamina and melee validation](docs/resources-melee.md),
[shield, footwork and VFX validation](docs/defense-vfx.md) and
[elemental-duel validation](docs/elemental-duel.md).

After normal asset import, rebuild movement and aerial casting clips with:

```powershell
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_duel_clips.gd
```

## Sources and checkpoints

Characters and base locomotion are **Quaternius CC0**. The flip choreography and
clothing are **Clint Christopher Canada / 3D Fighter, CC BY 4.0**. Existing MIT
skeletal composition helpers are reused. Full credits: [asset notices](assets/combat/NOTICE.md).
Effect masks come from [Kenney Particle Pack](https://kenney.nl/assets/particle-pack),
CC0; the ten selected textures and original license are included for offline use.
No assets were extracted from Naruto, Jujutsu Kaisen, or proprietary games.

The static ten-spell study remains in `scenes/spell_study.tscn`; earlier striking
sparring remains in `scenes/sparring.tscn`. Their regression checks are retained.
