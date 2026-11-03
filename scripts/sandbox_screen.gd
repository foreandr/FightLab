extends "res://scripts/spell_creation_screen.gd"
## Sandbox is an adapter over the shared arena/tools, not a second combat mode.
var god_button:Button
var sandbox_god_modes:Dictionary={}
var animation_browser:VBoxContainer
func _build_world()->void:
 super._build_world()
 var extra=field.fighters.pop_back()
 field.remove_child(extra);extra.queue_free()
func _build_ui()->void:
 super._build_ui()
 spell_builder.human_only_targets=true
 spell_builder.draft_path="user://sandbox_spell_draft.cfg"
 spell_builder.preview_preferences_path="user://sandbox_spell_preview.cfg"
func _ready()->void:
 super._ready()
 title_label.text="Sandbox"
 var choices:Container=spell_builder.demo_screen.get_child(0).get_child(0)
 spell_builder.demo_screen.size_flags_vertical=Control.SIZE_EXPAND_FILL
 spell_builder.demo_screen.get_child(0).size_flags_vertical=Control.SIZE_EXPAND_FILL
 choices.size_flags_vertical=Control.SIZE_EXPAND_FILL
 spell_builder.demo_choices.clear();spell_builder.demo_type_labels.clear()
 for child in choices.get_children():choices.remove_child(child);child.queue_free()
 animation_browser=preload("res://scripts/sandbox_animation_browser.gd").new();choices.add_child(animation_browser);animation_browser.setup(self)
 if spell_builder.demo_button.pressed.is_connected(spell_builder.open_demo_animation_picker):spell_builder.demo_button.pressed.disconnect(spell_builder.open_demo_animation_picker)
 spell_builder.demo_button.pressed.connect(func():spell_builder.show_creation_step("demo"))
 spell_builder.demo_button.text="Choose animation"
 for back in spell_builder.find_children("BackToSpellStart","Button",true,false):back.tooltip_text="Return to the animation library"
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
