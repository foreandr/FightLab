# FightLab

Infrastructure for a future 3D fighting game. First playable physics combat sandbox: WASD movement, SPACE punch, R to reset the physics opponent. Character meshes and punch pose are temporary placeholders; the physics knockback is real.
Requires Git, PowerShell, and **Godot 4.6 stable**, standard GDScript edition. Uses Compatibility (OpenGL) for Windows 11 and AMD integrated graphics.

To play and test on Windows, double-click **Play.bat**. It pulls the latest main branch, then launches the game directly. Close the game when finished. If updating fails, it stops and keeps the error visible. Local edits are never discarded. The current scene has two temporary fighters in a simple arena.

Clone and begin a session in PowerShell:

```powershell
git clone https://github.com/foreandr/FightLab.git
Set-Location FightLab
# Set this only when Godot is not found automatically:
$env:GODOT_PATH = 'C:\path\to\Godot_v4.6-stable_win64_console.exe'
.\setup.ps1
.\sync.ps1
.\run.ps1 -Editor
```

Press F5 in Godot to play: WASD to move, SPACE to punch, R to reset the opponent. Face the opponent and get within reach before punching.
Launch directly with `.\run.ps1`. All Godot scripts also accept `-GodotPath 'C:\path\to\godot.exe'`.
Download the pinned release from https://godotengine.org/download/archive/4.6-stable/.
Godot is discovered through the override, GODOT_PATH, PATH, local tools, common Godot/WinGet folders, or Downloads.

Each development session:

```powershell
Set-Location 'C:\path\to\FightLab'
.\sync.ps1
.\run.ps1 -Editor
# Edit, run with F5, and validate before reviewing and committing:
.\validate.ps1
git diff
git status
git add <reviewed-files>
git commit -m "Describe the change"
git push origin main
```

`sync.ps1` requires a clean main branch and uses a fast-forward-only pull. It never resets, stashes, commits, or pushes automatically. Commit or stash local edits yourself before pulling. Diverged history requires manual resolution.

Validation imports in headless editor mode, then starts the main scene for 60 frames. Any nonzero exit or Godot error fails validation. GitHub Actions repeats these checks for pushes and pull requests using the same pinned release.

Keep required assets in Git; generated `.godot/` caches and local tools are ignored. Follow AGENTS.md and wait for explicit instructions before adding gameplay.

## Animation and asset direction

Build the finished game as a composition of properly licensed third-party components, not bespoke effects for their own sake. Initial candidates: [GDQuest Godot 4 third-person controller](https://github.com/gdquest-demos/godot-4-3d-third-person-controller) (MIT code, CC BY 4.0 assets); [Quaternius Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html) (CC0 animation clips); and [Godot Real Controller](https://store.godotengine.org/asset/furkan-demir/real-controller/) (MIT Godot 4.6 controller). These are **candidates, not yet imported**. Preserve their notices when integrating. The first sandbox intentionally uses only built-in Godot physics and placeholder meshes so Play.bat remains self-contained. Do not copy assets or decompiled code from proprietary games.

## Optional licensed character integration (experimental)

`Play.bat` now attempts to download two CC0 rigged GLB characters from the public [Gobkit free-assets manifest](https://gobkit.com/api/free), installs them into ignored `assets/gobkit/`, and runs Godot's asset importer. Offline or failed downloads leave the built-in primitive demo playable. These are stylized animated humanoids, **not UFC-realistic characters**. The baked imported animation is only an initial visual test; the procedural strike and physical impulse are not yet driven by the skeleton. Realistic boxing motion, root motion, limb hitboxes and ragdoll contact remain future work. License: CC0 1.0; asset creator Gobkit, https://gobkit.com .
