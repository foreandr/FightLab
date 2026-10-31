# Saved milestones

Create starts with BOT_1 selected at the center of the ring and an empty
timeline. At least one editor bot is maintained; additional bots continue as
BOT_2, BOT_3, and so on. The simplified Spells demo also uses the ring center.

## Current spell workspace: projectile-first

Spells opens to five requested collection animations: Left cross, Melee hook,
Left knee, Block stand and Self mend. Exact personal-library matches take
precedence over the starter library. Native imported clips play directly.
Selecting one highlights it and previews the motion once. Confirm advances to
Projectile, Targeted, Touch or Barrier. Targeted, Touch and Barrier are currently
disabled; Projectile is available. The wider rear-side camera leaves space
ahead of the caster and stays fixed across these steps. The type selection is
saved with the spell draft. Back returns to the demo choices. Changing the demo
animation returns to the first step without discarding the selected type.
Projectile starts elementless. The left card previews effects on click and saves
only on Confirm. Duration, green stamina depletion, red physical damage, blue
mana cost and purple Spell amp remain in the right card. Playback has a separate
bottom row. Preview effects never overwrite a confirmed choice until confirmed.
Offensive demo stamina is its one-second base effort divided by duration squared,
capped at 100; physical damage uses the shared combat formula. Block stand and
Self mend have no physical damage. Preview stamina visibly depletes and recovers.
Only Fire and No effect are selectable; other elements remain visible but disabled.
The Spell timing slider sits beneath Animation duration in the right card and
spans 5–55% of the animation: early cast through the motion's apex, excluding
recovery. One Spell amp readout combines duration and timing. Timing contributes
+0% at 5% through +100% at 55%, multiplying the duration amplifier. No release
percentage/time or separate Timing amp readout is displayed. It increases projectile hit
damage and elemental potency. Motion stamina supplies the physical damage base;
projectile impact multiplies it by actual flight speed / 14 m/s. Twice the speed
means twice the physical impact, including speed earned through Spell amp without
counting that amp twice. The red Physical damage readout shows this final hit value;
burn damage stays separate. Spell amp also multiplies projectile diameter and speed.
The right card shows the actual mana cost at the top with base × cost percentage,
then the combined Spell amp, size multiplier/diameter, and speed multiplier/m/s.
Elementless projectile base cost is 10 mana: 0.5 seconds costs 14.1 mana;
late timing gives +100% Spell amp, 2× diameter and 2× speed. Earned bonuses apply
after validation of the base size/speed, so base limits do not erase the bonus.
All sliders are in the right card, including Power balance, sharing 100% between Size and Speed
for No effect, or Size, Speed and Burn for Fire. Raising one slider redistributes
the remaining budget proportionally across its peers, including recovery from a
100% allocation. Each effect remembers its own balance in the spell draft and
provenance. Size maps through the existing logarithmic radius range, speed through
1–50 m/s, and Burn through 0–4 base potency; Spell amp then scales the results.
The right panel reports amplified diameter, speed and Fire burn damage per second
for four seconds. Zero Burn creates no burn/status/ground-fire effect. Balancing
does not alter the base mana price or duration cost multiplier. The right controls
scroll when needed; the left panel contains choices, Confirm and Back only.
Release occurs before animation completion handling, including at
the apex, and the release fraction persists with the spell draft and provenance.
Play casts once, Repeat loops until switched off, and Slow mo previews at quarter
speed. Leaving the projectile page disables looping and restores the prior speed.
In Spells, W approaches the practice target, A/D strafe, and S backpedals while
the caster keeps facing the target. Combining keys gives normalized diagonal
movement with blended forward/backward and strafe cycles, without extra speed.
Shift runs; starting, stopping and direction changes blend smoothly. Take Control
uses the same directional clips and diagonal blending with camera-forward facing.
`tests/creation_directional_movement_test.gd` verifies eight directions, poses,
speed, facing, sprint, idle return and parity between both Create control modes.
The camera
follows translation and mouse camera controls remain available.
F focuses the camera on the spell caster or selected animation character without
moving the character or restarting playback; text entry suppresses the shortcut.
Spellcrafting uses the normal arena selection controls for the caster, wooden
dummy and human target: hover shows a blue ring, click makes the selection gold,
and F centers that gold selection while preserving camera orbit/zoom. Rings and
click handling share the normal editor implementation, with the pickable arena
area spanning the space between the spell panels. Dragging retains placement in
the practice workspace; returning to animations restores the normal bot selection.
A visible training mannequin starts 3.5 m ahead. Its real hurtboxes are enabled only for this practice
workspace, with health loss, normal impact reactions and floating damage numbers.
It is visibly a wooden combat dummy: cross-foot stand, grained timber post and
peg arms, padded torso with painted bullseye, and a blank wooden head. Its own
capsule hitboxes match the visible parts. The native human model stays hidden;
hits wobble the wooden body and mortal defeat tips it over without a human
ragdoll. Reset restores it upright, and leaving Spells restores the original actor.
The caster and mannequin both appear in the arena view on entry; the caster faces
the mannequin. Spell previews aim from the actual emitting hand to the mannequin's
chest at release, including after repositioning, for immediate target practice.
A passive human target also appears three metres to the wooden dummy's right.
It uses Idle cannon while standing at its practice home, including after reset
and returning from a hit, instead of the guard/block pose. It uses the normal
human model and is mortal by default, independently of the
dummy's God mode. Its death does not end practice; Reset scene heals/revives and
repositions all three. `tests/spell_human_target_test.gd` verifies placement,
visibility within the arena view, mortal damage, reset and workspace isolation.
It returns to its base after impacts. God mode defaults On for endless damage
testing: real hit/burn damage is counted, with only Last spell damage displayed
under the mannequin name. DPS and total damage are hidden. God mode Off allows normal health loss
and death; the corpse stays until Reset mannequin or God mode is enabled again.
There is no automatic respawn. Normal mannequin death does not end the workspace.
The God mode preference saves separately from the spell asset. Other immortal/editor
actors retain their existing health behavior.
The bottom Reset scene button stops playback/repeat/slow motion, heals and revives
the practice fighters, refills resources, restores placements/camera, and clears
projectiles, environment effects, statuses and damage totals. It preserves the
demo animation, duration, release timing, effect choice, power allocation and God
mode preference. `tests/spell_scene_reset_test.gd` verifies the complete reset.
`tests/spell_practice_test.gd` verifies key input, movement/camera follow, an actual
projectile hit, mortal death, manual reset, repeated lethal God-mode hits, damage
readouts and preference persistence in a rendered game.
Left cross is the default, and the demo remains explicitly preview-only.
The right-side timing card has one 0.1–60 second slider. It retimes the full
demo and displays mana savings using `2^(1-duration)` below ten seconds:
one second is neutral, two seconds saves 50%, four seconds saves 87.5%.
At ten seconds mana saving becomes exactly 100% and stops increasing.
Duration Spell amp is neutral at one second, then increases linearly to +100%
at ten seconds. With charge `max(0, duration-1)/9`, its bonus is charge through
ten seconds and charge squared thereafter. Before the release-timing multiplier,
10 seconds gives 2× strength, 19 seconds 5×, and 28 seconds 10×.
The curve is continuous at ten seconds; the previous logarithmic amp is replaced.
Longer durations remain available for amplification. Preview entry, exit and
mid-motion selection changes blend from the currently visible pose.
The rest of the spell controls are hidden during these first steps;
their existing implementation and saved drafts are retained. Demo preferences
are stored separately and do not alter spell properties or contributor history.
Animation favorites and sorting remain in Motion/Attack creation.

