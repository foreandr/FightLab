# Install the pinned standard GDScript Godot build locally; no admin rights needed.
$ErrorActionPreference = 'Stop'
$zipUrl = 'https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_win64.exe.zip'
$expectedSha256 = '5C9177625C0DCA18C92BA6328203C7B5A9596C85EF9D7C968396F0272D8F10D9'
$toolsDir = Join-Path $PSScriptRoot '..\..\tools'
$zipPath = Join-Path $env:TEMP 'FightLab-Godot-4.6-stable-win64.zip'
New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
try {
    Write-Host 'Downloading official Godot 4.6 stable (~80 MB)...'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
    if ($actual -ne $expectedSha256) { throw "Godot archive hash mismatch. Expected $expectedSha256, got $actual" }
    Expand-Archive -LiteralPath $zipPath -DestinationPath $toolsDir -Force
    $exe = Join-Path $toolsDir 'Godot_v4.6-stable_win64.exe'
    if (-not (Test-Path -LiteralPath $exe)) { throw 'Downloaded Godot archive did not contain the expected executable.' }
    Write-Host "Godot installed at $exe"
    return $exe
} finally {
    Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
}
