# Interactive combat showcase

Double-click `Showcase.bat`, run `.\run.ps1 -Showcase`, or press F2 in the normal
battle. B returns to the autonomous three-way battle.

The showcase automatically cycles through 54 named cases. One fighter performs
the move while a second waits and reacts to real hits. The partner only blocks
or attacks when the selected case calls for it. The third fighter is hidden and
has its collision and hurtboxes disabled. Each case resets resources, poses,
statuses, effects and physics so previous tests cannot contaminate the next one.

## Coverage

- Fireball, Cinder Slash and Freezing Ray: ground, jump, charged, palm shield,
  braced shield and charged guard-break variants.
- Glacial Armor: ground, jump, incoming Fireball and incoming punch.
- Overdrive: ground, jump and sprint. Flash Step knee: ground, jump, shield
  impact and a follow-up after Overdrive.
- Left jab, right cross, left hook, front kick, round kick and knee. Separate
  shield tests for jab, front kick and knee, plus elemental Fire kick/Ice knee.
- Charged uppercut and charged uppercut against weakened guard. Lethal Fireball
  and lethal jab demonstrate physical death reactions.
- Palm and braced shields, including raise, hold and lower.
- Run, approach, retreat while facing the partner, both strafes, backward dodge,
  backward roll and backflip.

The visible title names the move and variant. The next line explains what to
watch. Health, mana, stamina and guard appear above the scene; the bottom line
reports observed contacts, blocks, guard breaks and active defenses. A passive
target can be knocked away, launched or killed; it is reset for the next case.

## Controls

| Control | Action |
| --- | --- |
| Left / Right (or P / N) | Previous / next case |
| R | Replay current case |
| Space | Pause / resume |
| S | Toggle 0.35× slow motion |
| A | Toggle automatic advance |
| B | Return to battle |
| M | Mute / unmute |
| Esc | Exit |

On-screen buttons cover navigation, replay, pause, slow motion, automatic advance
and return to battle. Disable Auto to hold a case after it finishes, then replay
as needed. Manual navigation resumes a paused case; the slow-motion setting stays.

## Validation and recording

`validate.ps1` includes `tests/combat_showcase_test.gd`, which runs all 54 cases
and checks required real contacts, blocks, guard breaks, defenses, movement,
airborne height and deaths. It also checks titles, the two visible fighters,
passive AI, navigation, pause and slow motion. Existing combat and saved-scene
regressions remain in the validation suite.

Resetting an interrupted ragdoll/get-up now clears skeleton offsets before idle
plays. A recovery regression checks that non-pelvis bone positions return to
their rest offsets. This also prevents stale poses on ordinary round resets.

```powershell
.\scripts\core\review-video.ps1 -CombatShowcase
```

This records a ten-case representative subset with native stereo audio, a
contact timeline and `showcase-cases.json`. The interactive showcase includes all
54 cases. Pass `--showcase-report=<absolute path>` after Godot's `--` separator
to save case observations from an interactive session. This is an animation and
mechanics review tool; it does not replace balance testing in the normal battle.
