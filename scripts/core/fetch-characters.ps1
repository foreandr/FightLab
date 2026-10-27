# Optional CC0 characters from Gobkit. Downloads once, leaves existing demo functional if offline.
$ErrorActionPreference = 'Stop'
$assetDir = Join-Path $PSScriptRoot '..\..\assets\gobkit'
New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
$manifest = Invoke-RestMethod -Uri 'https://gobkit.com/api/free' -TimeoutSec 25
$pack = @($manifest.packs | Where-Object { $_.id -eq 'minion' -or $_.name -match 'minion' }) | Select-Object -First 1
if (-not $pack) { throw 'Gobkit manifest did not include a minion pack.' }
$models = @($pack.models) | Select-Object -First 2
if ($models.Count -lt 2) { throw 'Gobkit manifest did not provide two models.' }
for ($i = 0; $i -lt 2; $i++) {
    $url = [string]$models[$i].url
    if ($url -notmatch '^https://') { throw 'Asset URL is not HTTPS.' }
    $destination = Join-Path $assetDir ("fighter{0}.glb" -f ($i + 1))
    if (-not (Test-Path -LiteralPath $destination)) {
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -TimeoutSec 120
    }
    if ((Get-Item -LiteralPath $destination).Length -lt 1000) { throw 'Downloaded character file is unexpectedly small.' }
}
Write-Host 'CC0 animated characters downloaded from Gobkit.'
