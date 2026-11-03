extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/home.tscn");await process_frame;await process_frame
 var home=current_scene
 assert(not home.navigation_buttons.has("Fight") and not home.navigation_buttons["Free Fight"].disabled and not home.navigation_buttons.Sandbox.disabled)
 home.navigation_buttons["Free Fight"].pressed.emit();assert(home.page=="Free Fight" and home.navigation_buttons.has("CPU 1v1"))
 home.navigation_buttons.Back.pressed.emit();assert(home.page=="Home")
 home.show_page("Fight");assert(home.page=="Free Fight","Old return links failed")
 home.navigation_buttons["CPU 1v1"].pressed.emit();await process_frame;await process_frame
 var cpu=current_scene;assert(cpu.ready_for_match)
 cpu.go_home();await process_frame;await process_frame
 home=current_scene;assert(home.page=="Free Fight")
 home.navigation_buttons.Back.pressed.emit();home.navigation_buttons.Sandbox.pressed.emit()
 await process_frame;await process_frame
 var sandbox=current_scene
 assert(sandbox.workspace_ready and sandbox.title_label.text=="Sandbox" and sandbox.field.fighters.size()==2)
 assert(not sandbox.target.practice_wooden_dummy and not is_instance_valid(sandbox.target.practice_dummy_visual))
 assert(sandbox.field.get_script().get_base_script()==load("res://scripts/combat_world.gd"))
 var actor=sandbox.actor;var target=sandbox.target
 sandbox.focused_unit=actor;sandbox.god_button.pressed.emit()
 assert(actor.practice_god_mode and not target.practice_god_mode)
 assert(actor.spend_stamina(1000) and actor.spend_mana(1000) and actor.stamina==actor.MAX_STAMINA and actor.mana==actor.MAX_MANA)
 sandbox.focused_unit=null;sandbox.sync_god_button();assert(sandbox.god_button.disabled)
 sandbox.focused_unit=target;sandbox.toggle_selected_god_mode();assert(actor.practice_god_mode and target.practice_god_mode)
 var key:=InputEventKey.new();key.keycode=KEY_G;key.pressed=true
 sandbox._input(key);assert(not target.practice_god_mode and actor.practice_god_mode)
 sandbox.spell_builder.prepare_preview_targets();sandbox._process(0.01);assert(actor.practice_god_mode,"Preview reset lost Sandbox choice")
 sandbox.return_to_main_menu();await process_frame;await process_frame
 assert(current_scene.navigation_buttons.has("Free Fight"))
 print("FREE FIGHT / SANDBOX PASS: one public fight entry, CPU option and return, legacy alias, unlocked shared sandbox, selected-only God mode/G input, no selection disabled, scene reset preserved, main menu exit")
 quit()
