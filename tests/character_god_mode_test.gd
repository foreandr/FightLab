extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("CHARACTER GOD MODE FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.open_projectile_workspace()
	b.preview_preferences_path="user://god_mode_test_preferences.cfg"
	var caster=editor.actor
	var dummy=editor.target
	var human=b.practice_human
	b.set_character_god_mode(caster,false)
	b.set_character_god_mode(dummy,true)
	b.set_character_god_mode(human,false)
	editor.select_editor_unit(caster)
	b.refresh_dummy_controls()
	if not check(b.dummy_god_button.text.contains("You") and not b.dummy_god_button.button_pressed,"Self selection not reflected in toggle"):return
	b.dummy_god_button.set_pressed(true)
	if not check(caster.practice_god_mode and dummy.practice_god_mode and not human.practice_god_mode,"Self toggle changed another character"):return
	if not check(caster.spend_cast_resources(600.0,600.0) and caster.stamina==caster.MAX_STAMINA and caster.mana==caster.MAX_MANA,"God resources not unlimited above max pool"):return
	if not check(caster.spend_mana(1000.0) and caster.spend_stamina(1000.0),"Single-resource actions still limited"):return
	editor._spend_unit_stamina(caster,1000.0)
	if not check(caster.stamina==caster.MAX_STAMINA,"Timeline drains God Mode stamina"):return
	editor.select_editor_unit(human)
	b.refresh_dummy_controls()
	if not check(not b.dummy_god_button.button_pressed and b.dummy_god_button.text.contains("Human target"),"Selection shows wrong character state"):return
	b.dummy_god_button.set_pressed(true)
	human.guard_energy=0.0
	human.invulnerability=0.0
	var before:float=human.damage_taken
	var landed:bool=human.receive_magic(10000.0,Vector3.FORWARD,caster,human.bone_point("spine_03"),"chest","spine_03",Vector3.FORWARD*0.1)
	if not check(landed and human.damage_taken>before and human.health==human.MAX_HEALTH,"God mode suppresses damage events or permits death"):return
	human.receive_status(caster,{"projectile_element":"Lightning","potency":1.0})
	if not check(human.stun_time>0.0,"God mode suppressed status reactions"):return
	human.receive_status(caster,{"projectile_element":"Fire","potency":1.0})
	human.burn_clock=0.5
	human.update_status(0.01)
	if not check(human.health==human.MAX_HEALTH and human.burn_time>0.0,"Burn consumes God health or is suppressed"):return
	human.wall_crash_cooldown=0.0
	human.wall_crash(human.global_position,Vector3.BACK,10.0,Vector3.FORWARD*10.0)
	if not check(human.health==human.MAX_HEALTH and human.stamina==human.MAX_STAMINA,"Wall crash consumes God resources"):return
	editor.select_editor_unit(dummy)
	b.refresh_dummy_controls()
	b.dummy_god_button.set_pressed(false)
	if not check(not dummy.practice_god_mode and caster.practice_god_mode and human.practice_god_mode,"Disabling dummy altered another actor"):return
	b.reset_practice_scene()
	if not check(caster.practice_god_mode and human.practice_god_mode and not dummy.practice_god_mode,"Reset overwrote per-character choices"):return
	editor.clear_editor_unit_selection()
	b.refresh_dummy_controls()
	if not check(b.dummy_god_button.disabled,"No selection silently edits another character"):return
	b.set_character_god_mode(caster,false)
	caster.stamina=100;caster.mana=100
	if not check(caster.spend_cast_resources(10,10) and caster.stamina==90 and caster.mana==90,"Normal resource costs broken"):return
	if not check(not caster.spend_cast_resources(1000,1000),"Off mode accepts unaffordable casts"):return
	dummy.invulnerability=0.0;dummy.guard_energy=0.0
	dummy.receive_magic(10000,Vector3.FORWARD,caster,dummy.bone_point("spine_03"))
	if not check(dummy.health<=0.0,"God-off dummy cannot die"):return
	var cfg:=ConfigFile.new()
	cfg.load(b.preview_preferences_path)
	var saved:Dictionary=cfg.get_value("practice","character_god_modes",{})
	if not check(saved.get("caster")==false and saved.get("dummy")==false and saved.get("human")==true,"Per-character settings not saved"):return
	print("CHARACTER GOD MODE PASSED: selected self/dummy/human isolated, unlimited costs, damage/status retained, reset persistence, off-mode costs/death, no-selection guard")
	quit()
