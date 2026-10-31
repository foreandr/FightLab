extends SceneTree
## Backward-walk guard with subtle alternating arm sway, shared by both strafes.
const Channels=preload("res://scripts/animation_channels.gd")
const LIBRARY="res://assets/combat/animations/duel.res"
static func apply(library:AnimationLibrary) -> void:
	var donor:=sway(library.get_animation("walk_back"))
	library.remove_animation("walk_back")
	library.add_animation("walk_back",donor)
	for name_ in ["strafe_left","strafe_right"]:
		var clip:=Channels.replace_channels(library.get_animation(name_),donor,"duel/walk_back",["arm_l","arm_r"])
		clip.set_meta("arm_source","duel/walk_back")
		clip.set_meta("copied_channels",["arm_l","arm_r"])
		library.remove_animation(name_)
		library.add_animation(name_,clip)

static func sway(base:Animation) -> Animation:
	# Preserve the unswayed source so rerunning the tool never stacks the edit.
	var source:Animation=base.get_meta("arm_sway_source") if base.has_meta("arm_sway_source") else null
	if source==null:
		source=Channels.filtered(base,"duel/walk_back","arm_l").duplicate(true)
		var right:=Channels.filtered(base,"duel/walk_back","arm_r")
		for track in right.get_track_count():right.copy_track(track,source)
	var result:=base.duplicate(true) as Animation
	for bone in ["upperarm_l","upperarm_r","lowerarm_l","lowerarm_r"]:
		for track in source.get_track_count():
			if source.track_get_type(track)!=Animation.TYPE_ROTATION_3D or str(source.track_get_path(track)).get_slice(":",1)!=bone:continue
			var target:=result.find_track(source.track_get_path(track),Animation.TYPE_ROTATION_3D)
			for key in range(result.track_get_key_count(target)-1,-1,-1):result.track_remove_key(target,key)
			result.track_set_interpolation_type(target,Animation.INTERPOLATION_LINEAR)
			for frame in 61:
				var progress:=frame/60.0
				var phase:=progress*TAU+(PI if bone.ends_with("_r") else 0.0)
				var angle:=deg_to_rad(4.0 if bone.begins_with("upperarm") else -2.0)*sin(phase)
				var rotation:=source.rotation_track_interpolate(track,progress*source.length)*Quaternion(Vector3.RIGHT,angle)
				result.rotation_track_insert_key(target,progress*result.length,rotation.normalized())
	result.set_meta("arm_sway_source",source)
	result.set_meta("arm_sway_degrees",4.0)
	return result
func _initialize() -> void:
	var library:=load(LIBRARY).duplicate(true) as AnimationLibrary
	apply(library)
	var error:=ResourceSaver.save(library,LIBRARY)
	if error!=OK:
		push_error("Could not save guarded strafes: %s"%error)
		quit(1)
		return
	print("SWAYING GUARD ARMS: walk_back → strafe_left / strafe_right; opposing 4 degree shoulder sway; legs/root preserved")
	quit()
