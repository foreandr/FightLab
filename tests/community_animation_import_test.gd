extends SceneTree
func _initialize():call_deferred("run")
func run():
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	for frame in range(600):
		await process_frame
		editor=current_scene
		if editor!=null and is_instance_valid(editor.get("slow_button")):break
	editor.spawn_editor_unit(Vector3(0,0.02,0))
	editor.actor.global_basis=Basis.IDENTITY
	var entries:=preload("res://scripts/community_animation_catalog.gd").entries()
	assert(not entries.is_empty())
	var entry:Dictionary={}
	for candidate in entries:
		if str(candidate.title).begins_with("punch normal"):entry=candidate;break
	assert(not entry.is_empty())
	editor._ensure_animation_source(entry)
	assert(editor.actor.player.has_animation(entry.clip),"Downloaded BVH failed to retarget")
	var animation:Animation=editor.actor.player.get_animation(entry.clip)
	assert(animation.get_track_count()>=13)
	var first:=Quaternion.IDENTITY
	var moved:=false
	for index in range(10):
		editor._sample_row_animation(entry,float(entry.duration)*float(index)/10)
		for bone in editor.actor.skeleton.get_bone_count():
			var rotation:Quaternion=editor.actor.skeleton.get_bone_pose_rotation(bone)
			assert(rotation.is_finite() and absf(rotation.length()-1)<0.001)
		var arm:Quaternion=editor.actor.skeleton.get_bone_pose_rotation(editor.actor.bones.upperarm_r)
		if index==0:first=arm
		elif first.angle_to(arm)>0.1:moved=true
	assert(moved,"Punch arm did not animate")
	var checked_sources:Dictionary={}
	for candidate in entries:
		var source:=str(candidate.source_name)
		if checked_sources.has(source):continue
		editor._ensure_animation_source(candidate)
		assert(editor.actor.player.has_animation(candidate.clip),"Source failed: "+source)
		var imported:Animation=editor.actor.player.get_animation(candidate.clip)
		assert(imported.length>0 and imported.get_track_count()>=13)
		for track in imported.get_track_count():
			for sample in [0.0,imported.length*0.5,imported.length]:
				if imported.track_get_type(track)==Animation.TYPE_ROTATION_3D:
					var rotation:=imported.rotation_track_interpolate(track,sample)
					assert(rotation.is_finite() and absf(rotation.length()-1)<0.001,"Invalid source rotation: "+source)
		checked_sources[source]=true
	editor._load_animation_store()
	assert(editor.animation_store_entries.size()>=entries.size())
	var preferences=[editor.animation_store_search.text,editor.store_body_filter.selected,editor.store_air_filter.selected,editor.store_view_filter.selected]
	editor.animation_store_search.text=""
	editor.store_body_filter.select(0)
	editor.store_air_filter.select(0)
	editor.store_view_filter.select(0)
	editor._populate_animation_store()
	assert(editor.animation_store_list.get_child_count()==100,"Shop must build exactly one hundred-result page")
	var first_title:String=editor.animation_store_list.get_child(0).get_child(0).text
	editor.store_page_next.pressed.emit()
	assert(editor.store_page==1 and editor.animation_store_list.get_child_count()==100)
	assert(editor.animation_store_list.get_child(0).get_child(0).text!=first_title,"Next page repeated the first page")
	editor.animation_store_search.text="tag:acrobatics"
	editor._populate_animation_store()
	assert(editor.store_page==0 and editor.animation_store_list.get_child_count()>0)
	assert(editor.animation_store_list.get_child_count()<=100)
	for row in editor.animation_store_list.get_children():
		assert("acrobatics" in row.get_child(0).get("entry").tags)
	editor.animation_store_search.text=preferences[0]
	editor.store_body_filter.select(preferences[1])
	editor.store_air_filter.select(preferences[2])
	editor.store_view_filter.select(preferences[3])
	editor._populate_animation_store()
	if "--capture-review" in OS.get_cmdline_user_args():
		entry.merge({"id":90001,"track":"BODY","priority":3,"start":0.0,"speed":1.0,"source_in":0.0},true)
		editor.timeline_clips.assign([entry])
		editor.timeline_duration=float(entry.duration)
		editor.timeline_rows.clear()
		editor._rebuild_timeline_tracks()
		editor._on_timeline_scrubbed(float(entry.duration)*0.45)
		editor.field.camera.global_position=Vector3(3,2.6,5)
		editor.field.camera.look_at(Vector3(0,1,0))
		editor.field.camera.h_offset=-1.4
		editor.field.camera.v_offset=0.0
		editor.camera_initialized=true
		editor.inspection_camera.capture_view(editor.field.camera,5.0)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://community_import_review.png")
	print("COMMUNITY IMPORT PASSED: ",entries.size()," source clips in shop; ",checked_sources.size()," source rigs sampled; finite retargeted punch, moving arm, cached resource, 100-row pages")
	quit()
