# Create: Animations and Spells

Double-click `Play.bat` to open Home. Choose **Create → Animations** for the
motion editor or **Create → Spells** for focused spell tests. Story currently
has a placeholder page; Fight opens the autonomous arena. Sandbox.bat and
Showcase.bat are legacy shortcuts to Home. `run.ps1 -Sandbox` and F2 in Fight
still open Animations directly; `run.ps1 -Spells` opens Spells.

## Animation chains

Animations is the former combat sandbox. It starts with one blank (End) slot,
ready for your own sequence. There are no preset buttons. Ordered dropdowns
let you chain **Dash**, **Punch**, **Knee**, **Jump**, **Flip**, **Twist** and
**Land**; **End** terminates the chain. The live result line
shows the active step, completion, or interruption. Hits, death, freeze and
insufficient resources stop a sequence rather than skipping its requirements.

**+** appends an animation; **−** removes the last one. Existing steps are kept.
The editor supports 1–32 slots and scrolls horizontally for long sequences.
An appended step starts with a valid ground/air choice that you can change.
Adding after End replaces the unused trailing slots with a usable next step.
Editing resets playback to Ready. Minus is disabled when one slot remains.

Choices depend on the planned state at each slot. Grounded slots offer Dash,
Punch, Knee and Jump. **Jump unlocks Flip, Twist and Land** in the following slot;
**Land restores grounded choices** after it. Unavailable entries are disabled
with a reason. Changing an earlier step clears incompatible later choices.
For an aerial sequence, select Jump, add Flip, add Twist, then add Land.
Jump hands off after actual lift-off when followed by an aerial step;
Land waits for floor contact and the landing recovery. A Jump with no aerial
follow-up retains its original jump-and-land behavior.

Playback checks actual grounding independently of menu predictions. Flip uses
the existing tucked backflip clip at a short aerial cadence; Twist rotates the
pelvis and its child bones through a full turn over the airborne pose. Both cost
stamina, preserve horizontal momentum and keep normal gravity. They do not
relaunch the fighter or hold them in the air. A late trick can land early; the
next aerial move then stops with a condition message. Runtime state is displayed
as Grounded/Airborne alongside the active step.

Dash direction has eight options relative to the fighter's facing. The dash
moves at 12 m/s for 0.30 seconds and travels up to 3.6 metres. It respects body
and wall collisions and stops short of the partner when heading toward them.
Direction is fixed when the dash begins.
Backward and sideways dashes retain facing during the dash. Dash spends stamina,
uses no mana, and does no contact damage by itself.

Start around **4.4 m** apart for a forward dash into knee. The knee uses real
animated-limb collision and retained dash momentum. A farther target can be missed. A plain Jump step jumps
without automatically casting. Reset clears the sequence, while Repeat replays
the same ordered setup. Spell chain steps remain for a later pass; individual
spell tests are still in the Move menu.

## Individual move testing

1. Choose a move from the menu. All six current spells are included: Fireball,
   Cinder Slash, Freezing Ray, Glacial Armor, Overdrive and Flash Step. The menu
   also includes physical strikes, shields, movement, defensive impact tests,
   powered combinations and lethal attacks (31 individual tests plus the combo builder).
2. Enter a distance from 0.5 to 26 metres. This is the horizontal distance between
   fighter centers at spawn, not the gap between their bodies. The scene resets
   immediately to preview the new spacing.
3. Set caster jump, partner jump, no block/palm shield/brace shield, charged cast
   and weakened guard as needed. Unsupported options are disabled. Held charge
   applies to grounded Fireball, Cinder Slash and Freezing Ray; jump casts use
   the actual quick airborne release. Flash Step and uppercut have their built-in
   charge. Jumping is available for spell, melee, uppercut and shield actions.
4. Click **Run / Replay** or press R. The actual combat action plays once, with
   physical reactions and live damage/block/guard-break counters.
5. Click **Reset** or press X to restore both fighters and wait again. Settings
   remain selected. Enable **Repeat setup** to replay the same configuration
   every nine simulated seconds. Reset stops playback even when Repeat is on.

Each test begins with full health/resources and clean status/physics, except
explicit plain melee tests (no elemental mana), lethal tests (one target HP),
and weakened guard. Only the two test fighters are active. The partner has no AI;
it reacts to hits and follows only the chosen jump/block or defensive-impact
scenario. A jumping partner can also hold a shield. Far-away punches can miss:
the sandbox preserves real reach and collision checks. Suggested melee distance
appears below the menu.

WASD moves the camera relative to its viewing direction; Q/E lowers/raises it.
Hold middle mouse and drag to orbit, and scroll the wheel to zoom. Shift speeds
up camera movement. These controls work while ready, paused or in slow motion.
The camera retains your view across Run/Reset; **Reframe / F** restores automatic
framing of both fighters. Mouse controls apply over the arena; typing in the
distance field or scrolling a menu does not move the camera.

Space pauses/resumes; T toggles 0.35× speed; M mutes; B returns to battle. The
Home button returns to the main menu; Esc does the same. The old guided cycle
is available through `run.ps1 -Tour`, with an Animations button to return.
Existing saved sparring/duel scenes and the milestone tag are preserved.

`validate.ps1` includes menu coverage, exact spacing, actual charge damage,
projectile blocking and guard break, caster/partner jumps, airborne blocking,
pause/reset and same-setup repeat tests. Record a representative menu review with
`.\scripts\core\review-video.ps1 -SandboxShowcase`.
Use `-MotionShowcase` instead to record forward dash, dash-knee, backward dash, sideways dash and an aerial chain. Motion regression checks cover all eight
dash directions, real contacts, shield blocks, misses, ordered
four-step playback, jump, reset and interruption.
