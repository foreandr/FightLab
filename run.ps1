param([string]$GodotPath, [switch]$Editor)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/core/godot.ps1"
$portableExe = Join-Path $PSScriptRoot 'tools/Godot_v4.6-stable_win64.exe'

# Prefer an existing verified portable installation. Do not download it again.
if (-not $GodotPath -and -not $env:GODOT_PATH -and (Test-Path -LiteralPath $portableExe)) {
    $executable = (Resolve-Path -LiteralPath $portableExe).Path
} else {
    try {
        $executable = Find-Godot $GodotPath
    } catch {
        if ($GodotPath -or $env:GODOT_PATH) { throw }
        Write-Host 'Godot not found. Installing portable Godot automatically...'
        $installed = & "$PSScriptRoot/scripts/core/install-godot.ps1"
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Godot installer failed.' }
        $executable = (Resolve-Path -LiteralPath $portableExe -ErrorAction Stop).Path
    }
}

if (-not (Test-Path -LiteralPath $executable)) { throw "Godot executable not found: $executable" }
Write-Host "Launching Godot: $executable"
# Acquire free CC0 assets when available; never block offline play.
$assetOne = Join-Path $PSScriptRoot 'assets/gobkit/fighter1.glb'
$assetTwo = Join-Path $PSScriptRoot 'assets/gobkit/fighter2.glb'
if (-not (Test-Path $assetOne) -or -not (Test-Path $assetTwo)) {
    try {
        & "$PSScriptRoot/scripts/core/fetch-characters.ps1"
    } catch {
        Write-Warning "Optional character download failed: $_. Running fallback demo."
    }
}
if ((Test-Path $assetOne) -and (Test-Path $assetTwo)) {
    $importMarker = Join-Path $PSScriptRoot '.godot/fightlab-character-import-ok'
    if (-not (Test-Path -LiteralPath $importMarker)) {
        Write-Host 'Importing characters (bounded headless import)...'
        & $executable --headless --editor --path $PSScriptRoot --import --quit-after 180
        if ($LASTEXITCODE -eq 0) {
            New-Item -ItemType File -Path $importMarker -Force | Out-Null
        } else {
            Write-Warning 'Godot import did not finish successfully; launching anyway.'
        }
    }
}
# Prefer rigged human character models over the temporary Gobkit monsters.
$humanFile = Join-Path $PSScriptRoot 'assets/humanoid/night-striker.glb'
if (-not (Test-Path -LiteralPath $humanFile)) {
    try {
        & "$PSScriptRoot/scripts/core/fetch-humanoid.ps1"
    } catch {
        Write-Warning "Optional humanoid download unavailable: $_"
    }
}
if (Test-Path -LiteralPath $humanFile) {
    # One bounded import for the new asset. Do not repeatedly hold launch in editor mode.
    $humanMarker = Join-Path $PSScriptRoot '.godot/fightlab-humanoid-import-ok'
    if (-not (Test-Path -LiteralPath $humanMarker)) {
        & $executable --headless --editor --path $PSScriptRoot --import --quit-after 120
        if ($LASTEXITCODE -eq 0) {
            New-Item -ItemType File -Path $humanMarker -Force | Out-Null
        } else {
            Write-Warning 'Humanoid import failed; previous visuals will be used.'
        }
    }
}
$arguments = @('--path', $PSScriptRoot)
if ($Editor) { $arguments += '--editor' }
& $executable @arguments
if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