The previous self/barrier editor, effect illustration and live roaming prototype
are retired from the Spells workspace. Their old draft file is retained on disk.
The retained builder supports Projectiles, Buffs, Barriers, Debuffs, Summons and Teleports; only Projectiles has
content. Default Spell Cast is a new editable open-palm forward punch under
Attack/Punch, with hip/torso support and an open hand facing the shot direction.
The projectile pane chooses Element first, then Size (radius in meters). Fire
applies an HP burn, Ice slows and builds toward leg freezing, Lightning briefly
stuns, and Wind has high physical knockback. Visual colors/trails and hit statuses
use the selected element independently of the caster's original team. Size drives
both visual/collision radius and the visible mana cost `8 + 8 * radius²`, used by
actual AI casts too. Auto-preview now uses the arena's swept projectile collision
and impact/status pipeline against immortal passive partners, including real
knockback and knockdowns. Play Fight uses the same selected projectile spec for
the caster. Other spell categories are empty placeholders.

Starting distance (0.5–20 m) is saved with element/size in
`user://projectile_spell_draft.cfg`. Reset Field clears previous hits/effects and
restores an equilateral three-fighter layout with that pairwise distance; a live
readout shows caster/partner separation after knockback. The preview continues
unpaused after reset. The immortal fight HUD also has Reset Field and preserves
pause state when resetting. Normal Fight behavior remains unchanged.

Animation rows have star favorites. Favorites first, Name A–Z and Favorites only
sort/filter stock and saved animations together within every category, including
all Punch entries. The projectile picker shares these favorites and preferences.
They persist in `user://animation_favorites.cfg`; sorting does not restart the
currently previewed animation. Saved custom entries use their file identity.

