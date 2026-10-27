function Find-Godot {
    param([string]$GodotPath)
    $candidates = @()
    if ($GodotPath) { $candidates = @($GodotPath) }
    elseif ($env:GODOT_PATH) { $candidates = @($env:GODOT_PATH) }
    else {
        foreach ($name in @('godot4','godot','Godot_v4.6-stable_win64_console','Godot_v4.6-stable_win64')) {
            $command = Get-Command $name -ErrorAction SilentlyContinue
            if ($command) { $candidates += $command.Source }
        }
        foreach ($folder in @("$PSScriptRoot/../../tools", "$env:LOCALAPPDATA/Programs/Godot", "$env:LOCALAPPDATA/Microsoft/WinGet/Packages", "$env:USERPROFILE/Downloads")) {
            if (Test-Path -LiteralPath $folder) {
                $candidates += Get-ChildItem -LiteralPath $folder -Filter '*godot*.exe' -Recurse -ErrorAction SilentlyContinue | Sort-Object @{Expression={ $_.Name -notmatch 'console' }} | Select-Object -ExpandProperty FullName
            }
        }
    }
    foreach ($candidate in $candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if (-not $command) { continue }
        $version = & $command.Source --version 2>&1
        if ($LASTEXITCODE -eq 0 -and "$version" -match '^4\.6\.stable') { return $command.Source }
    }
    throw 'Godot 4.6 stable not found. Set GODOT_PATH or pass -GodotPath with the executable path.'
}

function Invoke-GodotCheck {
    param([string]$Executable, [string[]]$Arguments)
    $output = & $Executable @Arguments 2>&1
    $code = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    if ($code -ne 0 -or ($output | Where-Object { "$_" -match '(?i)(SCRIPT ERROR:|(^|\s)ERROR:)' })) {
        throw "Godot validation failed (exit $code)."
    }
}
