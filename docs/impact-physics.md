# Localized impact physics — 2026-10-27

The duel now uses contact location and incoming momentum to drive a reduced
articulated physical response, blended over the animated character. It replaces
the same generic chest-flinch clip and fixed 2.5 m/s shove for every hit.

## Contacts and momentum

The existing head/chest/pelvis hurtboxes now carry bone metadata. Eight additional
capsules follow upper/lower arms and thighs/calves through each evaluated pose.
Their centers, axes and lengths follow the current bone endpoints. The deformed
physical pose therefore also changes the next frame's actual collision geometry.

Projectile and fist sweeps pass the actual struck collider into the damage/reaction
path. Channels preserve the collider and ray contact. Expanding spells reconstruct
a capsule-surface contact and choose the closest overlapping hurtbox. The water
surge's low collision volume contacts legs, rather than synthesizing a chest hit.

Projectile impulse uses current velocity times a tuned effective spell mass.
Fist impulse uses measured animated fist velocity and an effective striking mass.
Channels and shockwaves use tuned impulses along their actual incoming direction.
These values are independent of health damage. Shield absorption transmits a
reduced impulse through the guard; overflow transfers its remaining share to the
struck body part. Gameplay limits cap extreme impulses and root speeds.

## Articulated response

The new `impact_physics.gd` model maintains angular displacement and velocity for
pelvis, two spine joints, neck/head, arms, thighs and calves. Each joint has tuned
principal inertia, stiffness, damping and per-axis limits. It computes angular
impulse from the contact lever arm crossed with incoming impulse, distributes
part of that through the connected body chain, and divides by joint inertia.

Fixed bounded substeps integrate the damped angular springs. Animation supplies
their moving equilibrium. Model/actor frame conversion handles different rig
orientations; offsets are restored before the next animation evaluation so they
do not accumulate into permanent deformation.

- Off-centre torso hits produce twist plus lean; opposite-side impacts reverse it.
- Head hits preferentially drive head and neck, with some shoulder transmission.
- Arm hits deflect the struck arm and transmit a smaller share to the torso.
- Leg hits move the affected thigh/calf, add compliant knee bend and disrupt support.
  Support loss temporarily slows movement and costs some stamina.
- Root impulse produces actual collision-constrained CharacterBody movement.
  Airborne hits alter momentum and vertical velocity; gravity and floor contact
  continue to act. Damping removes the shove over time.

This is an animation-driven reduced joint model, not a free PhysicalBone rigid-body
ragdoll. Individual limbs do not solve independent world collisions, and the root
remains an upright CharacterBody. It provides location/direction-sensitive physical
feedback while retaining controlled running, casting, flips and fistfighting.
Health damage is unchanged by body-zone multipliers in this pass.

## Verification

`validate.ps1` passed in both the working project and a fresh staged-file package
without an import cache. It includes `tests/impact_physics_test.gd` alongside the earlier duel,
resource, shield, movement and casting checks. The impact checks:

- Fire actual projectiles at head, torso and both lower legs on each rig.
- Verify collider metadata, directional root shove, mirrored off-centre torque,
  local joint movement and leg support/stamina disruption.
- Double projectile speed and verify a stronger impulse with identical health damage.
- Verify shield absorption transfers smaller physical recoil without health damage.
- Verify the low water surge contacts a leg.
- Let the springs settle and check finite state and absence of pose drift.
- Compare equal simulation time at 30/60 FPS using bounded integration substeps.

The torso-only test isolates guarded forearms to measure the torso joint response.
All normal fight hurtboxes remain enabled; an arm may correctly intercept a shot
before the chest. The long duel additionally checks physical-response activity,
health/resource bounds, camera framing, KOs, melee, shields and cleanup.

Controlled native close-ups (`tests/impact_review.gd`) show opposite torso hits,
head hits and both leg hits for both fighters. They use the actual projectile and
collision paths; torso-only review likewise isolates guarded forearms. Consecutive
frames were inspected at contact, peak motion and recovery. The normal fight is
also recorded with every hurtbox enabled. Hit events now include zone, bone,
contact point and impulse, and reports count physical contacts by zone.

The final uninterrupted 70-second recording logged 22 physical contacts on Fire
and 23 on Water, including head, chest, arms and a leg on each fighter. A ground
spell hit Fire's right leg at 11.07 s; an aerial heavy projectile hit Water's head
at 26.33 s. These are normal autonomous contacts with every hurtbox enabled.
Fire won the first round and the second began automatically. Rendered review
runtime error logs were empty.

No new asset, plugin, animation download or external dependency was introduced.

```powershell
.\run.ps1
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 70
.\tools\Godot_v4.6-stable_win64_console.exe --path . -s res://tests/impact_review.gd
```

Space toggles slow motion, R restarts and Esc quits. Fighters remain autonomous.
