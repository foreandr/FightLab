param(
    [string]$GodotPath,
    [string]$OutputDirectory,
    [int]$Seconds = 40,
    [switch]$IsolateKicks,
    [switch]$Background
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/godot.ps1"
$projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$executable = Find-Godot $GodotPath
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $projectRoot ('builds/review-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$moviePath = Join-Path $OutputDirectory 'gameplay.avi'
$reportPath = Join-Path $OutputDirectory 'contacts.json'
$arguments = @('--path', $projectRoot, '--resolution', '960x600', '--write-movie', $moviePath, '--fixed-fps', '30')
if ($IsolateKicks) {
    $arguments += @('-s', 'res://tests/kick_review.gd')
}
$arguments += @('--', "--report-file=$reportPath")
if (-not $IsolateKicks) { $arguments += "--duration=$Seconds" }
if ($Background -and $env:OS -eq 'Windows_NT') {
    $nativeArguments = $arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }
    $recording = Start-Process -FilePath $executable -ArgumentList $nativeArguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $OutputDirectory 'recording.log') -RedirectStandardError (Join-Path $OutputDirectory 'errors.log')
    $code = $recording.ExitCode
} else {
    & $executable @arguments
    $code = $LASTEXITCODE
}
if ($code -ne 0) { throw "Video review failed (exit $code)." }
if (-not (Test-Path -LiteralPath $reportPath)) {
    throw 'Recording ended before its review completed; no contact timeline was produced.'
}
Write-Host "Movie: $moviePath"
Write-Host "Timestamped contacts: $reportPath"
Write-Host 'Compare consecutive frames around each contact; check support foot, chamber, impact, recoil, and guard recovery.'