The projectile pane hides redundant default/selected-animation headings and has
no Home or manual Preview button. Release controls come first; the animation
picker is the final section. Casts run automatically while Projectiles is open,
with a short idle interval between repeats. Switching category/workspace stops
the loop and clears its shots; returning to Projectiles resumes it automatically.

Play Fight · Immortal starts real three-way arena AI combat in the spell workspace.
The caster's projectile uses the chosen animation snapshot and release timing;
the other fighters use the existing arena spell kits. All fighters are immortal
only during this test: damage accounting, hits, guard reactions, status effects
and physical knockdowns remain active, while lethal branches are prevented and
health returns to maximum. Finite mana/stamina and ordinary regeneration remain.
The fight HUD offers Pause/Resume (Space) and Stop/Back to Editor (Escape), plus
hit/damage counters. Camera starts in arena-follow mode and can be manually
orbited/zoomed. Stopping or changing tabs clears practice flags/effects, restores
passive editor setup, and resumes the automatic projectile preview. Normal Fight
mode retains lethal damage; immortality is not saved in the spell draft.

Idle/ready transitions now hold an explicitly sampled posed baseline instead of
resetting the skeleton to T-rest while waiting for playback. Preview clip sampling
layers full-body guard and source tracks directly, including joints omitted by
a clip; editor playback uses the same baseline before mirroring/custom offsets.
This also avoids AnimationPlayer cache gaps after switching/replaying a source.
Repeated cast → idle, browser-ready transitions, custom editing round trips and
mirrored edited playback have been verified.

The remaining sections document earlier development milestones, including the
retired self/barrier prototype; they do not describe the current Spells menu.

## Combat foundation v1

Annotated Git tag: `milestone/combat-foundation-v1`

Commit: `98cc2fa90939343d4d2e34b99d9df7e99a6438d0`

The tag is pushed to origin. It preserves the game before the interactive combat
showcase: the wide colosseum, three-way Fire/Ice/Storm fight, charged spells and
Flash Step knee, Overdrive, leg freeze, impact-driven ragdolls and adaptive
resource recovery. The normal battle continues to be available alongside the
new showcase.

## Custom animation editor

Every Motion action has a custom editor: Idle, Run, Sprint, Jump, Land, Dash,
Crouch, backflip and twist. Block and Dodges now live under Attack, including
both blocks, each directional dodge and roll, with their custom editors and
previously saved animations available there. Users
can pose arms, legs, elbows, knees and torso across 2–32 frames (six by default). Jump previews
cover anticipation and airtime; Land has its own grounded recovery timeline.
Saved poses are JSON under `user://custom_animations/<name>.json`, with a `name`, a
`frame_count`, `duration` (seconds; three when omitted), and a `frames` array. Each frame maps bone names to three
rotation angles in degrees and stores each hand's thumb/index/middle/ring/pinky
curl as a percentage. Optional `pelvis_offset` stores local hip translation in
meters, and `foot_l` / `foot_r` store ankle orientation compensation for planted
feet. Older files default these fields to zero. Saved `category`, `step`, `clip` and `source_title` fields
preserve the source action, including variants within Dodges, Block and Acrobatics.
Older Jump/Idle/Land files remain readable. Idle stays grounded and loops a
standing pose. Saved animations include an Edit button and play their custom
poses during the matching action in arena previews.

New Custom actions start from the selected original animation, including its
normal action timing and composite Jump/Block stages. Native source playback
uses immediate sampling without crossfades. The frame controls display actual
source-pose angles, and an untouched save retains the original continuous tracks
exactly at any partition count. Land no longer adds a separate preset crouch.
A unique Copy name is prefilled so Save can be used immediately.

`source_timing: "native_v1"` and `source_duration` preserve that playback recipe.
`source_frames` stores sampled source angles and pelvis transforms; `frames`
continues to store editable changes layered over the complete source animation.
This avoids approximating a complete backflip with only six replacement poses.
Older files without the timing marker retain their previous timing and edits.

The Clone icon is available beside saved animations and next to Save inside the
editor. It starts an independent editing copy of the parent's complete frame
data, timing and source recipe, including current unsaved edits when used in the
editor. A unique Variant name is prefilled; Save writes a separate animation.
Variants can be used as parents for further variants. `based_on` records the
immediate parent's name/path for context; the copied animation does not depend
on that parent file remaining present.

