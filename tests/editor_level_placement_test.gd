extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("EDITOR LEVEL PLACEMENT FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.field.set_physics_process(false)
	var map:=Node3D.new()
	editor.field.add_child(map)
	map.position=Vector3(80,5,20)
	var floor_body:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(24,0.2,16)
	collision.shape=box
	floor_body.add_child(collision)
	map.add_child(floor_body)
	floor_body.position.y=-0.1
	var definition=preload("res://scripts/combat_level.gd").new()
	definition.bounds=definition.Bounds.BOX
	definition.half_extents=Vector2(12,8)
	editor.field.use_level(map,definition)
	await physics_frame
	await physics_frame
	var camera:Camera3D=editor.field.camera
	camera.global_position=map.global_position+Vector3(0,7,10)
	camera.look_at(map.global_position)
	var pointer:Vector2=root.get_visible_rect().size*0.5
	var point:Variant=editor.arena_drag_point(pointer)
	if not check(point is Vector3 and absf(point.y-5.0)<0.01,"Unit drag still intersects a plane at zero"):return
	var unit:CharacterBody3D=editor.spawn_editor_unit_at_screen(pointer)
	if not check(is_instance_valid(unit) and absf(unit.global_position.y-5.02)<0.01 and unit.global_position.distance_to(map.global_position)<0.1,"Dropped unit did not use generated terrain"):return
	editor.move_editor_unit(unit,map.to_global(Vector3(30,1,0)))
	if not check(absf(map.to_local(unit.global_position).x-10.0)<0.01 and absf(unit.global_position.y-5.02)<0.01,"Dragging uses pit bounds or stale ground height"):return
	var b=editor.spell_builder
	b.draft_path="user://logs/level_placement_draft.cfg"
	b.preview_preferences_path="user://logs/level_placement_preview.cfg"
	editor.select_group("Spells")
	b.open_projectile_workspace()
	b.set_process(false);b.set_physics_process(false)
	b.playing=false;b.preview_repeating=false
	b.prepare_preview_targets()
	if not check(editor.actor.global_position.distance_to(map.global_position+Vector3.UP*0.02)<0.05,"Spell practice reset its caster to the old arena center"):return
	if not check(absf(editor.target.global_position.y-5.02)<0.01 and absf(b.practice_human.global_position.y-5.02)<0.01,"Practice targets use floor zero"):return
	print("EDITOR LEVEL PLACEMENT PASSED: real terrain ray picking, dropped/dragged units, rectangular bounds and caster/dummy/human placement on an offset elevated map")
	quit()
