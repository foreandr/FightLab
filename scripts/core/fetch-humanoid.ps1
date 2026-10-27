# Download CC0 humanoid meshes, kept outside Git to avoid giant binary commits.
$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot '..\..\assets\humanoid'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$url = 'https://raw.githubusercontent.com/Seyamalam/blood-league-kickoff/main/public/assets/vendor/quaternius/night-striker.glb'
$dest = Join-Path $dir 'night-striker.glb'
if (-not (Test-Path -LiteralPath $dest)) {
    $tempFile = "$dest.download"
    try {
        Write-Host 'Fetching CC0 Quaternius humanoid...'
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing -TimeoutSec 120
        if ((Get-Item $tempFile).Length -lt 20000) { throw 'Downloaded model is unexpectedly small.' }
        $bytes = [System.IO.File]::ReadAllBytes($tempFile)
        $magic = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4)
        if ($magic -ne 'glTF') { throw 'Not a valid GLB file header.' }
        Move-Item -LiteralPath $tempFile -Destination $dest
    } finally {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }
}
Write-Host 'Humanoid mesh available.'
