# Colosseum arena

The main battle now takes place in a complete circular colosseum instead of the
grass courtyard. A sand fighting floor, ashlar retaining wall and four recessed
portcullises sit inside twelve rising stone seating rows with radial stair
aisles. Two stacked arcade levels, projecting cornices, exterior arched recesses
and Fire/Ice/Storm-colored hanging standards form the outer building. The
structure is about 56 m across, enclosing a 30 m diameter fighting floor.

Architecture is baked into 40 sector meshes sharing one stone material. The
foreground architecture is cut away only when a low combat camera pulls outside
the bowl; overhead views reveal the complete building. Warm daylight replaces
the meadow lighting, and sand replaces grass and distant green hills. The saved
duel and casting studies keep their earlier settings.

Forty overlapping collision segments provide a circular physical boundary.
The existing crash damage, dust, audio, ragdoll bounce and death behavior remain.
A faint golden ward above the retaining wall makes the upper 18 m containment
visible during high launches; seating and arcades are scenery outside the active
combat boundary. Gates are closed scenery, not traversable exits. Recovery roots
are placed within the circular floor rather than a square clamp.

Wall regression checks now throw living/dead ragdolls in eight directions. The
180-second autonomous battle checks radial containment of every fighter and
ragdoll part, resources, cleanup, recovery, kit participation and camera framing.
The full gameplay regression suite passes. A native showcase records a complete
overhead view followed by ordinary autonomous combat in the new setting.

```powershell
.\run.ps1
.\validate.ps1
.\scripts\core\review-video.ps1 -ColosseumShowcase
```

This is original procedural stylized architecture. It does not include a crowd,
destructible stands or navigable spectator seating.

The fighting floor was widened from 20 m to 30 m across: 50% more width and
2.25 times the area. Starting separation, movement limits, wall fixtures and
recovery bounds expand with it; the seating keeps its original row depth/height.
