# Fire × Ice × Storm — 2026-10-27

The default scene is a three-way autonomous fight. Every other living character
is an enemy; targets update by proximity and threat, and an elimination leaves the
remaining two fighting. Only the final survivor wins. An equilateral starting
layout and cyclic initial targets avoid starting with both casters assigned to
the same nearest opponent. Health, mana, stamina, guard and statuses reset for
automatic rematches.

The prior duel is preserved in `scenes/duel_study.tscn`. Its existing regression
tests now load that saved scene explicitly. Shared cast/animation/movement hooks
preserve the old behavior by default; the new battle scripts supply the triad rules.

## Abilities, timing and resources

| Fighter | Spell kit | Lasting effects |
|---|---|---|
| Fire | Fireball; severing arm-swipe Cinder Slash | Burn after a connected spell or augmented leg strike |
| Ice | Glacial Armor; Freezing Ray | Temporary mitigation; chill and accumulated freeze |
| Storm | Overdrive; Flash Step | Faster sprinting and a forward dash that can feed into melee |

Quick fireball/slash gestures advance at 2.9 source seconds per second, compared
with the prior 1.65. Fireball's nominal windup is about 0.23 s. Ground projectile
casts can hold their gathering pose, accumulate charge, then complete the swing.
AI uses charge when resources/opportunity permit; the feature study requests
specific holds. Air casts remain quick. Interrupted holds emit no projectile.

At full charge, fire projectile damage is 2.2 times base, speed 1.7 times base,
collision radius 1.9 times base and effective mass 2.8 times base. Mana cost rises
by up to 80%. Affordable charge is capped by current mana, and actual release
must still be paid. Held ice beam grows stronger and wider as well.

Base costs: fireball 14, slash 12, ice armor 20, ice beam 22, overdrive 18 and flash
step 9 mana. A forward burst spends 14 stamina and reserves enough for a following
strike. Kicks/knees can spend 5 mana for elemental augmentation. Existing low-mana
melee, stamina recovery, strafing, retreat, jumping and airborne casting remain.

Armor lasts 6.5 s, holds 50 mitigation capacity and absorbs 55% of a damaging
contact until exhausted. Overdrive lasts 7 s and increases the speed fighter's
already higher movement multiplier. Chill reduces locomotion to 60% for 3.5 s.
Ice contact accumulates frost; freeze lasts 1.25 s with an immunity window so it
can expire. Fire burn refreshes a bounded duration and ticks 1.5 damage every 0.5 s.
Burn ticks award damage to their source and can eliminate a fighter.

All fighters use jabs, crosses, hooks, front/high kicks, an authored knee and a
charged uppercut. Limb sweeps decide contacts. Measured relative limb velocity
and a short dash-combo momentum window increase damage/impulse, up to a tuned cap.
Whiffs do no health damage. Augmented Fire leg strikes burn; Ice strikes chill;
Storm's boosts support rapid movement into strikes. These are gameplay tuning
rules rather than a claim of exact biomechanics or damage-energy equivalence.

## Ragdoll launches

Ordinary contacts keep the localized spring-joint response. Strong impulses
(normally at least 440) or a charged guard break can switch to actual ragdoll.
Charged uppercuts provide an upward impulse, and sufficiently charged projectiles
can add lift. Guard pressure accounts for charge/impulse; insufficient guard
shatters, transmits overflow damage and can allow a launch.

The ragdoll contains eleven `RigidBody3D` capsules, totaling 75 effective mass,
connected by ten positional joints. The engine applies gravity and collision
response; the bodies drive the existing skinned bones while animation is paused.
Bodies collide with the meadow and other fighters. Initial launch/spin are bounded.
Initialization waits for physics registration before unfreezing the joined bodies.
Ground contact produces a landing sound. A living settled body restores controlled
animation and plays a get-up; a KO stays down until round reset.

This is a first pass with free angular joint motion, not anatomically limited
elbows/knees or a motion-matched recovery system. Self-collision is disabled to
keep the small-body setup stable on integrated graphics. It is nevertheless a
rigid-body/world-collision ragdoll, rather than an airborne death animation.

## Sound and visual review

Original deterministic synthesis produces reusable signed PCM Foley for fists,
kicks/knees, heavy hits, guard/shatter, ice, dash and landing. A bounded pool of
twelve positional voices prevents unbounded players. M toggles sound. Audio is
included in native review recordings and exported MP4s.

Ice has faceted geometry, frost materials, a bright freezing beam, chips, mist and
visible armor/freeze plates. Fire keeps flame and slash effects; Storm has gold
clothing, augmentation glow and speed trails. Three HUD panels show named pools
and statuses. Camera fitting accounts for launches and the HUD's upper coverage.

Recorded multiple normal fights and controlled feature passes. Inspected the
gather/hold/release, guard shatter, full airborne rigid-body motion, landing/get-up,
beam freeze, armor, dash-to-strike and augmented knee. Review corrections included
an earlier knee/uppercut contact window, a forward-reaching strike pose, camera
framing, sound level and ragdoll stability. The unstable angular constraint setup
was replaced with bounded positional joints; the corrected long-run check passed.

## Validation

`validate.ps1` passed in the working project and in a fresh staged-file package
without its import cache. It includes focused feature checks, 180 simulated seconds of the new
fight, and the saved duel's resource, local-impact, defense, movement and casting
regressions. Focused checks verify:

- Three distinct kits and enemy-only collision masks; no free spell without mana.
- Faster quick release; held pose without premature emission; one charged release.
- Charge scaling of damage, cost, speed, size and mass.
- A shattered forward guard followed by a bounded actual rigid-body launch and recovery.
- Funded armor mitigation; lasting burn; ice slow/freeze and thaw.
- A physical forward-dash combo, actual knee/kick contacts and charged uppercut launch.
- Non-silent PCM buffers, bounded audio voices and last-survivor round/reset rules.

The long run checks finite/bounded resources and physical state, HUD agreement,
ragdoll cleanup, every kit's participation, charge/status use, real melee/dash
combos, effects limits, automatic rounds and camera coverage. Earlier focused
physics tests still verify head/torso/leg contacts and mirror-direction responses
in the saved duel.

The final 180-second check measured a maximum ragdoll-body speed of 18.82 and
camera coverage of 99.99% for sampled living heads. The ordinary 70-second native
recording completed two rounds and entered a third. It recorded charged fire
casts, freezing, eleven ragdoll transitions, four living recoveries and four Storm
dash-combo contacts. Maximum recorded ragdoll pelvis height was about 9.1 m.
Both normal and focused rendered runs ended with empty runtime-error logs. The
focused audio mix contained stereo sound, with measured peak about -17.6 dBFS;
the MP4 exports retain this mix rather than stripping it.

A separate 16-second live run without movie encoding or background export/test
load ended at a sampled 57 FPS on the Radeon 610M. This is one sample, not a
minimum or average benchmark. Recorded-movie encoding speed is separate.

## Reproduce

```powershell
.\run.ps1
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 70
.\scripts\core\review-video.ps1 -FeatureShowcase
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_battle_clips.gd
```

The native feature recording uses real cast, limb and projectile collision paths;
it pauses AI only to make the requested interactions repeatable. The ordinary
fight leaves all three AIs active. This is an initial tuning pass with reused
characters, not commercial anime-game polish or player-controlled combat.
