# Combat testing sandbox

Double-click `Sandbox.bat` or `Showcase.bat`, run `.\run.ps1 -Sandbox`, or press
F2 in the normal battle. It starts ready and waits for you to run a test.

1. Choose a move from the menu. All six current spells are included: Fireball,
   Cinder Slash, Freezing Ray, Glacial Armor, Overdrive and Flash Step. The menu
   also includes physical strikes, shields, movement, defensive impact tests,
   powered combinations and lethal attacks (31 choices total).
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

Space pauses/resumes; S toggles 0.35× speed; M mutes; B returns to battle. The
54-case tour button retains the guided cycle, with a Sandbox button to return.
Existing saved sparring/duel scenes and the milestone tag are preserved.

`validate.ps1` includes menu coverage, exact spacing, actual charge damage,
projectile blocking and guard break, caster/partner jumps, airborne blocking,
pause/reset and same-setup repeat tests. Record a representative menu review with
`.\scripts\core\review-video.ps1 -SandboxShowcase`.
