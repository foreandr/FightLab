# Validation — 2026-10-26

Latest: [Fire × Ice × Storm](triad-combat.md). Previous: [localized impacts](impact-physics.md), [mana/stamina and melee](resources-melee.md), [shields and effects](defense-vfx.md), [dynamic duel](elemental-duel.md), [grassland study](spell-study.md), [bilateral kicks](refinement.md). The notes below describe the first prototype.

Engine: Godot 4.6 stable, Compatibility renderer, Windows 11.
GPU identified by the rendered application: AMD Radeon(TM) 610M.

## Rendered inspection

The demo was launched repeatedly with frame capture, followed by a 20-second
960x600 movie recording. Inspected frames include stance, front-kick contact,
jab contact, close hook contact, high kick, prone knockdown and recovery.

The 40-second 1280x800 capture run reported 19 contacts (9 punches, 10 kicks),
4 knockdowns, minimum center spacing 0.6895 m and a final FPS sample of 34.
Both NPCs landed strikes. No runtime errors were logged. FPS is a sample on this
machine, not a minimum/average benchmark; capture and recording add overhead.
The final retreat change reverses the guarded-walk clip when moving backward.

Visible corrections made after the initial run:

- Replaced the excessively low, fast melee lunge with a compact hook baked using
  upstream IK and planted-foot helpers; adjusted its actual contact range.
- Reduced lighting washout and added the licensed hair/eyebrow meshes.
- Excluded retracting/very slow limbs from scoring a hit.
- Fixed imported outfit texture dependencies and hair ownership warnings.

## Automated validation

`validate.ps1` passed editor import, scene startup and the physics integration test.
The final 90-second autonomous phase registered 37 contacts: 18 punches, 19 kicks,
9 knockdowns; jabs, crosses, hooks and both kicks all landed. Recovery was asserted.
Minimum center spacing was 0.6895 m. Both NPCs landed hits.
Additional phases disable hurtboxes at close range and then restore them at
4 m range: all five moves must score zero additional contacts in both phases.
No Godot errors were emitted.

## Remaining limitations

The result is a working, visibly improved sparring prototype. It does not yet
meet the requested realistic/UFC-like motion and physics quality. Meshes and
some transitions are stylized; hit reactions are limited authored clips.
Knockback uses CharacterBody3D motion resolved by Godot collision; falls and
stand-ups are skeletal clips. There is no active ragdoll, dynamic balance solver,
full skeletal rigid-body contact or collision against defensive forearms.
AI follows a varied move sequence and spacing rules rather than advanced tactics.
Feet can slide during transitions, and the recovery cross-fade needs refinement.

A fresh directory containing only staged repository files also passed the full
validation, confirming that ignored downloads and existing import caches are not
required. Licenses and all required assets are included in that package.