Animation lists use one compact row per item: add-to-chain icon on the left,
preview name, then clone and delete icons on the right. Saved items have no
in-place Edit action; cloning opens a separately named working copy. Base
animations have disabled delete icons, and the deletion handler only accepts
saved JSON animations inside the custom animation directory. Both stock and
saved add buttons obey chain capacity and grounding availability. Icon actions
have tooltips, and full animation names remain available when labels are clipped.

Chain slots keep the exact selected animation as an independent profile snapshot,
alongside its canonical action type. Chips and playback status use the saved name.
Starting each step applies that slot's frame data; a default move explicitly clears
the previous custom pose. Hover previews have separate profiles and cannot replace
queued animations. Removal keeps profiles aligned with the remaining steps.
`user://animation_chain.cfg` persists the steps and complete typed pose snapshots,
so playback does not depend on the source JSON still existing. Custom landing
profiles activate at actual landing rather than interrupting the preceding air pose.

Deleting a saved animation archives its original JSON first under
`user://custom_animations/.trash`. The undo icon beside the category heading restores
the latest deletion, including after restarting. A name collision creates a Restored
copy instead of overwriting an existing animation. This recovery applies to deletions
made after the archive feature was added.
The editor includes open, fist, point, peace, middle,
shocker, pinky, and thumbs-up presets, with individual curl sliders. For example:

```json
{
  "version": 1,
  "name": "My Jump",
  "category": "Jump",
  "step": "Jump",
  "clip": "duel/air",
  "source_title": "Jump",
  "duration": 3.0,
  "frame_count": 2,
  "frames": [
    {
      "upperarm_l": [0, 0, -30],
      "spine_03": [12, 0, 0],
      "pelvis_offset": [0, 0, 0],
      "hands": {
        "l": {"thumb": 0, "index": 0, "middle": 100, "ring": 100, "pinky": 100},
        "r": {"thumb": 100, "index": 100, "middle": 100, "ring": 100, "pinky": 100}
      }
    },
    {
      "upperarm_l": [0, 0, 25],
      "spine_03": [-8, 0, 0],
      "hands": {
        "l": {"thumb": 0, "index": 0, "middle": 0, "ring": 0, "pinky": 0},
        "r": {"thumb": 0, "index": 0, "middle": 0, "ring": 0, "pinky": 0}
      }
    }
  ]
}
```

When the count changes, the editor resamples existing poses over the same
action span. Playback can loop the full animation, play a selected frame,
or loop/play a selected frame range. Hand pose controls are editable per side
and per frame, separately from whole-limb joint posing.

Limb sliders sweep through proposed rotations and stop at body intersections,
with an on-screen warning. Lightweight capsule proxies cover the torso, pelvis,
head, arms, hands, legs and feet; connected joints allow normal contact. Existing
contact in a source pose can move apart but cannot be pushed deeper. This is a
body-volume editing guard, rather than exact clothing or finger-mesh collision.

The editor separates Pose, Randomize, Playback and Record into tabs, with a compact
scrolling timeline and transport controls always visible. Pose controls are
grouped into Arms, Legs, Torso and Hands. Opening the editor frames the active
mannequin beside the controls once; the camera then remains user controlled.

Randomize Frame changes only checked parts in the highlighted pose;
Randomize All Frames changes checked parts across every pose. Selection can be
as specific as the right elbow or one finger, with All/None and body group presets.
Both use the same swept joint limits
and body-intersection guard as manual limb edits. Bulk generation shows progress
between frames, temporarily locks editing and preserves the playback position.
Restore Selected Parts restores checked controls from before the last randomization,
in the current frame or all affected frames, while keeping other changes. Undo Last
Randomize restores every remaining control from that operation. Restore also checks
for body intersections, and undo snapshots expire when the animation or frame count
changes so they cannot be applied to a different timeline.

Copy to Next Frame carries all limb offsets and hand/finger poses into the
following frame. Blend to Next (50%) mixes them halfway with that frame's existing
pose. Both pause playback and select the destination for repeated propagation or
editing, stop at the final frame, and reject an intersecting destination while
preserving its original pose. Copied hand dictionaries are independent.
The Copy / blend selector scopes both operations to All, Arms, Legs, Torso or
Hands. Torso includes spine/neck/pelvis rotation and hip translation; Legs includes
ankle rotation. Hands carries the finger gestures. Unselected groups retain their
destination data, and the same intersection guard checks the combined pose.
For native source animations, copying/blending converts through the sampled
source poses, so it carries the visible joint pose and hip position instead of
reapplying the same offset to a different underlying pose.

