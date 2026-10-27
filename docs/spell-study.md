# Grassland spell study — 2026-10-26

The default scene is now a spellcasting motion study in a generated meadow.
A caster and a target stay 3.8 m apart. The target never approaches, counters,
staggers across the field or falls; it briefly flinches on an actual spell hit.
The ring and kick AI are absent from this scene. Previous sparring remains in
`scenes/sparring.tscn`, with its regression scripts pointed at that archived scene.

## Casting motions

Ten original skeletal clips plus a neutral casting idle were composed on the
existing licensed Quaternius rig using the vendored IK/foot-plant helpers:

1. Palm Fireball — right-palm extension with shoulder turn.
2. Severing Flick — compact horizontal, finger-led arm sweep.
3. Cinder Cleave — two-handed overhead preparation and downward chop.
4. Verdant Mend — gather light and bring both hands toward the chest.
5. Twin-Palm Blast — compress an ember and push with both hands.
6. Offhand Spark — left-palm extension with the opposite shoulder leading.
7. Sun Spear — overhand wind-up and throw.
8. Ground Sigil — knee bend and downward palm press.
9. Solar Nova — inward coil followed by a wide arm opening.
10. Flame Channel — braced two-hand extension with a sustained hold.

The references supplied by the user guided the gesture ideas. No proprietary
animation or game assets were extracted. New motion is baked skeletal animation,
with cross-fades and dense planted-foot sampling; it is not primitive-mesh rotation.
The self-heal is a visual activation in this study; there is no health/progression UI.

## Visual development loop

Recorded the full sequence and inspected consecutive frames around the slash,
overhead chop and self-heal, alongside release frames for all ten gestures.
The visual pass tightened camera framing, reduced the green fog on the sky,
refined grass blades, billboarded the slash crescents for readability, added hot
fire cores and denser flame trails, and corrected capture timing to save one
release frame per cast. A final 36.1-second movie includes the whole sequence.

## Validation

- `validate.ps1` passed import, startup, the full spell integration check and
  skeletal pose sampling, with no Godot errors.
- Two autonomous cycles: each of the ten casts appeared twice; all nine offensive
  spells hit once per cycle, for 18 target hits; self-heal activated twice.
- Target and caster root positions stayed fixed throughout the automatic cycles.
- With target collision disabled, no projectile, pulse or beam registered a hit.
- A fireball missed when the target moved out of its already launched trajectory.
- Spent projectiles, pulse meshes, beams and particles cleaned up across loops.
- All ten release hand poses were distinct on both imported rigs. Maximum foot
  drift across every sampled clip: 6.72 mm male, 17.43 mm female.
- The final rendered movie showed all ten casts, nine hits and one self-heal,
  with empty runtime error logs.
- A separate 12-second 1152x720 live run, with recording and frame saving disabled,
  ended at a sampled 58 FPS on the AMD Radeon 610M. This is a sample, not a
  minimum/average benchmark; native movie encoding speed is measured separately.

## Reproduce

```powershell
.\run.ps1
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 36
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_spell_clips.gd
```

N advances immediately to the next cast and clears the previous spell effects.
Space toggles slow motion, R restarts and Esc quits.
The meadow, sky and VFX are lightweight procedural geometry/materials. They remain
stylized prototypes; the focus is readable casting gestures and release timing.

A fresh directory containing only the staged repository files passed the same
validation, confirming that the new scene does not depend on ignored downloads
or an existing import cache.
