# Dynamic fire-versus-water duel — 2026-10-27

The default scene is now an automatic elemental fight. The man uses fire, the
woman water, with health bars, impacts, stagger, limited healing, knockout scoring
and automatic rematches. The static casting study is retained separately in
`scenes/spell_study.tscn`; its tests still run against that saved scene.

## Reused and adapted movement

Quaternius CC0 Sprint, Jump_Start, NinjaJump_Idle and Jump_Land provide the movement
foundation. The existing licensed skeletal flip choreography supplies the full
somersault. FightLab adds an arms-back dash and airborne variants of the casting
clips. The air blend preserves the tucked lower body while retaining the upper
body's casting motion. A bounded chest-aim adjustment handles elevated opponents.

Characters move with CharacterBody3D collision, gravity and ballistic jumps.
Lateral dashes and short aerial bursts move continuously rather than teleporting.
Projectiles emit after evaluating movement, animation and the aim layer, so they
start at the current animated hand position. Hurtboxes follow the animated head,
chest and pelvis through the jump/flip/cast poses.

The camera follows the pair, adjusts distance for separation and altitude, and
smoothly moves toward a side view to keep both fighters readable. Small impact
shake, colored speed trails and expanding flashes emphasize the action.

Water uses a reflective animated surface/foam shader, falling droplets, splashes,
a water lance/torrent and a low surge that airborne fighters can evade. Fire uses
hot cores, rising embers and an expanding spherical nova. Opposed projectiles use
a continuous relative sphere sweep for clashes; target damage still depends on
Godot physics queries against animated hurtboxes. The clash produces steam and
neither opponent takes proximity damage from it.

## Visual review and corrections

Recorded several fight passes, then inspected consecutive video frames around
backflips, air-to-air exchanges, spell releases, impacts and landing. Corrections:

- Fixed bone-local versus model-space pelvis normalization, which was lowering the
  pelvis in air clips. Both rigs now retain the intended bent-leg air pose.
- Combined the airborne pelvis/lower-body orientation with the original upper-body
  cast orientation rather than copying incompatible local rotations.
- Added a separate forward-leaning, arms-back dash pose.
- Changed the camera from a fixed direction to damped pair-relative framing.
- Stabilized small solver penetration at the flat meadow surface.
- Moved release evaluation after the current movement and skeletal pose.
- Added clearer hit flashes and separately rendered the steam-clash review.

## Verification

`validate.ps1` passed with no Godot errors in both the working project and a fresh staged-file package without its import cache, including:

- 120 simulated seconds of AI combat: running, dashes, jumps, backflips, landings,
  air-dash bursts, airborne casts, damaging spells, KOs and automatic new rounds.
- Health always in [0,160] and matching both visible bars. Both fighters dealt
  substantial damage. Body collision, floor contact and effect cleanup passed.
- Both heads remained in the camera frustum throughout sampled active exchanges
  at the intended 1152x720 viewport.
- Disabling hurtboxes prevented damage from every offensive spell type.
- A moving target evaded an already launched projectile; no homing/proximity hit.
- Opposing projectiles consumed each other in a clash without phantom damage.
- Both imported rigs showed a real sprint foot cycle, a skeletal inversion during
  the flip, and bent legs during airborne casting. Saved ten-cast study tests passed.

The final 55-second rendered recording included:

| Metric | Fire | Water |
|---|---:|---:|
| Airborne casts | 9 | 8 |
| Flips | 7 | 7 |
| Distance traveled | 111.2 m | 116.7 m |
| Root jump peak | 2.91 m | 2.91 m |
| Hits landed | 11 | 10 |
| Damage dealt | 216 | 206 |

Water won the first round at 43.28 s; round two began automatically. Both health
bars changed during actual combat. That recording had no projectile clash, so the
clash effect was additionally verified in the isolated `tests/clash_review.gd`
rendered check. Its error log was empty and both health values remained full.

A separate 16-second 1152x720 live run without recording ended at a sampled 60 FPS
on the Radeon 610M, with no runtime errors. This is a sample, not a minimum or
average benchmark. Native movie encoding speed is reported separately.

## Reproduce

```powershell
.\run.ps1
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 55
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_duel_clips.gd
```

Space slows the fight, R restarts and Esc exits. Both fighters remain autonomous.
This is a first dynamic arena-combat pass. Visual effects and the meadow remain
stylized; it does not yet have commercial anime-game animation polish, melee
combos, active ragdolls, player control or a fluid simulation.
