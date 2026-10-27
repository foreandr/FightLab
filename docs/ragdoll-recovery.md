# Grounded ragdoll recovery

Living fighters now need 0.35 seconds of continuous, stable floor contact before
recovery, with a minimum 1.4-second ragdoll duration. Pelvis/chest speed and chest
rotation must settle; old floor contact does not allow recovery during a later
bounce. A fresh impulse resets this settling clock. Death still prevents get-up.

The handoff captures every bone's world pose before moving the character root.
The get-up heading follows the lying head/pelvis direction and its pelvis is
aligned horizontally to the landing location, within the courtyard. The source
pose is reconstructed in the new root space so no bone teleports at handoff.

Recovery blends from that landing pose over 0.45 seconds. The first 0.25 seconds
hold the opening ground pose while the body gathers, then LayToIdle plays at
1.05 speed instead of 1.5. Duration comes from the actual clip length. The upright
collider returns when the rise finishes, with recovery protection covering the
transition.

Focused checks cover positional/rotational continuity on all three rigs, ground
dwell, the initial gather, completion and collider restoration. The 180-second
autonomous fight and saved combat regressions also pass. A native controlled
recording shows all three models landing, settling, blending and rising.

```powershell
.\validate.ps1
.\scripts\core\review-video.ps1 -RecoveryShowcase
```

This uses the existing get-up clip with pose blending and heading alignment;
separate prone/supine recovery clips and full foot/hand placement are not added.
