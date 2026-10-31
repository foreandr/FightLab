extends SceneTree
## Run directly to edit only these two clips; also reused by the full generator.
const Channels=preload("res://scripts/animation_channels.gd")
const LIBRARY="res://assets/combat/animations/duel.res"
static func apply(library:AnimationLibrary) -> void:
	var donor:=library.get_animation("shield_hold_brace")
	for name_ in ["strafe_left","strafe_right"]:
		var clip:=Channels.replace_channels(library.get_animation(name_),donor,"duel/shield_hold_brace",["arm_l","arm_r"])
		clip.set_meta("arm_source","duel/shield_hold_brace")
		clip.set_meta("copied_channels",["arm_l","arm_r"])
		library.remove_animation(name_)
		library.add_animation(name_,clip)
func _initialize() -> void:
	var library:=load(LIBRARY).duplicate(true) as AnimationLibrary
	apply(library)
	var error:=ResourceSaver.save(library,LIBRARY)
	if error!=OK:
		push_error("Could not save guarded strafes: %s"%error)
		quit(1)
		return
	print("COPIED BLOCKING ARMS: shield_hold_brace → strafe_left / strafe_right; leg/root tracks preserved")
	quit()
