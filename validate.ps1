param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/core/godot.ps1"
$executable = Find-Godot $GodotPath
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--editor','--import','--quit')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--quit-after','60')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/battle_features_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/death_ragdoll_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/wall_collision_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/recovery_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/air_cast_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/overdrive_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/battle_sim_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/elemental_duel_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/defense_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/resources_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/impact_physics_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'-s','res://tests/movement_animation_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'--fixed-fps','60','-s','res://tests/spells_test.gd')
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--path',$PSScriptRoot,'-s','res://tests/spell_animation_test.gd')
Write-Host 'PASS: Fire/Ice/Storm free-for-all, charges, statuses, ragdolls, audio, melee and saved duel/casting regressions.'
