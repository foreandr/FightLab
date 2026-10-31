extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("PIT/PRESENTATION FAILED: "+message)
	quit(1)
	return false
func verify_map(field:Node) -> bool:
	if not check(is_equal_approx(float(field.Boundary.RADIUS),30.0),"Pit radius is not 30 metres"):return false
	var pit=field.get_node_or_null("Colosseum")
	if not check(is_instance_valid(pit) and pit.scene_file_path=="res://scenes/maps/gladiatorial_pit.tscn","Field is not instancing the reusable map"):return false
	var floor_shape:BoxShape3D=pit.get_node("ArenaFloor").get_child(0).shape
	if not check(floor_shape.size.x>=62.0 and floor_shape.size.z>=62.0,"Physical floor is smaller than expanded pit"):return false
	var walls:=0
	for node in pit.get_children():
		if node.has_meta("arena_wall"):
			walls+=1
			if not check(is_equal_approx(Vector2(node.position.x,node.position.z).length(),30.55),"Wall did not move to new boundary"):return false
	return check(walls==40,"Map lost containment walls")
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	if not verify_map(editor.field):return
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/presentation_draft.cfg"
	b.preview_preferences_path="user://logs/presentation_preview.cfg"
	b.open_projectile_workspace()
	b.set_process(false)
	b.playing=false
	var actor=editor.actor
	var tag=actor.get_node("OverheadHealthTag")
	actor.stamina=100.0;actor.mana=100.0;actor.guard_energy=44.0
	tag.update_tag()
	tag._advance_resource_bars(1.0)
	actor.stamina=40.0;actor.mana=40.0;actor.guard_energy=17.6
	tag.update_tag()
	tag._advance_resource_bars(1.0/60.0)
	var shown:float=tag.resource_fills.stamina.displayed
	if not check(shown>0.4 and shown<1.0,"Overhead resource change snaps instead of animating"):return
	for key in ["magica","block"]:
		if not check(absf(float(tag.resource_fills[key].displayed)-shown)<0.001,"Resource bars have different easing"):return
	tag._advance_resource_bars(1.0)
	if not check(absf(float(tag.resource_fills.magica.displayed)-0.4)<0.001 and is_equal_approx(float(actor.mana),40.0),"Smoothing changes actual resources or fails to settle"):return
	var bar=preload("res://scripts/smooth_resource_bar.gd").new()
	bar.value=100.0
	root.add_child(bar)
	bar.set_target_value(40.0)
	bar._process(1.0/60.0)
	if not check(bar.value>40.0 and bar.value<100.0,"Screen resource meter snaps"):return
	bar.queue_free()
	b.clear_shots()
	actor.stamina=100.0;actor.mana=100.0
	b.preview_effect="None"
	b.demo_duration=1.0
	b.casting_animation["duration"]=1.0
	b.launch_projectile()
	if not check(not editor.field.shots.is_empty(),"First comparison shot did not spawn"):return
	var original:Dictionary=editor.field.shots.back()
	var original_radius:float=original.radius
	b.set_projectile_allocation("size",0.9)
	b.set_release_fraction(0.3)
	b.set_demo_duration(1.1)
	b.preview_projectile_effect("Fire")
	if not check(editor.field.shots.has(original) and is_instance_valid(original.node) and is_equal_approx(float(original.radius),original_radius),"Changing settings erased or resized existing projectile"):return
	actor.mana=100.0
	b.launch_projectile()
	if not check(editor.field.shots.size()==2,"Comparison shot replaced previous projectile"):return
	b.reset_practice_scene()
	if not check(editor.field.shots.is_empty(),"Reset does not clear comparison shots"):return
	# Story uses the same shared overhead tag and map. Open its real scene when
	# a saved character exists, without creating or changing the user's profile.
	if FileAccess.file_exists("user://story_character.cfg"):
		change_scene_to_file("res://scenes/fight.tscn")
		await process_frame
		await process_frame
		if not check(current_scene.scene_file_path=="res://scenes/fight.tscn","Story redirected unexpectedly"):return
		if not verify_map(current_scene):return
		for fighter in current_scene.fighters:
			if not check(fighter.get_node("OverheadHealthTag").get_script().resource_path=="res://scripts/fighter_overhead_tag.gd","Story bypasses shared resource presentation"):return
	print("PIT/PRESENTATION PASSED: reusable 30m map and physical boundary, identical smooth overhead/screen meters, settings preserve old shots, reset clears shots, Story shared map and HUD")
	quit()
