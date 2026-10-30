# All numbered projects use the original FightLab save folder.
function Set-FightLabSharedUserDirectory {
    param([string]$ProjectPath, [int]$Instance)
    $settingsPath = Join-Path $ProjectPath 'project.godot'
    $contents = [IO.File]::ReadAllText($settingsPath)
    foreach ($setting in @{
        'config/use_custom_user_dir' = 'true'
        'config/custom_user_dir_name' = '"Godot/app_userdata/FightLab"'
    }.GetEnumerator()) {
        $pattern = '(?m)^' + [regex]::Escape($setting.Key) + '=.*$'
        $line = $setting.Key + '=' + $setting.Value
        if ([regex]::IsMatch($contents, $pattern)) {
            $contents = [regex]::Replace($contents, $pattern, $line)
        } else {
            $contents = $contents.Replace('[application]', "[application]`n$line")
        }
    }
    $logPath = if ($Instance -eq 1) { 'user://logs/godot.log' } else { "user://logs/instance_$Instance/godot.log" }
    $contents = [regex]::Replace($contents, '(?m)^file_logging/log_path=.*$', 'file_logging/log_path="' + $logPath + '"')
    [IO.File]::WriteAllText($settingsPath, $contents, [Text.UTF8Encoding]::new($false))
}

function Initialize-FightLabSharedData {
    param([string]$UserDataParent = (Join-Path $env:APPDATA 'Godot\app_userdata'))
    $sharedRoot = Join-Path $UserDataParent 'FightLab'
    New-Item -ItemType Directory -Path $sharedRoot -Force | Out-Null
    $migrationRoot = Join-Path $sharedRoot '_shared_migrations'
    New-Item -ItemType Directory -Path $migrationRoot -Force | Out-Null
    $excluded = @('logs', 'shader_cache', 'objectdb_snapshots', 'animation_pavlov')
    foreach ($legacy in Get-ChildItem -LiteralPath $UserDataParent -Directory) {
        if ($legacy.Name -notmatch '^FightLab Instance (\d+)$') { continue }
        $number = $Matches[1]
        $marker = Join-Path $migrationRoot "instance-$number.json"
        if (Test-Path -LiteralPath $marker) { continue }
        $backupRoot = Join-Path (Split-Path -Parent $UserDataParent) ('FightLabSaveBackups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + "-instance-$number")
        $manifest = @()
        foreach ($source in Get-ChildItem -LiteralPath $legacy.FullName -File -Recurse) {
            $relative = $source.FullName.Substring($legacy.FullName.Length + 1)
            $top = ($relative -split '[\\/]')[0]
            if ($top -in $excluded -or $top -like 'pavlov_test_*' -or $top -like 'bot_api_port*') { continue }
            $destination = Join-Path $sharedRoot $relative
            $exists = Test-Path -LiteralPath $destination -PathType Leaf
            if ($exists -and (Get-FileHash -LiteralPath $source.FullName).Hash -eq (Get-FileHash -LiteralPath $destination).Hash) { continue }
            if ($exists) {
                foreach ($entry in @(@{Path=$destination; Label='main-original'}, @{Path=$source.FullName; Label='instance-original'})) {
                    $backup = Join-Path (Join-Path $backupRoot $entry.Label) $relative
                    New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
                    Copy-Item -LiteralPath $entry.Path -Destination $backup
                }
            }
            $takeSource = -not $exists -or $source.LastWriteTimeUtc -gt (Get-Item -LiteralPath $destination).LastWriteTimeUtc
            if ($takeSource) {
                New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
                Copy-Item -LiteralPath $source.FullName -Destination $destination -Force
            }
            $manifest += @{ File=$relative; Conflict=$exists; Selected= $(if ($takeSource) { 'instance' } else { 'main' }) }
        }
        @{ Source=$legacy.FullName; Shared=$sharedRoot; Backups=$backupRoot; Files=$manifest } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $marker
    }
    return $sharedRoot
}
