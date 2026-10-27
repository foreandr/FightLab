$ErrorActionPreference = 'Stop'
$source = 'https://github.com/clintcan/3d-fighter.git'
$root = $PSScriptRoot
$game = Join-Path $root 'external/3d-fighter'
$parent = Split-Path $game
New-Item -ItemType Directory -Path $parent -Force | Out-Null

if (-not (Test-Path (Join-Path $game '.git'))) {
    if (Test-Path $game) { throw "A directory exists at $game but is not the expected Git checkout. Nothing was overwritten." }
    Write-Host 'Downloading the open-source 3D Fighter game...'
    & git clone --depth 1 $source $game
    if ($LASTEXITCODE -ne 0) { throw 'Could not clone upstream 3D Fighter.' }
} else {
    Write-Host 'Using existing downloaded 3D Fighter game.'
}
$project = Join-Path $game 'project.godot'
if (-not (Test-Path $project)) { throw "Upstream download has no project.godot: $game" }
$portableDir = Join-Path $root 'tools'
$godot = Join-Path $portableDir 'Godot_v4.7-stable_win64.exe'
if (-not (Test-Path $godot)) {
    $zip = Join-Path $env:TEMP 'FightLab-Godot47.zip'
    $url = 'https://github.com/godotengine/godot-builds/releases/download/4.7-stable/Godot_v4.7-stable_win64.exe.zip'
    try {
        Write-Host 'Downloading official Godot 4.7 stable for this upstream game...'
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        Expand-Archive -LiteralPath $zip -DestinationPath $portableDir -Force
    } catch {
        throw "Godot 4.7 is required by the upstream game. Automatic download failed: $_"
    } finally {
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
    }
}
if (-not (Test-Path $godot)) { throw "Godot 4.7 executable was not found at $godot" }
Write-Host 'Starting upstream 3D Fighter (choose DEMO for automatic CPU vs CPU).'
Write-Host 'This game requires a Vulkan-capable graphics driver.'
& $godot --path $game
if ($LASTEXITCODE -ne 0) { throw "Upstream Godot game exited with code $LASTEXITCODE" }