Direct posing uses projected rings for hands, elbows, knees, feet, chest and hips.
Dragging moves in a camera-facing plane; Shift-drag changes depth. Inverse
kinematics bends connected limbs using their actual rig lengths and rejects new
body intersections or excessive elbow/knee folding. Hip dragging anchors both
feet in position and orientation, and rejects moves that cannot keep them planted.
Undo Drag / Ctrl+Z steps through up to 100 previous drags across frames, returning
to the affected frame for each undo. The button shows the history count; unchanged
drags are skipped. Opening another animation, changing frame count, mirroring or
building a recorded take clears incompatible history. Cancel/Undo Take restores
the previous drag history. Text fields keep their normal text undo behavior.
Camera controls remain available.

Record Movement freezes the highlighted starting pose and samples the performed
motion at up to 30 Hz for at most 30 seconds. Stop & Build Frames resamples local
bone rotations with quaternion interpolation into the selected 2–32 frame count,
rebakes offsets against each destination frame's base clip, and includes starting
and finishing poses. Timing is saved with one frame of endpoint hold; repeat is
off after a take so the last pose is retained. Completed frames remain editable,
copyable and savable. Cancel Take and Undo Last Take restore the prior animation,
timing and randomization undo state. Runtime playback also applies recorded hip
translation and ankle compensation; rotation interpolation avoids angle wrapping.

Head posing has a forehead drag ring that rotates around the neck without moving
the head joint. The Head panel exposes pitch, turn and side tilt, constrained to
55, 75 and 35 degrees respectively, with the body intersection guard retained.
Head is a separate randomization and copy/blend group. Recording, saved variants
and chain snapshots carry its rotation offsets, and older frames default to zero
head offsets. This supports head poses for future scream-casting animations.

Offensive attacks now use the same custom editor as Motion: jab, cross, hook,
front kick, roundhouse, knee, elbow, uppercut and sweep have left/right library
entries with clone, direct posing, fingers/head, recording, selective randomize,
frame ranges, copy/blend, save and recoverable deletion. Elbow uses a bundled
procedural base clip. Selected source clip and striking bone travel with each
chain slot. Custom attack playback follows its saved timing, including the
uppercut playback and scaled contact windows. Uppercuts start immediately by
default (18 stamina), without the former 0.85-second charge hold. Their catalog
names and native editor recipes use this uncharged version; an explicit charged
actor call remains available separately.

Mirror L/R reflects the whole working animation, rebakes edited rotations over
the reflected source, swaps finger gestures and striking limbs, and preserves
the frame count and duration. Pressing it twice restores the posed keys. The
saved `mirrored` and `attack_bone` fields preserve side identity through cloning,
restart and chain snapshots; existing files default to their original side.

Hands now offer Original, Fist, Straight and Palm up radio choices separately
for each hand, plus Up/Down radio choices for each digit. New poses set fingers
relative to rest instead of adding more curl to the source animation. Straight
aligns the wrist to the forearm; Palm up rolls around that axis toward world up.
The hand data retains numeric curls for smooth interpolation and old files, with
`straight`, `palm_up`, `absolute` and optional `absolute_<finger>` weights. These
travel through save/load, copy/blend, mirroring, recording and runtime playback.

The old spell-effect test list is removed from the animation library; spell
throwing/slashing and effect test entries are no longer chain options. Loading older chains
skips those removed entries while retaining the matching profiles on remaining
steps. Fight-mode spell mechanics and their assets remain available separately.

Spells remains beside Motion and Attack as a separate creation workspace. Its
first branch chooses Self or Ground Barrier. Radius zero means self-only; positive
radii create a barrier at the caster's ground position. Enemy/ally recipient
selection and projectile eligibility logic have been removed from this workspace.
Mana updates live with the provisional visible scale `5 + 2 * radius² + 2 * seconds`;
size and duration are the only scaling axes. Settings persist in
`user://spell_draft.cfg`. Duration now has a slider plus numeric input. Effect
type follows duration with Buff, Heal, Shield and Absorb as the initial list;
Potency is the final setting, with a 1–100 slider and numeric input. Both new
fields persist with backward-compatible defaults. These remain draft settings,
with effect execution/delivery still separate. Mana continues to scale only with
size and duration. Camera placement stays fixed when parameters change.

Effect type now branches into concrete subtypes: speed (% faster), spell area
multiplier, maximum health (+HP), restored health, energy shield capacity, damage
absorption and mana absorption. Potency uses the subtype's units/range, including
500 extra HP and 5× spell area. Choosing a subtype immediately displays an applied
state illustration on the selected mannequin: speed streaks, expanding aura,
health crosses, shield shell or inward absorption particles, plus numeric context.
These previews do not alter fight resources. The preview camera frames the subject
when choosing the workspace/target; changing parameters preserves camera placement.

