# Air casting readability and gravity

The main battle uses five new baked airborne casting clips covering all six kit
actions. Fireball draws its casting arm back overhead before a palm thrust;
Cinder Slash uses a wide shoulder-led cross-body sweep. Freezing Ray raises both
arms before driving the palms forward. Armor crosses the arms from a wide gather,
and Overdrive opens both arms. Flash Step reuses the broad palm gesture. Tucked
legs, torso rotation, a held wind-up and follow-through make the silhouettes read
from the combat camera. Air casts run at 1.65 animation-time speed.

The action player seeks cast time directly. Its previous timed crossfade could
remain at the take-off pose because seeking does not advance the blend clock.
Seek-driven casts now start without that stalled crossfade. A runtime regression
checks the visible raised casting hand during an actual jump, in addition to
sampling baked clips on both humanoid rigs.

Charged melee wind-ups now integrate gravity and movement. Forward bursts retain
vertical velocity instead of resetting it each frame. AI cannot start another
ground jump/action while airborne. Falling fighters temporarily ignore upright
fighter collision bodies, and restore body separation after clearing overlap,
so another fighter's head cannot become a floating landing platform. Hurtbox
areas and attack collisions remain active. World walls and floor still collide.

Focused checks cover arm travel, actual cast playback, charge/burst/freeze falling,
all six jumping kit actions returning to the floor and rejected midair re-jumps.
The full suite includes 180 seconds of autonomous combat, wall containment,
death ragdolls and grounded recovery. The rendered showcase uses actual jumps
and spell actions for all six kit entries.

```powershell
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_battle_clips.gd
.\validate.ps1
.\scripts\core\review-video.ps1 -AirShowcase
```
