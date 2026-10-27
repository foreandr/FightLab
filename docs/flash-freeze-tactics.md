# Charged Flash Step, frozen legs and resource planning

Flash Step charges for 0.28 seconds, displays a short golden power-up aura, then
dashes at 34 m/s (previously 17). It automatically attempts a knee at the end,
independent of the normal strike sequence. Movement brakes at knee range instead
of stepping through the target. The knee still requires a real animated-limb
contact; missing, interruption and wall collisions remain possible. Funding checks
cover the dash and knee before spending spell mana. The paid dash powers its
elemental knee without another mana payment. The short aura does not grant the
full fourteen-second Overdrive buff.

Full-speed Overdrive running/pursuit reaches 25.5 m/s, 75% of Flash Step. Slower
movement inputs remain proportionally slower. Chill and physical support loss
still reduce speed, and chase movement brakes near the target. Gravity continues
during charge and dash, including airborne casts.

Freeze now displays opaque, pale, jagged frost casings on thighs, shins and feet.
These track the actual leg bones with a separate matte frost shader. Glacial
Armor retains its blue, glossy upper-body pieces and independent timer/HP pool.
Both can be visible together; freeze no longer toggles armor pieces. Chill mist
also originates at the legs.

AI recovery checks precede attack shortcuts. A tired fighter commits to a
60-stamina reserve instead of immediately spending the first affordable attack.
Repeated attempts without damage, or a longer absence of personal damage
progress, trigger saving toward 65 stamina and a kit-specific mana reserve.
Fighters back away/circle while recovering. Once funded, the plan changes to a
charged alternative, Overdrive, a charged uppercut or closer pursuit. Recovery
has a timeout, and failed Flash Step tactics temporarily suppress another burst.
The HUD identifies deliberate recovery. These decisions never award fake hits.

Focused tests exercise actual charged dashes/knees with different move cursors,
real 34/25.5 m/s movement, chain funding, aura expiry, leg attachment/material
separation and resource hysteresis. An autonomous fighter against disabled enemy
hurtboxes also saves and replans after genuine misses without damaging them.
The full suite passes. The 180-second fight completed six rounds; the longest
interval without damage during active combat was about 6.18 seconds in this run.
This sample does not guarantee that every possible AI stalemate is eliminated.

```powershell
.\validate.ps1
.\scripts\core\review-video.ps1 -FlashFreezeShowcase
```
