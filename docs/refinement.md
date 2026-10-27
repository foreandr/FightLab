# Bilateral strike refinement — 2026-10-26

Both fighters now use both hands and both legs. The eight moves are left jab,
right cross, left/right hooks, left/right front kicks and left/right high kicks.

## What changed

Reused upstream kick choreography is baked separately for each striking leg from
the existing guard, without mirroring the entire fighter or switching stance.
Front kicks have a longer knee chamber, more deliberate extension and recoil,
less arm drop, and a higher body target. High kicks rise outside the torso before
sweeping across at head height. Contact follows the ball of the actual kicking
foot with a smaller query shape, after chambering rather than during the knee lift.

Dense 60 Hz baked poses solve the support leg at every sample and pivot around
the planted ball of the foot. Sparse cubic interpolation no longer lifts/slides
the support foot between authored key poses. No runtime procedural limb animation
or new dependency is required. The existing rig, physics queries and locomotion
remain in use. Starting a strike resets reverse walk playback speed.

## Video debugging

Recorded an isolated kick review at 30 FPS (19.2 seconds), extracted consecutive
frames at 12 FPS around each kick, then changed the high-kick approach after seeing
that the left foot initially swept up through the torso. Recorded the corrected
review again: all eight kicks connected exactly once with the intended body/head
zone. Also recorded 40 seconds of fully autonomous fighting and inspected its
frame sequences for contact, spacing, recoil, falls and recovery.

The repeatable workflow is now part of the repository:

```powershell
.\scripts\core\review-video.ps1 -IsolateKicks
.\scripts\core\review-video.ps1 -Seconds 40
```

It produces a 30 FPS AVI and a JSON contact timeline in ignored `builds/review-*`.
Video encoding speed is not gameplay FPS. No video encoder dependency is needed
for this native Godot recording workflow.

## Validation

Full `validate.ps1` passed without Godot errors:

- 180-second autonomous phase: 79 contacts, 33 punches, 46 kicks, 20 knockdowns.
- All eight moves landed. Each NPC attempted and landed with all four limbs.
- Recovery, center separation (minimum 0.6893 m), disabled hurtboxes at close range,
  and every move missing at long range passed.
- Sampled every kick at 120 Hz on both character rigs. Maximum support-ball drift:
  1.85 mm on the male rig and 22.25 mm on the female rig.
- Isolated contact review: left/right front kicks hit the body and left/right
  high kicks hit the head, once each, for both characters.
- The PowerShell video helper successfully generated both the movie and timeline.

Autonomous landed strikes by limb:

| Fighter | Left hand | Right hand | Left foot | Right foot |
|---|---:|---:|---:|---:|
| Red | 15 | 6 | 8 | 14 |
| Blue | 7 | 5 | 9 | 15 |

A separate 25-second rendered run on the Radeon 610M at 1280x800, with screenshot
and movie saving disabled, ended at a sampled 69 FPS. This is a single FPS sample,
not a guaranteed minimum or an average benchmark. Its log contained no Godot errors.

The scene still uses stylized models and animation-driven knockdowns. Defensive
forearm blocking, fully physical balance, active ragdolls and more varied tactics
remain outside this refinement. These improvements do not claim UFC-level realism.
