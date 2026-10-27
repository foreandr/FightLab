# Shields, footwork and textured effects — 2026-10-27

The autonomous meadow duel now has directional energy shields, guarded lateral
and backward movement, quick backsteps and backward ground rolls. Both characters
retain their fire/water identities and the earlier jumping, backflips, aerial casts,
health, KOs and automatic rematches.

## Defense and movement

- One-palm ward and two-handed brace: separate raise, hold, impact and lower clips.
  Guard break uses the licensed Quaternius UAL2 recovery animation.
- Guard holds 44 energy. Absorption spends the incoming damage amount; an exhausted
  shield passes the remaining damage to health and ends protection. Recharge is
  delayed, with a cooldown before another shield can be raised.
- A swept projectile versus forward-facing shield disk check runs before hurtbox
  queries. Channels check the same disk before the body. Guarding area attacks uses
  the incoming direction. Rear attacks bypass the shield.
- The thin pale HUD bar is guard energy. Absorbed spells do not award health damage
  or a damaging hit. The shield displays a hit ripple and the actor recoils.
- Sideways footwork keeps the torso facing the rival. Alternating foot paths use
  the existing IK helpers. Forward/backward guarded walking reuses the licensed
  walk cycle; a reversed CC0 Roll drives a real skeletal backward roll.
- Quick backward steps and ground rolls move the CharacterBody through physics.
  They do not grant immunity; a well-timed projectile can still hit.

## Effect assets and rendering

Ten unmodified masks from the official Kenney Particle Pack 1.1 (CC0) are included,
with the original license. The pack provides flames, smoke, sparks, slashes,
glow, rings and swirls. No download is needed to run the game.

Fire uses layered soft flame heads, a hot tapered trail, rising embers and smoke.
Water uses an animated reflective core, flowing streaks, spray/foam and splashes.
Channels use animated textured ribbons, replacing the plain cylinder. Cleaves use
textured slash silhouettes. Charges, heals and impacts use layered textured quads.
The forward shield is a curved mesh with hex cells, a bright rim and hit ripple.

Transparent quads face the camera, depth-test against the world and expire. There
is a hard cap of 240 texture particles. The Compatibility renderer needs no bloom,
screen-space refraction, paid plugin or external runtime. Effects remain stylized;
this is not a fluid simulation or a commercial VFX-pack integration.

## Verification and visual review

- `validate.ps1` passes in both the working project and a fresh staged-file package without an import cache: 120 simulated fight seconds, health/HUD agreement, physical
  impacts/misses, KOs/rematches, camera coverage and cleanup, plus previous studies.
- Both autonomous fighters use every new footwork action and absorb real spells.
- Focused defense tests fire an actual projectile into the shield, verify energy
  cost and projectile consumption, check rear bypass, break/overflow and recharge,
  and test fast front sweeps, rear sweeps and paths outside the shield disk.
- Movement tests on both rigs find about 0.48 m of lateral foot excursion, an
  inverted backward roll, and about 0.39 m difference between shield hand poses.
- Physics footwork checks keep facing alignment above 0.94 while actually moving,
  with backward moves increasing separation. Particle stress/expiry checks pass.
- Both heads remained within the camera throughout sampled active fight frames.
- Multiple native recordings were inspected as consecutive frames. The first pass
  exposed dim textures; alpha-mask shaders improved their readability. The fire
  head's opaque red sphere was removed. Water trail curls were changed to irregular
  spray. Explicit 1152x720 framing also fixes cropped review-video HUD edges.
- Controlled rendered reviews cover both shield poses for each fighter, actual
  absorption, sideways/backward movement, backward rolls and both channels.

The final 60-second fight includes three natural projectile clashes and a Water
knockout win. Fire absorbs one hit (16 damage prevented), Water two (34 prevented).
Both cast six spells while airborne. Fire travels 95.1 m and Water 99.2 m. No guard
break occurs naturally in that minute; the focused physics test verifies it.
Runtime error logs from rendered reviews are empty.

A separate 16-second live run without movie encoding ends at a sampled 60 FPS on
the Radeon 610M. That is one sample, not a minimum or average benchmark.

## Reproduce

```powershell
.\run.ps1
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 60
.\tools\Godot_v4.6-stable_win64_console.exe --path . -s res://tests/defense_review.gd
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_duel_clips.gd
```

Both fighters remain autonomous. Space toggles slow motion, R restarts and Esc
quits. The prior ten-spell study and striking scene remain available.
