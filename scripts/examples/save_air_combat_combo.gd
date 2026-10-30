extends "res://scripts/examples/inverted_hook_slash_demo.gd"

func build_demo() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	for frame in range(600):
		await process_frame
		workspace=current_scene
		if workspace!=null and is_instance_valid(workspace.get("slow_button")):break
	var selected:Dictionary={}
	for saved in workspace.timeline_library:
		if str(saved.get("name","")).begins_with("Corkscrew Open Hand Melee Hook"):selected=saved
	assert(not selected.is_empty(),"Saved open-hand combo missing")
	workspace.spawn_editor_unit(Vector3(0,0.02,0))
	workspace.spawn_editor_unit(Vector3(0,0.02,1.1))
	workspace.focus_editor_unit(0)
	workspace.actor.editor_pose_locked=true
	workspace.timeline_clips.assign(selected.clips.duplicate(true))
	workspace.timeline_duration=float(selected.duration)
	workspace.timeline_length_input.set_value_no_signal(workspace.timeline_duration)
	workspace.timeline_name.text=str(selected.name)
	for clip in workspace.timeline_clips:workspace._ensure_animation_source(clip)
	workspace._capture_timeline_origin()
	bake_prefix="user://authored_animations/air_combat_"+str(Time.get_ticks_usec())
	var resource:=bake("corkscrew_open_hand_hook",workspace.timeline_duration,sample_combo)
	var parents:Array=[]
	for clip in workspace.timeline_clips:parents.append(Credits.source(clip))
	var entry:=derived_entry({},"Corkscrew Open Hand Melee Hook",resource,"Attack","Air Combat","Hook",parents,"combined editable timeline baked for reuse; source clips retained in metadata")
	entry.attack_bone="hand_r"
	entry.composed_timeline=selected.duplicate(true)
	entry.tags=["airborne","corkscrew","melee","hook","open hand"]
	var category:=""
	for existing in workspace.category_store.names_for("Attack"):
		if str(existing).nocasecmp_to("Air Combat")==0:category=str(existing)
	if category.is_empty():
		var added:Dictionary=workspace.category_store.add("Attack","Air Combat")
		assert(added.ok,str(added.get("error","Could not save category")))
		category="Air Combat"
	assert(workspace.store_library.take(entry,"Attack",category))
	workspace.actor.player.remove_animation_library("authored_demo")
	workspace._ensure_animation_source(workspace.store_library.last_taken_entry)
	assert(workspace.actor.player.has_animation(resource.clip),"Saved combo could not reload")
	for clip in workspace.timeline_clips:workspace._ensure_animation_source(clip)
	workspace.select_group("Attack")
	workspace.select_category(category,true)
	workspace._rebuild_timeline_tracks()
	workspace._rebuild_timeline_library_menu()
	workspace._on_timeline_scrubbed(0.96)
	frame_camera()
	root.show();root.grab_focus();root.request_attention()
	print("AIR COMBAT SAVED: full combo with jump height, source timeline and credits; F camera shortcut removed")

func sample_combo(time:float) -> Dictionary:
	workspace._apply_timeline_at(minf(time,workspace.timeline_duration-0.00001),true)
	var pose:=capture_pose()
	var rig:Skeleton3D=workspace.actor.skeleton
	var parent:=rig.get_bone_parent(workspace.actor.bones.pelvis)
	var parent_basis:Basis=rig.global_basis
	if parent>=0:parent_basis=parent_basis*rig.get_bone_global_pose(parent).basis
	var height:float=workspace.focused_unit.global_position.y-workspace.timeline_unit_origin.y
	pose.positions.pelvis+=(parent_basis.inverse()*Vector3.UP*height)
	return pose
