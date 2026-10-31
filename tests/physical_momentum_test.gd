extends SceneTree
const Momentum=preload("res://scripts/physical_momentum.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("PHYSICAL MOMENTUM FAILED: "+message)
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
	b.draft_path="user://logs/momentum_draft_test.cfg"
	b.preview_preferences_path="user://logs/momentum_preferences_test.cfg"
	b.open_projectile_workspace();b.select_demo_choice("cross",false)
	b.set_process(false);b.set_physics_process(false)
	var field=editor.field
	field.set_physics_process(false)
	var actor=editor.actor
	var victim=editor.target
	b.set_dummy_god_mode(true)
	b.set_character_god_mode(actor,true)
	b.playing=false;b.clear_shots()
	var area:Area3D=victim.practice_dummy_visual.hurtboxes[0]
	var melee:Dictionary={"id":"momentum_punch","effect":"melee","damage":10.0,"charge":0.0}
	for speed in [0.0,4.0,7.0,28.0]:
		actor.velocity=Vector3.BACK*speed
		victim.invulnerability=0.0;victim.guard_energy=0;victim.armor_hp=0
		var before:float=victim.damage_taken
		field.apply_impact(actor,victim,melee,area.global_position,Vector3.BACK,area,Vector3.BACK*0.1)
		if not check(is_equal_approx(victim.damage_taken-before,10.0*(1.0+speed*0.03)),"Actual melee does not apply movement once at speed %s"%speed):return
	for movement in [Vector3.RIGHT*7,Vector3.FORWARD*7,Vector3.UP*7]:
		if not check(Momentum.melee_multiplier(movement,Vector3.BACK,melee)==1.0,"Sideways/backward/vertical movement gives forward melee bonus"):return
	actor.velocity=Vector3.ZERO
	b.manual_aim=true;b.manual_aim_valid=true
	var origin:Vector3=field.fighter_hand(actor,preload("res://scripts/combat_aim.gd").emitter(b.casting_animation))+actor.global_basis.z*0.12
	b.manual_aim_point=origin+Vector3.BACK*20
	var neutral:Dictionary=b.demo_preview_spec()
	var snapshot:=neutral.duplicate(true)
	var neutral_speed:float=preload("res://scripts/basic_projectile.gd").resolved_motion(neutral).speed
	for speed in [0.0,4.0,7.0,28.0]:
		actor.velocity=Vector3.BACK*speed
		var launch_input:Dictionary=b.projectile_preview_launch()
		var prepared:Dictionary=field.projectile_launch_state(actor,launch_input.spec,launch_input.origin)
		field.spawn_projectile(actor,launch_input.spec,launch_input.origin)
		var shot:Dictionary=field.shots.back()
		var expected_speed:float=neutral_speed+speed*0.35
		if not check(is_equal_approx(shot.velocity.length(),expected_speed),"Projectile does not inherit forward speed"):return
		if not check(is_equal_approx(float(shot.spec.damage),10.0*expected_speed/neutral_speed),"Projectile damage does not follow launch speed exactly once"):return
		if not check(shot.spec.potency==neutral.potency and shot.spec.mana==neutral.mana and shot.spec.stamina_cost==neutral.stamina_cost and is_equal_approx(float(shot.radius),float(neutral.projectile_radius)),"Movement changes effect, costs or size"):return
		if not check(shot.velocity.is_equal_approx(prepared.velocity),"Prediction launch and real flight disagree"):return
		b.refresh_demo_timing()
		if not check(b.demo_damage_label.text=="Physical damage: %.1f"%float(shot.spec.damage),"RHS movement damage does not match actual shot"):return
		var again:Dictionary=Momentum.projectile(shot.spec,actor.velocity,Vector3.BACK,neutral_speed,shot.spec.damage)
		if not check(is_equal_approx(float(again.spec.damage),float(shot.spec.damage)),"Already-launched spell gets movement applied twice"):return
		actor.velocity=Vector3.ZERO
		if not check(is_equal_approx(float(shot.spec.damage),10.0*expected_speed/neutral_speed),"Stopping caster removes damage from in-flight projectile"):return
	if not check(neutral==snapshot,"Launch mutates saved/input spell"):return
	var legacy=load("res://scripts/duel_arena.gd").new()
	var prepared_legacy:Dictionary=Momentum.projectile({"effect":"orb"},Vector3.BACK*7,Vector3.BACK,12.5,16.0)
	if not check(is_equal_approx(float(legacy.damage_for(prepared_legacy.spec)),float(prepared_legacy.spec.damage)),"Legacy arena ignores captured projectile damage"):return
	legacy.free()
	b.clear_shots()
	var toward_target:Vector3=victim.global_position-actor.global_position
	toward_target.y=0.0
	actor.velocity=toward_target.normalized()*7
	b.manual_aim_point=victim.bone_point("spine_03")
	victim.invulnerability=0.0;victim.guard_energy=0;victim.armor_hp=0
	var damage_before:float=victim.damage_taken
	b.launch_projectile()
	var moving_shot:Dictionary=field.shots.back()
	var expected_impact:float=moving_shot.spec.damage
	if not check(expected_impact>10.0,"Moving toward actual target gives no projectile damage bonus"):return
	actor.velocity=Vector3.ZERO
	for frame in 100:
		field.step_shots(1.0/60.0)
		if field.shots.is_empty():break
	if not check(is_equal_approx(victim.damage_taken-damage_before,expected_impact),"Moving projectile actual hit does not match captured physical damage"):return
	actor.velocity=Vector3.BACK*28
	var raw:Dictionary=neutral.duplicate(true)
	raw["unrestricted_preview"]=true
	var independent:Dictionary=Momentum.projectile(raw,actor.velocity,Vector3.BACK,neutral_speed,23.0)
	if not check(independent.spec.damage==23.0 and is_equal_approx(float(independent.speed),neutral_speed),"Limiter-off independent fields gain unwanted movement correlation"):return
	b.set_process(true);b.set_physics_process(true)
	root.grab_focus()
	b.set_third_person_focus(victim)
	b.movement_keys[KEY_W]=true
	b.movement_keys[KEY_SHIFT]=true
	for frame in 8:await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if not check(Vector2(actor.velocity.x,actor.velocity.z).length()>4 and float(b.demo_projectile_stats().physical_damage)>10.0 and "movement" in b.demo_damage_breakdown.text,"Live sprint controls/RHS do not show movement bonus"):return
	root.get_texture().get_image().save_png("user://logs/physical_momentum.png")
	b.movement_keys.clear()
	for frame in 2:await physics_frame
	await process_frame
	if not check(is_equal_approx(float(b.demo_projectile_stats().physical_damage),10.0),"Stopping does not restore neutral damage readout"):return
	print("PHYSICAL MOMENTUM PASSED: actual static/walk/sprint/amped melee, directional bonus, moving projectile hit and velocity/damage snapshot, no double application, unchanged costs/effects/size, RHS match and Limiter-off independence")
	quit()
