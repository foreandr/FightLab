extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("SPRINT EXERTION FAILED: "+message)
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
	b.open_projectile_workspace();b.stop_preview_controls()
	b.set_process(false);b.set_physics_process(false);editor.field.set_physics_process(false)
	var actor=editor.actor
	actor.practice_god_mode=false;actor.stamina=100;actor.mana=100
	var before:float=actor.stamina_spent
	for step in 10:
		b.move_caster(0.1,Vector2(0,1),true)
		b.process_demo_preview(0.1)
	if not check(is_equal_approx(actor.stamina,88) and is_equal_approx(actor.stamina_spent-before,12) and actor.mana==100,"Create sprint does not spend 12 stamina/second without regenerating over it"):return
	for step in 10:
		b.move_caster(0.1,Vector2(0,1),false)
		b.process_demo_preview(0.1)
	if not check(actor.stamina>88 and is_equal_approx(actor.stamina_spent-before,12),"Walking consumes stamina or fails to recover"):return
	actor.stamina=100
	b.move_caster(1.0,Vector2.ZERO,true)
	if not check(actor.stamina==100 and not b.caster_sprinting,"Stationary Shift drains stamina or uses sprint pose"):return
	actor.stamina=1
	b.move_caster(0.1,Vector2(0,1),true)
	if not check(actor.stamina==0 and actor.sprint_exhausted and not b.caster_sprinting,"Exhaustion does not fall back to walking"):return
	b.process_demo_preview(1.0)
	var recovered:float=actor.stamina
	b.move_caster(0.1,Vector2(0,1),true)
	if not check(actor.stamina==recovered and not b.caster_sprinting,"Held Shift jitters back into sprint after exhaustion"):return
	b.move_caster(0.1,Vector2.ZERO,false)
	b.move_caster(0.1,Vector2(0,1),true)
	if not check(b.caster_sprinting and actor.stamina<recovered,"Releasing/repressing sprint cannot resume after recovery"):return
	actor.practice_god_mode=true;actor.stamina=100
	before=actor.stamina_spent
	b.move_caster(1.0,Vector2(0,1),true)
	if not check(actor.stamina==100 and actor.stamina_spent==before and b.caster_sprinting,"God Mode sprint spends stamina"):return
	editor.select_group("Motion")
	editor.playtest.toggle();editor.set_physics_process(false)
	var unit=editor.focused_unit
	unit.practice_god_mode=false;unit.stamina=100;unit.stamina_delay=0;unit.sprint_exhausted=false
	before=unit.stamina_spent
	editor.playtest.held={KEY_W:true,KEY_SHIFT:true}
	for step in 10:editor.playtest.physics(0.1)
	if not check(is_equal_approx(unit.stamina,88) and is_equal_approx(unit.stamina_spent-before,12),"Take Control uses a different sprint cost"):return
	editor.playtest.release()
	print("SPRINT EXERTION PASSED: Create/Take Control 12-per-second, no simultaneous regen, walking recovery, stationary Shift free, exhausted walking/release latch and God Mode bypass")
	quit()
