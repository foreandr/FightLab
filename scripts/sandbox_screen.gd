extends "res://scripts/spell_creation_screen.gd"
## Sandbox is an adapter over the shared arena/tools, not a second combat mode.
var god_button:Button
var sandbox_god_modes:Dictionary={}
func _ready()->void:
 super._ready()
 title_label.text="Sandbox"
 var row:Container=spell_builder.spell_playback_panel.get_child(0)
 god_button=button(row,"God mode",toggle_selected_god_mode)
 god_button.name="SandboxGodMode";god_button.toggle_mode=true
 god_button.tooltip_text="G · Infinite health, stamina and mana for the selected character"
 sync_god_button()
func sync_god_button()->void:
 if not is_instance_valid(god_button):return
 var selected:=is_instance_valid(focused_unit)
 god_button.disabled=not selected
 god_button.set_pressed_no_signal(focused_unit.practice_god_mode if selected else false)
func toggle_selected_god_mode()->void:
 if not is_instance_valid(focused_unit):return
 var enabled:bool=not focused_unit.practice_god_mode
 sandbox_god_modes[focused_unit.get_instance_id()]=enabled
 spell_builder.set_character_god_mode(focused_unit,enabled)
 sync_god_button()
func _process(delta:float)->void:
 super._process(delta)
 if not workspace_ready:return
 for unit in field.fighters:
  if sandbox_god_modes.has(unit.get_instance_id()) and unit.practice_god_mode!=bool(sandbox_god_modes[unit.get_instance_id()]):
   spell_builder.set_character_god_mode(unit,bool(sandbox_god_modes[unit.get_instance_id()]))
 sync_god_button()
func _input(event:InputEvent)->void:
 if workspace_ready and not camera_text_editing() and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_G:
  toggle_selected_god_mode();get_viewport().set_input_as_handled();return
 super._input(event)
