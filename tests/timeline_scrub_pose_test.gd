extends SceneTree
func _initialize():call_deferred("run")
func run():
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	for frame in range(600):
		await process_frame
		editor=current_scene
		if editor!=null and is_instance_valid(editor.get("slow_button")):break
	var unit:CharacterBody3D=editor.spawn_editor_unit(Vector3(2,0.02,2))
	editor.timeline_clips.assign([{"id":101,"group":"Motion","category":"Acrobatics","title":"Backflip","step":"Flip","clip":"duel/backflip","track":"BODY","start":0.0,"duration":0.68,"priority":2}])
	editor.timeline_duration=0.68
	editor._capture_timeline_origin()
	var bone:int=editor.actor.bones.pelvis
	var first:=Quaternion.IDENTITY
	var stamina:float=unit.stamina
	for time in [0.1,0.4,0.1,0.68]:
		editor._on_timeline_scrubbed(time)
		var expected:Quaternion=editor.actor.skeleton.get_bone_pose_rotation(bone)
		assert(unit.skeleton.get_bone_pose_rotation(bone).angle_to(expected)<0.001,"Scrub must immediately show sampled pose")
		for frame in range(5):await process_frame
		assert(unit.skeleton.get_bone_pose_rotation(bone).angle_to(expected)<0.001,"Idle overwrote scrubbed pose")
		if time==0.1:
			if first==Quaternion.IDENTITY:first=expected
			else:assert(first.angle_to(expected)<0.001,"Backward scrub must reproduce same pose")
	assert(unit.stamina==stamina,"Scrubbing must not spend stamina")
	editor.stop_timeline()
	assert(editor.timeline_scrub_unit==null)
	print("TIMELINE SCRUB PASSED: immediate pose, held pose, reverse seek, endpoint, no stamina cost")
	quit()
