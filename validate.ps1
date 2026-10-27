param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/core/godot.ps1"
$executable = Find-Godot $GodotPath
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--editor','--import','--quit')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--quit-after','60')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/sparring_test.gd')
Write-Host 'PASS: import, scene startup, and contact-driven sparring integration checks.'
