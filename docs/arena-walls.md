# Finite courtyard and wall crashes

The main three-fighter meadow now has a 20 m square fighting area. Four static
collision walls rise 18 m, with a stone base, pillars and translucent upper
barriers so airborne fighting remains visible. The upper panels are solid to
fighters, ragdolls and projectiles. The saved two-fighter study remains separate.

Physical ragdoll contacts use incoming limb or whole-body velocity to detect a
hard crash. The rigid-body solver supplies the actual bounce and tumble. Fast
upright knockback into a wall becomes a ragdoll with a bounded rebound. Ordinary
walking simply stops at the boundary.

Crashes above 4.5 m/s produce a heavy positional impact sound and dust. Living
fighters lose health, stamina and guard in proportion to impact speed, capped at
22 health per crash, with a 0.65-second cooldown shared by all body parts. Wall
damage credits the last attacker when available. A lethal wall slam preserves
the existing physical body; surviving ragdolls can settle and recover. Walls do
not count as floor contacts for recovery. Beams and projectiles stop at walls.

Validation includes all four boundaries with living and dead ragdolls, physical
containment, bounded crash damage, living recovery, lethal wall damage, upright
knockback, harmless walking and projectile blocking. The 180-second autonomous
fight checks containment, finite physics, resource bounds, cleanup and framing.
The full saved-combat regression suite passes. The controlled rendered showcase
records actual charged fireball contacts, with both living and lethal wall slams.

```powershell
.\validate.ps1
.\scripts\core\review-video.ps1 -WallShowcase
```

The walls are fixed geometry; this pass does not include destruction or broken
wall pieces. Upper barriers are intentionally translucent for camera visibility.