Casting animation is the final setting after Potency. A searchable Attack library
includes stock moves and saved custom variants; the draft keeps a full chosen
snapshot. Preview samples source tracks, mirrored side, custom poses and gestures
without melee contact, then returns to idle. Casting is currently self/barrier only;
still and relaxed poses are allowed. No enemy targeting, projectile eligibility,
release-limb analysis or projectile delivery is retained in the spell builder.

Four additional whole-body Attack sources have left/right variants: Sky Palm
(open palm faces up, arm rises above the head and gaze tracks upward), Ground
Stomp (weight shift, knee lift, downstroke and compressed landing), Ground Punch
(chamber, hip drop, torso fold, closed fist reaching the floor), and Body Slash
(hip/spine coil, sweeping open hand, opposite-arm balance and follow-through).
Sky Palm and Ground Punch appear under Punch, Stomp under Kick, and Body Slash
under Slash. All use the same clone/edit, mirror, save, chain and casting-picker
paths. Procedural clips bake support-foot IK at 30 Hz; the stomp foot is clamped
against floor penetration. Native timing includes anticipation and recovery.

The battle actor registers only its two referenced auxiliary UAL2 clips
(Idle_Shield_Break and LayToIdle), preserving the complete source asset on disk.
This keeps the runtime animation cache lean and resolves the startup failure
observed when registering the expanded attack bundle alongside all unused clips.

Nonzero spell radius now previews a spherical barrier centered at the subject's
ground position, with the above-ground dome and a matching perimeter ring. Absorb
effects use this radius for their barrier and incoming particles instead of a
fixed personal aura. The UI distinguishes radius and full width (diameter).
Zero radius retains the personal effect. Shell, boundary and effect particles
form outward with a 0.65-second eased expansion/fade rather than appearing at size.

Spell initialization follows the casting picker. Its saved `release_fraction`
slider is constrained to 25–100% of the selected animation; the opening quarter
is blocked. Readout includes seconds and full animation length. Dragging inspects
the corresponding pose. Preview Timed Cast hides all effect meshes and the ground
boundary until that point, then starts formation, including a release exactly at
100%. Replaying clears prior formation. This remains the spell creation preview;
the barrier is not a new fight-mode collision/absorption implementation.

Create practice now keeps three passive mannequins visible: Caster (blue label),
Ally (green) and Enemy (red), with their existing live HP readouts. The previously
hidden third fighter is placed beside the practice lane after every setup/reset.
Its hitboxes are disabled so an ally cannot receive incidental chain strikes.
Roles are practice metadata rather than changes to the fight-mode team indices.
Ally and Enemy remain practice NPCs, not spell recipients. Old recipient/validation
fields are ignored on load and dropped when the self/barrier draft is saved.
Spell workspace framing includes all three without moving the camera when size,
potency or timing changes. Fight mode retains its existing combat behavior.


Spell preview ownership and live practice:
- `editor_pose_locked` prevents the combat tick from advancing rigs owned by the
  custom/spell preview or live controller. Transitions stop playback, clear stale
  custom profiles, reset skeleton/model/twist state, and synchronize `clip` with
  the animation player. Switching Slash → custom edit → Spells → Slash no longer
  needs a second selection to restore the pose.
- Every nonzero-radius visual motif lies on the barrier skin, including health
  crosses, speed streaks and absorption particles. Personal effects are limited
  to radius zero. Ground barriers capture their world origin on release and stay
  there when the caster runs away; the perimeter uses that same origin.
- Run Around & Test Spell opens a live HUD. WASD moves relative to the camera,
  Shift sprints, Space casts the current draft, middle mouse orbits, and the wheel
  zooms. The camera follows without changing the user's zoom/orbit. Casting plants
  the feet until the chosen animation completes; movement resumes afterward.
- Ally/Enemy roam without combat AI, with a toggle to stop them. Locomotion uses
  the normal run/idle clips, acceleration, gravity, world collisions and arena
  bounds. Escape / Back to Spell Editor returns to editing. Live effects expire
  after duration (at least their formation time); radius-zero speed buffs adjust
  practice movement speed. Other effect types remain visual previews, not full
  combat-effect implementations. Existing Fight mode is unchanged.


### Water, breakable ice, and return-hit regression
- Return, swim, stun and ice-trap movement now expire temporary hit immunity.
- Electrified water retains its blue material and displays animated yellow 3D sparks.
- Water freezes into persistent full-depth collision tiles; submerged fighters are trapped. Tiles crack and shatter under projectile, melee and body-impact damage. Raised ice supports standing and ragdoll recovery.
- Jump actions become upward swim strokes in water, with autonomous surfacing. Eight seconds of air precede lethal drowning damage, including in immortal spell practice. Reset Field restores fighters and clears ice.
- Verified repeated actual projectile hits after return, physical standing on raised ice, actual projectile destruction, swim action, trapping, drowning, reset, and rendered sparks/cracks.


