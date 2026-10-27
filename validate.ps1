param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/core/godot.ps1"
$executable = Find-Godot $GodotPath
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--editor','--import','--quit')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--quit-after','60')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/elemental_duel_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/defense_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/resources_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/impact_physics_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'-s','res://tests/movement_animation_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/spells_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'-s','res://tests/spell_animation_test.gd')
Write-Host 'PASS: localized impact physics, resources, melee, defense, movement, health/KO loop and saved casting study.'
