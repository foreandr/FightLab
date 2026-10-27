# FightLab

Infrastructure for a future 3D fighting game. Currently an empty Node3D scene with no gameplay.
Requires Git, PowerShell, and **Godot 4.6 stable**, standard GDScript edition. Uses Compatibility (OpenGL) for Windows 11 and AMD integrated graphics.

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

Press F5 in Godot to run the empty main scene. An empty window is expected.
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