### Local water and Earth debris
- Water hits use the victim's actual feet position. Separate impact puddles grow locally, merge on contact, conserve volume, and can still flood the arena. Removed starter puddles and scattered debris.
- Earth is a selectable projectile element that raises a physical wall at impact. Size controls dimensions and potency controls wall durability. Projectile, melee and body impacts damage walls; destruction produces twelve physical chunks, capped at 96 active debris bodies. Wind throws the chunks.
- Verified actual Water/Earth casts, remote target placement, puddle merging and flooding, local ice, physical wall destruction by a real projectile, wind impulses on resulting debris, full reset, and earlier drowning/freeze/repeated-hit behavior. Rendered the scene and checked startup.


### Limb-aware ice and element reactions
- Leg casings immobilize legs while allowing casts from free arms or mouth. Solid ice checks the actual enclosed bones. Casting checks required limb chains at start and release, and frozen bone poses remain fixed while free bones animate.
- Fire evaporates liquid volume with steam, melts solid ice back to its already-conserved water, and thaws leg casings into local water. Water extinguishes ground fire. Wind amplifies fire projectiles and burning patches once per source; fire leaves short-lived damaging ground on dry earth.
- Every element button has a concise hover tooltip covering all five other elements; neutral pairings are explicit.
- Verified a real arm cast during leg freeze with anchored position and fixed calf pose, leg/mouth permissions, whole-body ice restrictions, melting/release/water, evaporation/steam, wind amplification, all tooltip pairings, and electrified-water stun regressions.


### Larger radii and Earth Wall summons
- Expanded size from 3m to 30m radius, including direct numeric entry, persistence, actual projectile collision size and scaled mana cost.
- Summons now contains Earth Wall with a deliberate Cast Earth Wall action. The wall appears directly between caster and target, with shared size/potency controls and its existing durability/debris physics. Live fight casts use the same summon specification and consume mana.
- Earth projectile remains a rock; impacts no longer raise walls. Summons do not auto-loop and pile up walls. Older Earth-only drafts without a category migrate to Summons.
- Verified real 30m projectile creation, mana/ranges, no projectile-wall creation, direct summons without flying shots, precise placement, manual preview, live summon cost, debris/reset, and category/large-size persistence.


### Compact coupled spell controls and percentage mana
- Radius and potency now use aligned horizontal label/slider/numeric rows. They share a 100% power cap; increasing either past the remaining capacity automatically reduces the other. Radius uses a logarithmic allocation across 0.1-30m, potency uses a linear 0.25-4x allocation. Saved builds above the cap are normalized while preserving radius.
- Spell mana costs are percentages of maximum mana (5-100% based on allocated power), and live casting converts that percentage to the actual pool. Summons and projectile previews use the same displayed calculation.
- Starting distance and Reset Field moved to Arena Settings. Opening arena settings preserves the previously selected projectile/summon for live fights.
- Verified both coupling directions over forty radius/potency combinations, horizontal control layout, percentage/capacity calculations and live spend, settings visibility/spacing reset, persistence and rendered layout.


### Normal radius cap and custom spell appearance
- Normal spell radius now caps at 2m, including the shared power budget. Larger radii up to 30m require an explicit Arena Settings testing toggle and carry TESTING ONLY UI/spec markers. The normal projectile factory also clamps oversized inputs; testing use must opt in explicitly.
- Added per-element appearance settings: six visible forms plus element defaults, primary/highlight colour pickers, five trail styles, orbit rings, glow, opacity, trail length, pulse and swirl. Animated procedural surfaces differ by element and work with the Compatibility renderer. Appearance settings persist and can reset independently per element.
- Actual projectile rendering reads the saved appearance, aligns directional shapes to flight and updates visual motion. Collision radius, elemental status effects and casting animation remain separate.
- Verified 2m normal/30m opt-in boundaries, actual test-size shots, material uniforms and shape propagation, unchanged collision radius, independent element settings, persistence/reset, and all 42 element/shape combinations; rendered a visual gallery.


