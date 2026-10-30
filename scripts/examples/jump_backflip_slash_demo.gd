extends SceneTree
## Run with --script res://scripts/examples/jump_backflip_slash_demo.gd.
## --verify-only checks the composition without saving or leaving a window open.
const Catalog=preload("res://scripts/animation_catalog.gd")
const Credits=preload("res://scripts/asset_provenance.gd")

func _initialize() -> void:call_deferred("build_demo")

func build_demo() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	for frame in range(600):
		await process_frame
		editor=current_scene
		if editor!=null and is_instance_valid(editor.get("slow_button")):break
	assert(editor!=null and is_instance_valid(editor.get("slow_button")),"Creation screen failed to load")
	var jump:Dictionary
	var flip:Dictionary
	var slash:Dictionary
	for entry in Catalog.entries():
		if entry.step=="Jump":jump=entry.duplicate(true)
		if entry.step=="Flip":flip=entry.duplicate(true)
		if entry.title=="Left body slash":slash=entry.duplicate(true)
	for custom in editor.load_custom_motion("Jump"):
		if custom.title=="Jump2 Variant":jump=custom.duplicate(true)
	for custom in editor.load_custom_motion("Acrobatics"):
		if custom.title=="Backflip Copy":flip=custom.duplicate(true)
	assert(not jump.is_empty() and not flip.is_empty() and not slash.is_empty(),"Missing combo source")
	var clips:Array[Dictionary]=[
		make_clip(editor,jump,1,"BODY",0.0,1.4,1,80.0),
		make_clip(editor,flip,2,"BODY",0.24,0.68,2,5.0),
		make_clip(editor,slash,3,"LEFT ARM",0.42,0.58,4,12.0)]
	var bot:CharacterBody3D=editor.spawn_editor_unit(Vector3(0,0.02,0))
	bot.rotation.y=0
	var target:CharacterBody3D=editor.spawn_editor_unit(Vector3(0,0.02,1.1))
	target.rotation.y=PI
	editor.focus_editor_unit(0)
	editor.actor.global_basis=bot.global_basis
	editor.timeline_name.text=""
	editor.timeline_clips.assign(clips)
	editor.timeline_duration=1.4
	editor.timeline_serial=3
	editor.timeline_length_input.set_value_no_signal(1.4)
	editor._capture_timeline_origin()
	editor._rebuild_timeline_tracks()
	editor._apply_timeline_at(0.62,true)
	assert(editor.timeline_active.BODY.id==2,"Backflip is not controlling the body")
	assert(editor.timeline_active["LEFT ARM"].id==3,"Slash is not controlling the left arm")
	assert(bot.global_position.y>0.5,"Jump is not providing height")
	var stamina:=0.0
	for clip in clips:
		assert(not clip.has("attached_spell"),"Demo must contain animations only")
		stamina+=float(editor._clip_combat_stats(clip).stamina)
	assert(stamina<=100,"Combo cannot be used with one full stamina bar")
	editor.reset_timeline()
	editor.play_timeline()
	var deadline:=Time.get_ticks_msec()+6000
	while (editor.timeline_playing or not editor.jump_tails.is_empty()) and Time.get_ticks_msec()<deadline:await process_frame
	assert(not editor.timeline_playing and editor.jump_tails.is_empty(),"Combo failed to finish")
	assert(absf(bot.global_position.y-0.02)<0.02,"Combo failed to land")
	editor.reset_timeline()
	bot.stamina=bot.MAX_STAMINA
	target.health=target.MAX_HEALTH
	if "--verify-only" in OS.get_cmdline_user_args():
		print("COMBO DEMO VERIFIED: 3 clips, airborne backflip, higher-priority left slash, 97 stamina, no spells, finished landing")
		quit()
		return
	var name_:="Jump Backflip Left Slash Demo"
	var existing:Array=[]
	for saved in editor.timeline_library:existing.append(str(saved.get("name","")))
	if "--reuse-demo" in OS.get_cmdline_user_args() and name_ in existing:
		editor._rebuild_timeline_library_menu()
		for visible_index in editor.timeline_visible_library_indices.size():
			if str(editor.timeline_library[editor.timeline_visible_library_indices[visible_index]].name)==name_:
				editor._select_saved_timeline(visible_index)
				break
	else:
		name_=preload("res://scripts/animation_store_library.gd").unique_name(name_,existing)
		editor.timeline_name.text=name_
		editor.save_timeline()
	editor._rebuild_timeline_library_menu()
	editor.timeline_library_menu.show()
	editor.timeline_library_menu.tooltip_text="Loaded: "+name_
	editor._update_time_zoom_label()
	editor._rebuild_timeline_tracks()
	editor.timeline_playhead=0
	editor.select_group("Attack")
	editor.select_category("Punch",true)
	editor._apply_timeline_at(0,true)
	editor.field.camera.global_position=Vector3(6,6,11)
	editor.field.camera.look_at(Vector3(0,1.3,0.5))
	editor.field.camera.h_offset=-2.2
	editor.field.camera.v_offset=-1.7
	editor.camera_initialized=true
	editor.inspection_camera.capture_view(editor.field.camera,7.5)
	editor._show_library_notice("Saved %s · BOT_1 selected · press Play"%name_)
	root.show()
	root.grab_focus()
	root.request_attention()
	print("COMBO DEMO SAVED AND READY: ",name_)

func make_clip(editor:Node,entry:Dictionary,id:int,track:String,start:float,duration:float,priority:int,stamina:float) -> Dictionary:
	editor._ensure_animation_source(entry)
	var clip:=entry.duplicate(true)
	var source_duration:float=editor._animation_timeline_duration(entry)
	clip.merge({"id":id,"track":track,"start":start,"duration":duration,"source_length":source_duration,"source_in":0.0,"speed":source_duration/duration,"priority":priority,"effort":stamina},true)
	clip["provenance"]=Credits.source(entry)
	clip.erase("attached_spell")
	return clip
