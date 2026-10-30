[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateRange(1, 999)]
    [int]$Instance = 1,

    # Refresh is deliberately opt-in. It replaces only this isolated instance's
    # project snapshot; Godot user data is stored separately and is preserved.
    [switch]$Refresh
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\core\shared-user-data.ps1')

$developmentProject = [IO.Path]::GetFullPath($PSScriptRoot)
$instancesRoot = Join-Path (Split-Path -Parent $developmentProject) 'FightLabInstances'
$instanceProject = if ($Instance -eq 1) {
    $developmentProject
} else {
    Join-Path $instancesRoot "instance-$Instance"
}
$godot = Join-Path $developmentProject 'tools\Godot_v4.6-stable_win64.exe'

function Stop-NumberedInstance([string]$ProjectPath) {
    $fullProjectPath = [IO.Path]::GetFullPath($ProjectPath).TrimEnd('\')
    $pathPattern = '(?i)--path\s+(?:"' + [regex]::Escape($fullProjectPath) + '"|' + [regex]::Escape($fullProjectPath) + ')(?=\s|$)'
    $allowedNames = @('Godot_v4.6-stable_win64.exe', 'Godot_v4.6-stable_win64_console.exe')
    $matchingProcesses = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -in $allowedNames -and $_.CommandLine -match $pathPattern
    }

    foreach ($process in $matchingProcesses) {
        Write-Host "Closing FightLab instance $Instance (PID $($process.ProcessId))..."
        Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
    }
}

function Set-InstanceProjectName([string]$ProjectPath, [int]$Number) {
    $settingsPath = Join-Path $ProjectPath 'project.godot'
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        throw "The snapshot is missing project.godot: $settingsPath"
    }

    $contents = [IO.File]::ReadAllText($settingsPath)
    $name = if ($Number -eq 1) { 'FightLab' } else { "FightLab Instance $Number" }
    $replacement = 'config/name="' + $name + '"'
    $updated = [regex]::Replace($contents, '(?m)^config/name=.*$', [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $replacement }, 1)
    if ($updated -eq $contents) {
        throw "Could not locate application/config/name in $settingsPath"
    }
    [IO.File]::WriteAllText($settingsPath, $updated, [Text.UTF8Encoding]::new($false))
}

function New-ProjectSnapshot([string]$Destination) {
    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    $staging = Join-Path $parent ('.staging-' + [IO.Path]::GetFileName($Destination) + '-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    try {
        # Keep the source project and its Git history untouched. Each copy gets
        # its own .godot import/editor cache after its first launch.
        & robocopy.exe $developmentProject $staging /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XD (Join-Path $developmentProject '.git') (Join-Path $developmentProject '.godot') /NFL /NDL /NJH /NJS /NP | Out-Null
        $copyCode = $LASTEXITCODE
        if ($copyCode -ge 8) {
            throw "Project snapshot copy failed (robocopy exit code $copyCode)."
        }
        Set-InstanceProjectName $staging $Instance

        if (Test-Path -LiteralPath $Destination) {
            $backup = Join-Path $parent ('.previous-' + [IO.Path]::GetFileName($Destination) + '-' + [guid]::NewGuid().ToString('N'))
            if ((Split-Path -Parent $backup) -ne $parent) {
                throw 'Safety check failed for the snapshot backup path.'
            }
            Move-Item -LiteralPath $Destination -Destination $backup
            try {
                Move-Item -LiteralPath $staging -Destination $Destination
            } catch {
                if (-not (Test-Path -LiteralPath $Destination) -and (Test-Path -LiteralPath $backup)) {
                    Move-Item -LiteralPath $backup -Destination $Destination
                }
                throw
            }
            if ((Split-Path -Parent $backup) -ne $instancesRoot) {
                throw 'Safety check failed before removing the replaced snapshot.'
            }
            Remove-Item -LiteralPath $backup -Recurse -Force
        } else {
            Move-Item -LiteralPath $staging -Destination $Destination
        }
    } finally {
        if (Test-Path -LiteralPath $staging) {
            if ((Split-Path -Parent $staging) -ne $parent) {
                throw 'Safety check failed for the temporary snapshot path.'
            }
            Remove-Item -LiteralPath $staging -Recurse -Force
        }
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $developmentProject 'project.godot') -PathType Leaf)) {
    throw "FightLab development project not found: $developmentProject"
}
if (-not (Test-Path -LiteralPath $godot -PathType Leaf)) {
    throw "Godot executable not found: $godot"
}
if ($Refresh -and $Instance -eq 1) {
    throw 'Instance 1 is the live development project and cannot be refreshed from itself.'
}

if ($Instance -gt 1) {
    New-Item -ItemType Directory -Path $instancesRoot -Force | Out-Null
    if ($Refresh) {
        Stop-NumberedInstance $instanceProject
        Write-Host "Refreshing isolated FightLab instance $Instance from the current development project..."
        New-ProjectSnapshot $instanceProject
    } elseif (-not (Test-Path -LiteralPath (Join-Path $instanceProject 'project.godot') -PathType Leaf)) {
        Write-Host "Creating persistent isolated FightLab instance $Instance from the current development project..."
        New-ProjectSnapshot $instanceProject
    }
}

Stop-NumberedInstance $instanceProject
$dataRoot = Initialize-FightLabSharedData
Set-FightLabSharedUserDirectory -ProjectPath $instanceProject -Instance $Instance
Write-Host "Starting FightLab instance $Instance"
Write-Host "Project:  $instanceProject"
Write-Host "User data: $dataRoot"
Start-Process -FilePath $godot -ArgumentList @('--path', $instanceProject, '--windowed', '--', "--fightlab-instance=$Instance") -WorkingDirectory $instanceProject