### Drawn silhouettes, drawn trails, texture library, and ground fire
- Draw Shape opens a mouse-drawing canvas, validates a non-crossing closed outline and extrudes its triangulated silhouette into a shallow 3D spell visual. Draw Trail turns an open stroke into a cached antialiased trail stamp used by live projectiles. Collision still uses the configured radius.
- Exposed all eighty transparent Kenney Particle Pack 1.1 textures (CC0, existing upstream license retained), with thumbnail pickers for body/trail masks. Added Fireball, Torch Flame, Embers and Cold Fire visual presets. Import PNG copies selected textures into the game's user library for runtime use, persistence and later selection.
- Default fire uses animated alpha-masked flame cards; burning ground uses a soft textured scorch mark plus bounded animated flame layers rather than a solid dark disc. Burn, wind amplification, extinguishing and expiry mechanics remain intact.
- Verified drawing UI input/validation, actual extruded projectile mesh and collision radius, live drawn trails, all texture resources, presets, textured burning-ground mechanics, and saved drawings/settings. Rendered the fire result for visual review.


### Projectile velocity consumes shared output
- Added a horizontal Velocity control (1-50 m/s, default 14 m/s). Radius, potency and velocity now share the same 100% cap. Increasing one beyond remaining output reduces the other two proportionally in allocation space.
- Velocity contributes to displayed percentage mana and is saved in projectile drafts/specs. Actual flight and impact momentum use the chosen speed. Slow shots get a distance-based lifetime so they can reach the target.
- Instant Earth Wall summons hide/exclude velocity from their budget and cost.
- Verified all three cap extremes, sixty-four stat combinations, actual travel at 1 and 50 m/s, slow-shot lifetime, percentage costs, summon exclusion and persistence.


### Animation aim and tutorial flow
- Cursor aiming is shared across equipped spell animations. The player’s torso/hip pose eases toward the cursor or focused target while the authored limb animation stays neutral; the projectile uses that same aim direction. Aim is constrained to the forward hemisphere, and the pose eases back after the action. This gives punch-linked spells and other limb-bound spells one consistent direction system.
- New characters skip the separate calibration stop and enter the tutorial: land five left jabs without focus, then select and focus the dummy and land five more. Held WASD moves the character; left mouse is the tutorial’s only attack input. Completing the lesson starts the first fight directly.
- Verified scene startup in headless mode and visually checked the live tutorial. No script or engine errors appeared; the log showed a short startup frame spike, then about 59 FPS with roughly 2.2 ms physics processing.

### Creation animation structure — milestone accepted (2026-10-29)
- User marked the creation screen's animation structure as basically complete. Treat the current structure as the established baseline; preserve working features and make targeted refinements rather than replacing the workflow.
- The baseline includes Motion/Attack categories, custom folders, a searchable Store with remembered filters, previews, blocking, duplicate-name suffixes, renaming, moving imported animations between categories, and deletion of Store imports while protecting original starter animations. Source metadata and contributor history remain attached.
- The Store stays open across workspace menu switches until its Close button is used or the creation screen is left.
- Unit selection, layered body-part timelines, moving/stretching/trimming/splitting clips, undo/copy/paste, stamina/damage/mana controls, and the detailed pose/frame/version editor form the current animation workflow. The detailed editor now introduces the basic steps and keeps technical transition tools under Advanced.
- This milestone records user acceptance of the animation structure, not a claim that every animation asset or future gameplay integration is finished.

### Third milestone — animation Store previews and downloads accepted (2026-10-30)
- User explicitly accepted this as the third milestone.
- Paginated Store rows load their complete source records. Play previews the selected clip on the focused bot, finishes once, and leaves the timeline unchanged. Download creates a loadable project asset in the Downloaded folder.
- Verified all 26,052 active community source records for complete indexed metadata. Exercised the actual Store buttons for Female1 D6 CartWheel, Female1 B09 WalkTurnLeft90, and an InterHuman NPY clip; measured movement on the visible bot and confirmed each preview completes. CartWheel was saved and reloaded as a project asset.
- Structured logs record the selected asset, page detail reads, import stages, project saves, preview completion, and measured bot movement. The rendered Store workflow regression covers the complete path from paginated rows to button actions.
- Preserve this working Store workflow as the accepted baseline. Metadata completeness does not imply that every source clip has received individual visual review.

### Accepted projectile aiming checkpoint (2026-10-30)
- User tested and accepted the revised free-aim convergence and requested saving this version.
- Preserve the mouse-following crosshair and arbitrary camera distance/orbit. Nearby fighter hurt bounds choose convergence depth on the cursor ray, avoiding far-wall convergence that could turn an above-head aim into a near-body hit.
- The amber predicted-impact overlay was rejected and removed. Physical prediction remains a read-only diagnostic API.
- Regression checks reproduced the old false hit, verified above-head misses and chest hits at three camera angles/distances, and passed third-person focus and spell casting/hitbox controls.
- This checkpoint also preserves the current shared character mechanics and spell creation workspace. The downloaded community animation archive remains local; attached project animation copies are included.
