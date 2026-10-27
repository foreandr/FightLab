param([string]$GodotPath, [switch]$Editor, [switch]$Showcase, [switch]$Sandbox, [switch]$Tour, [switch]$Fight, [switch]$Spells)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/scripts/core/godot.ps1"
try {
    $executable = Find-Godot $GodotPath
} catch {
    if ($GodotPath -or $env:GODOT_PATH) { throw }
    & "$PSScriptRoot/scripts/core/install-godot.ps1" | Out-Host
    $executable = Find-Godot
}
# All combat assets are versioned; importing is safe on a fresh clone and offline.
Invoke-GodotCheck -Executable $executable -Arguments @('--headless','--editor','--path',$PSScriptRoot,'--import','--quit')
$arguments = @('--path', $PSScriptRoot)
if ($Editor) { $arguments += '--editor' }
if ($Showcase -or $Sandbox) { $arguments += 'res://scenes/combat_sandbox.tscn' }
elseif ($Tour) { $arguments += 'res://scenes/combat_showcase.tscn' }
elseif ($Fight) { $arguments += 'res://scenes/main.tscn' }
elseif ($Spells) { $arguments += 'res://scenes/spell_editor.tscn' }
& $executable @arguments
if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
