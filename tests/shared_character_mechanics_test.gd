extends SceneTree
const Aim=preload("res://scripts/character_aim_pose.gd")
const Channels=preload("res://scripts/animation_channels.gd")
const Pose=preload("res://scripts/spell_cast_motion.gd")
const Movement=preload("res://scripts/character_movement.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("SHARED MECHANICS FAILED: "+message)
	quit(1)
	return false
func source_clip() -> Animation:
	var animation:=Animation.new()
	animation.length=1.0
	for bone in ["upperarm_r","upperarm_l","spine_02"]:
		var index:=animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(index,NodePath("Rig/Skeleton:"+bone))
		animation.rotation_track_insert_key(index,0.0,Quaternion.IDENTITY)
		animation.rotation_track_insert_key(index,1.0,Quaternion(Vector3.UP,0.5))
	return animation
func run() -> void:
	var loading_sandbox=load("res://scripts/combat_testing_sandbox.gd").new()
	var early_key:=InputEventKey.new()
	early_key.keycode=KEY_UP;early_key.pressed=true
	loading_sandbox._unhandled_key_input(early_key)
	loading_sandbox._input(early_key)
	loading_sandbox.take_camera_control()
	loading_sandbox.free()
	var source:=source_clip()
	var filtered:=Channels.filtered(source,"test","arm_r")
	if not check(filtered!=null and filtered.get_track_count()==1,"Limb filter includes another channel"):return
	if not check(Channels.filtered(source,"test","arm_r")==filtered,"Filtered clip is rebuilt for each consumer"):return
	var left:=Channels.filtered(source,"test","arm_l")
	if not check(left!=null and left!=filtered,"Channels share wrong filtered tracks"):return
	var revision:=Channels.revision(source)
	source.rotation_track_insert_key(0,0.5,Quaternion(Vector3.UP,1.1))
	source.emit_changed()
	var changed:=Channels.filtered(source,"test","arm_r")
	if not check(Channels.revision(source)>revision and changed!=filtered and changed.track_get_key_count(0)==3 and filtered.track_get_key_count(0)==2,"Editing source returns stale or mutates in-flight clip"):return
	var retained:Array[Animation]=[]
	for i in 140:
		var item:=source_clip()
		retained.append(item)
		Channels.filtered(item,"test","arm_r")
	if not check(Channels._cache.size()<=Channels.CACHE_LIMIT,"Shared clip cache grows without bound"):return
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.open_projectile_workspace()
	b.set_process(false)
	b.playing=false
	var actor=editor.actor
	var source_name:String=actor._filtered_limb_animation("ual1/Punch_Cross","arm_r")
	var serial:int=actor.story_limb_clip_serial
	if not check(actor._filtered_limb_animation("ual1/Punch_Cross","arm_r")==source_name and actor.story_limb_clip_serial==serial,"Actor rebuilds its animation library on repeated use"):return
	var profile:Dictionary=b.casting_animation
	var physical:Dictionary=b.demo_physical_stats().duplicate(true)
	Pose.pose(actor,profile,0.45)
	var emitter:String=str(profile.get("attack_bone","hand_r"))
	var pivot:Vector3=actor.bone_point("spine_03")
	var wrist:Vector3=actor.bone_point(emitter)
	var target:Vector3=pivot+Basis(Vector3.UP,deg_to_rad(110))*(wrist-pivot)*5.0
	var pelvis:int=actor.bones.pelvis
	var baseline:Quaternion=actor.skeleton.get_bone_pose_rotation(pelvis)
	var pose_before:Array[Quaternion]=[]
	for index in actor.skeleton.get_bone_count():pose_before.append(actor.skeleton.get_bone_pose_rotation(index))
	Aim.apply(actor,target,emitter,0.0)
	for index in actor.skeleton.get_bone_count():
		if not check(pose_before[index].is_equal_approx(actor.skeleton.get_bone_pose_rotation(index)),"Zero-weight aim changes authored animation"):return
	b.manual_aim_point=target;b.manual_aim_valid=true
	b.spell_focus_target=null
	var request:Dictionary=b.cast_pose_aim(0.45)
	if not check(not request.is_empty() and is_equal_approx(float(request.weight),1.0),"Spell preview does not request shared aim at apex"):return
	Pose.pose(actor,profile,0.45,request)
	if not check(baseline.angle_to(actor.skeleton.get_bone_pose_rotation(pelvis))>0.01,"Large aim correction does not engage hips/legs"):return
	if emitter in ["hand_l","hand_r"]:
		var elbow:Vector3=actor.bone_point("lowerarm_"+emitter.right(1))
		var hand:Vector3=actor.bone_point(emitter)
		if not check((hand-elbow).normalized().dot((target-elbow).normalized())>0.999,"Spell hand does not use shared endpoint alignment"):return
	if not check(is_zero_approx(float(b.cast_pose_aim(0.0).weight)) and float(b.cast_pose_aim(0.98).weight)<0.1,"Aim does not blend in/out smoothly"):return
	if not check(b.demo_physical_stats()==physical,"Aim refactor changed resource/damage calculations"):return
	Pose.pose(actor,profile,0.45)
	var thigh:int=actor.bones.thigh_l
	var original:Quaternion=actor.skeleton.get_bone_pose_rotation(thigh)
	Aim.aim_leg(actor,"l",actor.global_basis*Vector3(1,0,1).normalized())
	if not check(original.angle_to(actor.skeleton.get_bone_pose_rotation(thigh))>0.01,"Shared leg aiming does not rotate thigh"):return
	var camera:Camera3D=editor.field.camera
	var forward:=Movement.camera_forward(camera)
	if not check(Movement.camera_direction(Vector2(1,1),camera).length()<=1.00001 and Movement.camera_direction(Vector2(0,1),camera).dot(forward)>0.999,"Shared movement introduces diagonal speed/facing mismatch"):return
	print("SHARED MECHANICS PASSED: immutable bounded clip cache/invalidation, no repeated library rebuild, body/leg/hand aiming in spell preview, zero-weight/native poses, smooth recovery, unchanged cost formulas, shared movement")
	quit()
