# FightLab

An automatic two-NPC skeletal striking demonstration for **Godot 4.6 stable**.
Uses the Compatibility renderer for Windows 11 / AMD integrated graphics.

## Launch

Double-click **Play.bat** in `C:\Users\forea\FightLab`. It updates a clean checkout
and launches the demo. Both fighters approach and fight without input.

To launch your current local files without pulling from GitHub, run:

```powershell
Set-Location C:\Users\forea\FightLab
.\run.ps1
```

R restarts; Space toggles slow motion; Esc exits. `run.ps1 -Editor` opens Godot.
If Godot is missing, the launcher installs the pinned free portable 4.6 release.
`-GodotPath 'C:\path\to\Godot.exe'` or `GODOT_PATH` overrides discovery.
All required character and animation assets are in Git. No asset download or
external project checkout is needed. See [asset notices](assets/combat/NOTICE.md).

## What is implemented

- Two distinct, clothed, anatomically proportioned humanoids on the same 65-bone rig.
- Reused skeletal guard, guarded walk, jab, cross, front kick, high kick, hit,
  knockdown and stand-up clips. Both hands punch, both hands hook, and both legs
  front-kick and high-kick. Each NPC uses all four limbs in autonomous exchanges.
- Refined kicks reuse upstream's choreography and skeletal IK helpers: slower
  chamber/recoil, weight shift, ball-of-foot contact, and high kicks that rise
  outside the torso before sweeping at head height. Dense baked poses keep the
  support ball of the foot planted through the pivot.
- AnimationPlayer cross-fades between movement, strikes and recovery.
- Godot CharacterBody3D floor and fighter collision, and bone-following head/torso
  Area3D hurtboxes. A fist/foot-sized sphere sweeps the actual animated limb path.
  Only an outbound collision during the strike window can score; distance alone
  cannot cause a hit. Each swing can connect once.
- Contact direction and measured limb speed drive collision-resolved knockback.
  Accumulated hits trigger a skeletal fall and timed recovery. NPCs wait for a
  downed opponent, then resume; there are no periodic teleporting round resets.
- Readable inspection camera, contact counters and optional frame capture.

## Current limits

This is a visually inspectable sparring prototype, not UFC-level realism.
The characters remain stylized. Quaternius clips are authored animation; no claim
of motion capture is made. Knockdowns/get-ups are animation-driven, not an active
ragdoll or physically simulated balance. Hit reactions use a small set of clips
with directional body knockback. Blocking, per-limb rigid-body reactions, precise
foot locking during all blends and richer reactive tactics remain future work.
The original melee hook lunged too low; the adapted hook uses shorter range.

## Validation and capture

```powershell
.\validate.ps1
```

This fails on Godot errors and tests 180 simulated seconds of autonomous fighting,
all eight strike types, both NPCs landing with each hand/foot, separation and knockdowns.
It samples all four kicks on both rigs to bound support-foot drift, and runs an
isolated contact review requiring front kicks to hit the body and high kicks the
head, once each. It also
disables hurtboxes at close range and tests every strike at long range: neither
case may register a hit. Headless tests validate behavior; rendered inspection is
also required for motion quality.

For a rendered 35-second sample with PNG frames, impact frames and a JSON report:

```powershell
.\tools\Godot_v4.6-stable_win64_console.exe --path . --resolution 1280x800 -- --duration=35 --capture-dir=C:/path/to/captures
```

For repeatable video debugging (Godot records AVI directly, with no extra tools):

```powershell
.\scripts\core\review-video.ps1 -IsolateKicks
.\scripts\core\review-video.ps1 -Seconds 40
```

Each run saves a 30 FPS movie and `contacts.json` under `builds/review-*`.
The isolated review shows both legs on both characters against a passive opponent;
normal gameplay remains autonomous. Compare consecutive video frames around the
contact timestamps: guard → weight shift → chamber → impact → recoil → guard.

The JSON report includes contact timestamps, attempted/landed strikes per limb,
actual renderer, FPS, contacts by move and minimum fighter spacing. Capture overhead affects performance. See [validation notes](docs/validation.md)
for the latest observed results and remaining visual limitations.

## Reused systems and reproducibility

Characters, hair and UAL animation libraries: **Quaternius, CC0**. Guarded locomotion,
kicks and clothing: **Clint Christopher Canada / 3D Fighter, CC BY 4.0**.
Hook-baking helpers: upstream **MIT** code, adapted in `scripts/vendor/`.
Pinned upstream revision and full notices are in `assets/combat/NOTICE.md`.
The upstream arcade combat rules were not used: this demo's hits depend on Godot
physics contact with animated limbs. No proprietary game assets are included.

`PlayExisting.bat` remains an optional, independent arcade game launcher; it is
not required for this demonstration.
