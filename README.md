# FightLab — Grassland Spell Study

A hands-free spellcasting demonstration in **Godot 4.6 stable**, using the
Compatibility renderer for integrated graphics. The ring has been replaced by
an open meadow with grass, distant hills and a daylight sky.

A caster stands **3.8 metres** from a stationary target and automatically cycles
through ten skeletal casting animations. The target never walks or counterattacks;
it stays in place and briefly reacts when a spell physically hits it.

## Launch

Double-click `C:\Users\forea\FightLab\Play.bat`, or launch the current local files:

```powershell
Set-Location C:\Users\forea\FightLab
.\run.ps1
```

- **N:** skip to the next casting motion.
- **Space:** toggle slow motion.
- **R:** restart the study.
- **Esc:** quit.

Godot 4.6 is discovered automatically, or use `GODOT_PATH` / `-GodotPath`.
All required characters and animations are versioned. No asset download is needed.

## The ten casts

| Cast | Motion | Effect |
|---|---|---|
| Palm Fireball | Draw back and extend the right palm | Fireball |
| Severing Flick | Finger-led horizontal arm slash | Fiery crescent |
| Cinder Cleave | Raise both hands and chop downward | Vertical flame slash |
| Verdant Mend | Gather light and draw both hands to the chest | Green self-heal aura |
| Twin-Palm Blast | Compress an ember, then push with both hands | Larger fire orb |
| Offhand Spark | Quick left-hand palm cast | Small firebolt |
| Sun Spear | Draw above the shoulder and throw overhead | Fire lance |
| Ground Sigil | Sink through the knees and press toward the earth | Rune and ground flame |
| Solar Nova | Coil inward, then open both arms wide | Expanding fire pulse |
| Flame Channel | Brace both palms forward | Sustained flame stream |

Each gesture gets about 3.6 seconds, including preparation, release and recovery.
Spell origins follow the animated hands. Projectiles and the channel use Godot
ray queries; the nova uses a growing physics shape. Self-heal affects the caster.
The scene is a motion/effects study, without menus, progression or combat AI.

## Validation and video review

```powershell
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 36
```

Validation checks the entire ten-cast cycle, nine offensive impacts, self-heal,
fixed character positions, cleanup, missing target collision and a target moving
out of a fireball's path. It also samples all ten clips on both compatible rigs
for distinct release poses and grounded feet.

The video command writes a native 30 FPS AVI and a timestamped JSON report into
`builds/review-*`. Compare consecutive frames around each release/impact, rather
than judging the animation from a single screenshot. Recording speed is not a
measure of live gameplay FPS. See [spell-study validation](docs/spell-study.md).

To rebuild the casting clips:

```powershell
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_spell_clips.gd
```

The casts are original authored poses composed with the existing skeletal IK and
foot-plant helpers, not motion capture or copied animations from proprietary games.
The licensed Quaternius characters, rigs, hair and base poses remain in use.
Full attribution is in [asset notices](assets/combat/NOTICE.md).

The previous sparring experiment remains in `scenes/sparring.tscn` for regression
work. It is not the default demonstration; no kick or fighting AI runs in the meadow.
