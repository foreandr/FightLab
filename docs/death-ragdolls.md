# Directional death ragdolls

Every lethal direct hit now enters the physical ragdoll immediately, including
weak projectiles. The killing contact supplies the impulse and impact point;
the canned death clip cannot replace the resulting motion. Strong lethal side
and downward hits retain more momentum than a living stagger, within bounded
simulation speeds.

The same handling applies to fists, kicks and knees. Animated jabs, crosses,
hooks and charged uppercuts are covered by lethal-contact regression checks on
all three fighters. A charged uppercut transfers its upward impulse into the
corpse rather than interrupting the launch with a death animation.

A finishing hit on an airborne ragdoll preserves its bodies and pose, transfers
the new impulse across the body, and adds rotation from the contact offset.
Dead fighters stay physical until the round resets. Burn deaths collapse with
their existing motion and gravity instead of receiving an artificial upward kick.
The combat camera includes a newly defeated fighter for 1.4 seconds.

Validation covers real projectiles from six directions on all three fighters,
weak lethal hits, strong sideways/downward momentum, airborne finishers, burn
collapse, disabled upright colliders and absence of recovery after death. The
full gameplay regression suite also passes.

```powershell
.\validate.ps1
.\scripts\core\review-video.ps1 -DeathShowcase
```

The controlled native recording uses actual projectile collisions with AI paused
and low target health to make each death repeatable. It includes backward, right,
left, upward and downward hits. This remains the existing eleven-body pin-joint
ragdoll, with bounded impulses rather than anatomical joint limits.
