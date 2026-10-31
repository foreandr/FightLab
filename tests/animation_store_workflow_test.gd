extends SceneTree
## Exercises the actual paginated Store rows, their button callbacks and the
## visible bot skeleton. Source-only import tests miss broken page hydration.
var editor:Node
var results:Array[Dictionary]=[]
const REPORT:="user://logs/animation_store_workflow_report.json"

func _initialize() -> void:
	call_deferred("run")

func require(condition:bool,message:String) -> bool:
	if condition:return true
	results.append({"ok":false,"error":message})
	write_report(false)
	push_error("STORE WORKFLOW FAILED: "+message)
	quit(1)
	return false

func write_report(ok:bool) -> void:
	var file:=FileAccess.open(REPORT,FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"ok":ok,"results":results},"\t"))
	print("STORE_WORKFLOW_REPORT ",ProjectSettings.globalize_path(REPORT))

func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var deadline:=Time.get_ticks_msec()+90000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		editor=current_scene
		if editor!=null and is_instance_valid(editor.get("actor")) and not is_instance_valid(editor.get("loading_layer")):break
	if not require(editor!=null and is_instance_valid(editor.get("actor")),"Create did not initialize its actor"):return
	var unit:CharacterBody3D=editor.spawn_editor_unit(Vector3(0,0.02,0))
	if not require(unit==editor.focused_unit,"Spawned bot was not focused"):return
	editor.field.camera.global_position=Vector3(3.2,2.5,4.6)
	editor.field.camera.look_at(Vector3(0,1,0))
	editor.field.camera.h_offset=-0.75
	editor.field.camera.fov=35
	editor.camera_initialized=true
	editor.workspace_nav_panels.Store.show()
	await editor._load_animation_store()
	if not require(editor.store_loaded,"Store did not finish loading"):return
	var details:=FileAccess.open(str(editor.store_index_details_path),FileAccess.READ)
	if not require(details!=null,"Store detail file missing"):return
	for record in editor.store_index_records:
		details.seek(int(record._detail_offset))
		var full=bytes_to_var(details.get_buffer(int(record._detail_size)))
		if not require(full is Dictionary and str(full.get("store_asset_id",""))==str(record.store_asset_id) and str(full.get("clip",""))==str(record.clip) and full.has("bvh_source") and full.has("animation_resource"),"Indexed source record is incomplete: "+str(record.title)):return
	details.close()
	results.append({"ok":true,"check":"all indexed source records complete","records":editor.store_index_records.size()})
	print("STORE_ALL_RECORDS_VERIFIED ",editor.store_index_records.size())
	for row in editor.animation_store_list.get_children():
		var entry:Dictionary=row.get_child(0).get("entry")
		if not require(not str(entry.get("clip","")).is_empty(),"Visible row lost its clip: "+str(entry.get("title",""))):return
	results.append({"ok":true,"check":"initial page hydrated","rows":editor.animation_store_list.get_child_count()})
	for title in ["Female1 D6 CartWheel","Female1 B09 WalkTurnLeft90","Interaction 00001"]:
		editor.animation_store_search.set_block_signals(true)
		editor.animation_store_search.text=title
		editor.animation_store_search.set_block_signals(false)
		for filter in [editor.store_body_filter,editor.store_air_filter,editor.store_creator_filter]:filter.select(0)
		editor.store_view_filter.select(3)
		await editor._populate_animation_store()
		if not require(editor.animation_store_list.get_child_count()>0,"No row for "+title):return
		var row:HBoxContainer=editor.animation_store_list.get_child(0)
		var entry:Dictionary=row.get_child(0).get("entry")
		if not require(entry.has("bvh_source") or entry.has("animation_resource"),"Store row lost the source for "+title):return
		var baseline:Array[Quaternion]=[]
		for bone in unit.skeleton.get_bone_count():baseline.append(unit.skeleton.get_bone_pose_rotation(bone))
		row.get_node("StorePlay").pressed.emit()
		if not require(editor.row_preview_unit==unit,"Play button did not start a preview for "+title):return
		if not require(str(editor.selected_entry.clip)==str(entry.clip),"Play sampled the wrong clip for "+title):return
		var max_angle:=0.0
		var captured:=false
		var duration:float=editor.row_preview_action_duration
		var until:=Time.get_ticks_msec()+ceili((duration+0.6)*1000.0)
		while Time.get_ticks_msec()<until:
			await process_frame
			for bone in baseline.size():max_angle=maxf(max_angle,rad_to_deg(baseline[bone].angle_to(unit.skeleton.get_bone_pose_rotation(bone))))
			if title=="Female1 D6 CartWheel" and not captured and editor.row_preview_elapsed>duration*0.55+0.25:
				editor.workspace_nav_panels.Store.hide()
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("user://logs/store_cartwheel_preview.png")
				editor.workspace_nav_panels.Store.show()
				captured=true
		if not require(max_angle>15.0,"Bot did not visibly move for "+title+": "+str(max_angle)+" degrees"):return
		if not require(not is_instance_valid(editor.row_preview_unit),"Preview failed to finish once for "+title):return
		if not require(editor.timeline_clips.is_empty(),"Store preview changed the timeline"):return
		results.append({"ok":true,"check":"StorePlay button","title":str(entry.title),"max_bone_rotation_degrees":max_angle,"tracks":editor.actor.player.get_animation(str(entry.clip)).get_track_count()})
		print("STORE_PLAY_VERIFIED ",str(entry.title)," target_rotation_degrees=",max_angle)
		if title=="Female1 D6 CartWheel":
			row.get_node("StoreDownload").pressed.emit()
			await process_frame
			var owned:Dictionary={}
			for candidate in editor.store_library.taken.values():
				if str(candidate.get("store_source_id",""))==str(entry.store_asset_id) or str(candidate.get("store_asset_id",""))==str(entry.store_asset_id):owned=candidate;break
			if not require(not owned.is_empty(),"Download button did not save CartWheel; check animation_store diagnostics"):return
			var path:=str(owned.get("animation_resource",""))
			var saved:=load(path) as Animation
			if not require(path.begins_with("res://assets/animations/attached/") and saved!=null,"Download did not create a loadable project animation"):return
			results.append({"ok":true,"check":"StoreDownload button","title":str(owned.title),"project_asset":path,"tracks":saved.get_track_count()})
			print("STORE_DOWNLOAD_VERIFIED ",path)
	write_report(true)
	print("STORE WORKFLOW PASSED")
	if "--keep-open" in OS.get_cmdline_user_args():
		editor.row_preview_unit=null
		editor._set_unit_idle_target(unit)
		editor.select_group("Motion")
		editor.select_category("Downloaded",true)
		editor.animation_store_search.set_block_signals(true)
		editor.animation_store_search.text="Female1 D6 CartWheel"
		editor.animation_store_search.set_block_signals(false)
		await editor._populate_animation_store()
	else:
		current_scene=null
		editor.queue_free()
		await process_frame
		await process_frame
		quit()
