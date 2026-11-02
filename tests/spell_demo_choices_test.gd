extends SceneTree
var editor:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("SPELL DEMO FAILED: "+message)
	quit(1)
	return false
func visible_buttons(node:Node) -> Array[String]:
	var result:Array[String]=[]
	if node is Button and node.is_visible_in_tree():result.append(node.text)
	for child in node.get_children():result.append_array(visible_buttons(child))
	return result
func point(bone:String) -> Vector3:
	return editor.actor.skeleton.global_transform*editor.actor.skeleton.get_bone_global_pose(editor.actor.bones[bone]).origin
func pose_change(a:Array,b:Array) -> float:
	var maximum:=0.0
	for index in mini(a.size(),b.size()):
		var qa:Quaternion=(a[index] as Transform3D).basis.get_rotation_quaternion().normalized()
		var qb:Quaternion=(b[index] as Transform3D).basis.get_rotation_quaternion().normalized()
		var difference:=qa.inverse()*qb
		maximum=maxf(maximum,2.0*atan2(Vector3(difference.x,difference.y,difference.z).length(),absf(difference.w)))
	return maximum
func effect_only(spec:Dictionary) -> Dictionary:
	var result:=spec.duplicate(false)
	# Animation type belongs to the attachment/demo, not the saved spell effect.
	result.erase("animation_type")
	return result
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var deadline:=Time.get_ticks_msec()+90000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		editor=current_scene
		if editor!=null and is_instance_valid(editor.get("actor")) and not is_instance_valid(editor.get("loading_layer")):break
	if not check(editor!=null and is_instance_valid(editor.get("actor")),"Create was not ready"):return
	var builder=editor.spell_builder
	var original_draft:String=builder.draft_path
	var original_preferences:String=builder.preview_preferences_path
	builder.draft_path="user://logs/spell_demo_test_draft.cfg"
	builder.preview_preferences_path="user://logs/spell_demo_test_preferences.cfg"
	editor.select_group("Spells")
	if not check(visible_buttons(builder)==["Headbutt","Left cross","Melee hook","Left knee","Right roundhouse","Jump Dismantle","Block stand","Self mend","Confirm"],"Spells must show the eight demos and Confirm"):return
	if not check(builder.demo_duration_slider.min_value==0.1 and builder.demo_duration_slider.max_value==60.0,"Duration range is incorrect"):return
	builder.set_demo_duration(1.0)
	if not check(editor.actor.visible and not editor.animation_footer.visible,"Demo character/toolbar visibility is incorrect"):return
	builder.ensure_third_person_camera()
	var forward:Vector3=editor.actor.global_basis.z.normalized()
	if not check(forward.dot(editor.field.camera.global_position-editor.actor.global_position)<0 and forward.dot(editor.field.camera.global_basis.x)>0,"Spell camera must view from behind with casting to screen right"):return
	builder.save_draft()
	var original_spec:Dictionary=effect_only(builder.projectile_spec())
	var original_text:=FileAccess.get_file_as_string(builder.draft_path)
	var clips:Dictionary={}
	var types_seen:Dictionary={}
	for choice in builder.DEMO_ANIMATIONS:
		var badge:Label=builder.demo_type_labels[choice]
		if not check(not badge.text.is_empty() and badge.is_visible_in_tree(),"Demo is missing visible type: "+choice):return
		var profile:Dictionary=builder.demo_source_cache[choice]
		types_seen[preload("res://scripts/animation_cast_type.gd").kind(profile)]=true
	for type_ in preload("res://scripts/animation_cast_type.gd").TYPES:
		if not check(types_seen.has(type_),"No demo for "+type_):return
	if not check(builder.demo_type_labels.dismantle.text=="Movement + Arm","Composite label missing"):return
	for choice in builder.DEMO_ANIMATIONS:
		builder.reset_caster_pose()
		var foot_bone:="foot_l" if choice=="knee" else "foot_r"
		var knee_bone:="calf_l" if choice=="knee" else "calf_r"
		var base_foot:=point(foot_bone).y
		var base_knee:=point(knee_bone).y
		var base_head:=point("Head").y
		var before:Array=builder.capture_demo_pose()
		var camera_transform:Transform3D=editor.field.camera.global_transform
		var camera_settings:=Vector4(editor.field.camera_zoom,editor.field.camera_orbit_yaw,editor.field.camera_orbit_pitch,editor.field.story_camera_base_yaw)
		builder.demo_choices[choice].pressed.emit()
		if not check(editor.field.camera.global_transform.is_equal_approx(camera_transform),"Selecting a demo snapped the camera"):return
		if not check(pose_change(before,builder.capture_demo_pose())<0.0001,"Selecting a demo snapped the rig before blending"):return
		if not check(builder.playing and str(builder.casting_animation.demo_choice)==choice,"Button did not start "+choice):return
		if not check(builder.demo_type_labels[choice].text.contains(preload("res://scripts/animation_cast_type.gd").kind(builder.casting_animation)),"Type label disagrees with selected demo: "+choice):return
		if not check(builder.creation_step=="demo","Click advanced without Confirm"):return
		clips[str(builder.casting_animation.clip)]=true
		if not check(not builder.casting_animation.has("demo_palm"),"Demo is still using a generated palm variation"):return
		if choice in ["hook","block","mend"] and not check(builder.casting_animation.has("store_asset_id") and bool(builder.casting_animation.get("store_raw",false)),"Did not resolve the user's owned source for "+choice):return
		var max_foot:=base_foot
		var max_knee:=base_knee
		var max_hand:=point("hand_r").y
		var captured:=false
		var until:=Time.get_ticks_msec()+3000
		while builder.playing and Time.get_ticks_msec()<until:
			await RenderingServer.frame_post_draw
			max_foot=maxf(max_foot,point(foot_bone).y)
			max_knee=maxf(max_knee,point(knee_bone).y)
			max_hand=maxf(max_hand,point("hand_r").y)
			var sample_progress:=0.5
			if not captured and float(builder.elapsed)>=float(builder.cast_duration())*sample_progress:
				root.get_texture().get_image().save_png("user://logs/spell_demo_"+choice+".png")
				captured=true
		if not check(not builder.playing and not builder.released,"Demo repeated or launched a spell"):return
		if preload("res://scripts/animation_cast_type.gd").owns_legs(builder.casting_animation):
			if not check(builder.demo_exit_pose.is_empty(),"Recovery restarted a redundant exit fade"):return
		elif not check(not builder.demo_exit_pose.is_empty(),"Demo did not start a smooth exit"):return
		var settled:=Time.get_ticks_msec()+260
		while Time.get_ticks_msec()<settled:await process_frame
		if not check(builder.demo_exit_pose.is_empty(),"Demo exit blend did not finish"):return
		if choice=="headbutt":
			var animation:Animation=editor.actor.player.get_animation(str(builder.casting_animation.clip))
			for track in animation.get_track_count():
				if not check(str(animation.track_get_path(track)).get_slice(":",1) in ["Head","neck_01"],"Headbutt contains another body region"):return
			if not check(preload("res://scripts/combat_aim.gd").emitter(builder.casting_animation)=="Head","Headbutt emitter incorrect"):return
		if choice=="knee" and not check(max_knee-base_knee>0.12,"Knee animation did not visibly lift its knee"):return
		# Follow-camera smoothing may move the transform while the animation plays.
		# The user's chosen zoom/orbit must remain unchanged.
		if not check(Vector4(editor.field.camera_zoom,editor.field.camera_orbit_yaw,editor.field.camera_orbit_pitch,editor.field.story_camera_base_yaw).is_equal_approx(camera_settings),"Demo reset zoom/orbit settings"):return
		if not check(effect_only(builder.projectile_spec())==original_spec,"Demo changed spell stats or metadata"):return
		builder.save_draft()
		if not check(FileAccess.get_file_as_string(builder.draft_path)==original_text,"Demo changed spell draft"):return
		print("SPELL_DEMO_RENDERED ",choice," clip=",builder.casting_animation.clip," max_hand=",max_hand," foot_lift=",max_foot-base_foot," knee_lift=",max_knee-base_knee)
		builder.demo_confirm_button.pressed.emit()
		if not check(builder.creation_step=="delivery" and visible_buttons(builder)==["Projectile","Beam","Targeted","Touch","Barrier","← Back"],"Confirm did not open the spell types and Back"):return
		builder.delivery_back_button.pressed.emit()
		if not check(builder.creation_step=="demo","Back did not return to demos"):return
	if not check(clips.size()==8,"Demo choices do not use eight distinct source clips"):return
	for duration in [0.1,1.0,2.0,4.0,8.0,10.0,12.0,16.0,24.0,40.0,60.0]:
		builder.demo_duration_slider.value=duration
		var stats:Dictionary=builder.demo_mana_stats()
		var wait:float=duration*builder.release_fraction
		var expected:=0.0 if wait>=10.0 else pow(2.0,1.0-maxf(0.05,wait))
		if not check(is_equal_approx(float(builder.cast_duration()),duration) and is_equal_approx(float(stats.multiplier),expected),"Duration/mana scaling failed at "+str(duration)):return
		if not check(effect_only(builder.projectile_spec())==original_spec,"Changing demo duration altered the saved spell"):return
		print("SPELL_DEMO_TIMING ",duration," mana_multiplier=",stats.multiplier," saved_percent=",stats.saved_percent)
	for pair in [[1.0,1.0],[5.5,1.5],[10.0,2.0],[19.0,5.0],[28.0,10.0],[37.0,17.0]]:
		builder.set_demo_duration(float(pair[0]))
		if not check(is_equal_approx(float(builder.demo_mana_stats().amplifier),float(pair[1])),"Linear then quadratic Spell amp failed"):return
	builder.set_demo_duration(2.0)
	builder.select_demo_choice("knee",false)
	var switch_at:=Time.get_ticks_msec()+650
	while Time.get_ticks_msec()<switch_at:await process_frame
	var switch_pose:Array=builder.capture_demo_pose()
	builder.select_demo_choice("mend",false)
	if not check(pose_change(switch_pose,builder.capture_demo_pose())<0.0001,"Switching demos mid-animation snaps to idle"):return
	await RenderingServer.frame_post_draw
	if not check(not builder.demo_enter_pose.is_empty(),"Mid-animation change did not blend"):return
	builder.set_demo_duration(16.0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/spell_amplifier.png")
	builder.set_demo_duration(2.0)
	builder.choose_default(false)
	builder.load_demo_preferences()
	if not check(str(builder.casting_animation.demo_choice)=="mend" and is_equal_approx(float(builder.demo_duration),2.0),"Demo choice/duration were not restored"):return
	builder.demo_choices.cross.pressed.emit()
	builder.demo_confirm_button.pressed.emit()
	for type in ["Projectile","Beam","Targeted","Touch","Barrier"]:
		if type!="Projectile":
			if not check(builder.delivery_choices[type].disabled,"Unavailable spell type is enabled: "+type):return
			builder.choose_delivery_type(type)
			if not check(builder.delivery_type=="Projectile","Unavailable type changed the draft"):return
			continue
		builder.delivery_choices[type].pressed.emit()
		var cfg:=ConfigFile.new()
		cfg.load(builder.draft_path)
		if not check(cfg.get_value("spell","delivery_type","")==type and builder.projectile_spec().get("delivery_type","")==type,"Spell type was not saved: "+type):return
	print("SPELL DEMO PASSED: eight exact clips, smooth entry/exit/switching, 100% mana saving after 10s before release, doubling-time Spell Amplifier, Confirm/Back, unchanged saved spell")
	builder.draft_path=original_draft
	builder.preview_preferences_path=original_preferences
	builder.load_draft()
	builder.choose_default(false)
	builder.load_demo_preferences()
	builder.show_creation_step("demo")
	builder.prepare_preview_targets()
	editor.frame_spell_preview(editor.actor)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/spell_demo_workspace.png")
	if "--keep-open" not in OS.get_cmdline_user_args():quit()
