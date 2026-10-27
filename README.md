# FightLab — Fire × Ice × Storm

An autonomous three-way arena fight in Godot 4.6, using the Compatibility renderer.
All three enemies manage mana, stamina, guard and distance, cast spells, and fight
with punches, kicks and knees. The last survivor wins; another round starts automatically.

The main arena is a circular sandstone [colosseum](docs/colosseum.md), with a sand
floor 30 metres across, tiered seating, stacked arcades, gated entrances and physical wall slams.

## Play

Double-click `Play.bat`, or run:

```powershell
Set-Location C:\Users\forea\FightLab
.\run.ps1
```

The game opens on **Home: Story / Fight / Create**. Story is a placeholder;
Fight opens the current three-way arena. **Create → Animations** opens the
existing motion/animation editor, and **Create → Spells** opens focused casting
and impact tests. The legacy Sandbox.bat and Showcase.bat shortcuts now open Home too.

Animations starts with **Motion / Attack** at the top. Choose a category on the
left, and hover an animation to loop its actual action on the real arena fighter.
The arena is live immediately on opening Create; there is no separate preview
model or display viewport. Click to add the action to your chain.
Motion includes Run, Sprint, Jump, Dash, Crouch, Block,
Dodges and Acrobatics; Attack includes Punch, Kick, Knee, Uppercut and Spell
Throwing. Motion and Attack share one combined chain. **+ / −** edits chain
length. Jump unlocks aerial moves; Land restores grounded choices. **Run chain**
executes the physical test; **Browse** returns to the library. The bottom bar is
Run, Reset, Slow, Browse and Home. Partner behavior is one menu: no block,
palm/braced shield, jump, or jump with a shield. Repeat Setup and Weaken Guard
have been removed. Hover previews loop automatically; composed chains play once.

In Create, R replays, X resets and T slows time.
WASD moves the camera; hold middle mouse to rotate, scroll to zoom and F to
frame once. The camera stays where you place it through distance changes,
animation selections, loops and Run/Reset; it never automatically follows or
zooms toward the fighters. **Home / Esc** returns to the menu. In Fight, Space slows time, R
restarts, M mutes, F2 opens Animations and Esc returns Home. Direct commands:
`run.ps1 -Sandbox` (Animations), `-Spells`, `-Fight`, or `-Tour` for the retained
[54-case review](docs/combat-showcase.md). See the [Create guide](docs/combat-sandbox.md).
Both the full fight and review scenes use the actual combat/physics paths.
This remains an AI combat prototype; player controls are not implemented.

## Fighter kits

- **Fire:** quick or held fireballs and severing arm-swipe projectiles. Connected
  fire spells and augmented leg strikes apply a lasting burn.
- **Ice:** temporary glacial armor mitigates incoming damage. The freezing beam
  applies chill, reduces movement and can freeze an enemy inside pale leg ice;
  freeze expires and is visually separate from the blue upper-body armor.
- **Storm:** Flash Step briefly charges, dashes at 34 m/s and automatically attempts
  a momentum-powered knee. Its brief golden aura covers the charge and follow-up.
  The gold fighter is a distinct third opponent, not a teammate.
  His [14-second Overdrive](docs/overdrive.md) adds a golden lightning mantle,
  favors knees, improves melee power/endurance and reduces direct incoming damage.
  Full-speed Overdrive movement is 25.5 m/s. See the
  [Flash Step, freeze and AI planning update](docs/flash-freeze-tactics.md).

Quick projectile arm swings release faster. Ground casts can hold their gathering
pose, growing charge before release. Charge increases damage and mana cost; fire
projectiles also gain speed, size and effective mass. Charged beam grows stronger.
A held cast can be interrupted. A spell that cannot be paid for does not fire.

All fighters have jabs, crosses, hooks, front/high kicks, knees and charged
uppercuts. Mana can augment kicks/knees with elemental effects. Low mana drives
close combat; low stamina forces recovery. Punch/kick/knee hits require a sweep
of the real animated limb through an enemy hurtbox. Moving quickly can increase
physical damage, but a missed dash or strike awards no proximity hit.

## Physical response and ragdoll

Head, chest, pelvis, arms and legs retain the contact-localized spring-joint
feedback. Strong impacts instead switch to an eleven-body, ten-joint rigid-body
ragdoll. The physical bodies collide with the ground and other fighters and drive
the existing skin. A charged uppercut or overwhelming charged spell can shatter
forward guard and launch an enemy upward. Living fighters settle and play a get-up;
KO bodies remain down until the next round.

The ragdoll uses positional joints with free angular motion, tuned damping and
bounded initial velocities. It is a first pass, not a biomechanical joint-limit
model or a polished motion-matched get-up. The smaller hit-response model remains
active for ordinary blows.

## Sound and presentation

Original synthesized positional Foley covers fists, kicks/knees, heavy hits,
shield blocks/shatters, ice, bursts and landings. Twelve reusable voices keep
polyphony bounded. Video recordings include the actual audio mix.

Fire/ice/storm colors, charge glow, frost armor, ice fragments, freezing mist,
burning particles and motion trails identify the kits. The camera fits all living
fighters and pulls back for launches. Three HUD panels show health, mana, stamina,
guard and active statuses.

## Checks and recording

```powershell
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 70
.\scripts\core\review-video.ps1 -FeatureShowcase
.\scripts\core\review-video.ps1 -CombatShowcase
.\scripts\core\review-video.ps1 -SandboxShowcase
```

Validation includes a 180-second three-way fight, focused charge/status/ragdoll/
audio/melee checks and regressions against the saved two-fighter duel, casting
study and skeletal animation samples. Review recordings write a native 30 FPS AVI
with stereo audio and a JSON event timeline. Movie encoding speed is separate from
live gameplay performance.

Details: [triad combat validation](docs/triad-combat.md).

The combat foundation before the showcase is preserved in the pushed
[`milestone/combat-foundation-v1`](docs/milestones.md) Git tag.

## Sources and saved scenes

All required models, textures, animations and licenses are included for offline
use. Quaternius characters/UAL motions are CC0; clothing and adapted choreography
retain CC BY 4.0 credits; composition helpers retain MIT credits. Kenney effect
textures are CC0. Sounds are original procedural synthesis. No proprietary anime
or commercial game assets were extracted. See [asset notices](assets/combat/NOTICE.md).

The previous duel is retained in `scenes/duel_study.tscn`, the stationary ten-cast
study in `scenes/spell_study.tscn`, and striking in `scenes/sparring.tscn`.
To rebuild the knee and uppercut clips after normal import:

```powershell
.\tools\Godot_v4.6-stable_win64_console.exe --headless --path . -s res://scripts/vendor/build_battle_clips.gd
```
