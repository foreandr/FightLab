extends SceneTree
## Adapted from clintcan/3d-fighter, copyright 2026 Clint Christopher Canada, MIT.
## See assets/combat/licenses/3d-fighter-MIT.txt. FightLab adds build_boxing_hook.
## Bakes a compatible skeletal clip using upstream IK and foot planting helpers.
## Run: godot --headless --path . -s res://scripts/vendor/build_sparring_clips.gd
## Pose dictionaries hold bone-local [position, rotation]; +Z faces the opponent.

const MODEL := "res://assets/characters/base/Superhero_Male_FullBody.gltf"
const UAL1 := "res://assets/combat/animations/UAL1_Standard.glb"
const UAL2 := "res://assets/combat/animations/UAL2_Standard.glb"
const OUTPUT := "res://assets/combat/animations/fight_anims.res"
const TRACK_PREFIX := "Armature/Skeleton3D:"
const SAMPLE_FPS := 30.0

const LOWER_BODY := ["root", "pelvis", "thigh_l", "calf_l", "foot_l", "ball_l", "ball_leaf_l",
	"thigh_r", "calf_r", "foot_r", "ball_r", "ball_leaf_r"]
const SPINE := ["spine_01", "spine_02", "spine_03"]

var skeleton: Skeleton3D
var ual1: AnimationLibrary
var ual2: AnimationLibrary
var guard: Dictionary
var crouch: Dictionary
var rear := "r" # side of the rear (kicking / power-punch) limbs, detected from the guard
var lead := "l"


func _initialize() -> void:
	var model := (load(MODEL) as PackedScene).instantiate()
	skeleton = model.find_child("Skeleton3D") as Skeleton3D
	ual1 = load(UAL1)
	ual2 = load(UAL2)
	guard = sample(ual1.get_animation("Punch_Jab"), 0.0)
	var lib := AnimationLibrary.new()
	lib.add_animation("hook", build_boxing_hook())
	ResourceSaver.save(lib, "res://assets/combat/animations/boxing.res")
	model.free()
	quit()

# FightLab adaptation of upstream's IK/foot-plant composition helpers (MIT).
# A compact rear hook, replacing the fantasy lunge in Melee_Hook.


func build_boxing_hook() -> Animation:
	var lf := global_origin(guard, "foot_l")
	var rf := global_origin(guard, "foot_r")
	var load_pose := duplicate_pose(guard)
	hip_turn(load_pose, -12.0)
	move_bone(load_pose, "pelvis", Vector3(0, -0.025, -0.015))
	plant_both(load_pose, lf, rf)
	var shoulder := global_origin(load_pose, "upperarm_r")
	solve_ik(load_pose, "upperarm_r", "lowerarm_r", "hand_r", shoulder + Vector3(-0.22, -0.07, 0.28), Vector3(-1, 0.1, 0.1))
	var strike := duplicate_pose(guard)
	hip_turn(strike, 30.0)
	move_bone(strike, "pelvis", Vector3(0, -0.015, 0.045))
	plant_both(strike, lf, rf + Vector3(0, 0.025, 0))
	shoulder = global_origin(strike, "upperarm_r")
	solve_ik(strike, "upperarm_r", "lowerarm_r", "hand_r", Vector3(0.08, 1.40, 0.58), Vector3(-1, 0.2, 0.1))
	shoulder_roll(strike, "r", 8.0)
	return make_animation([[0.0, guard], [0.14, load_pose], [0.28, strike], [0.34, strike], [0.68, guard]], false)

# --- Clips -----------------------------------------------------------------------


func rear_sign() -> float:
	return 1.0 if rear == "l" else -1.0


## Two-bone IK in model space: places `end_bone` at `target`, bending `mid_bone` toward
## `pole`. Out-of-reach targets straighten the limb toward them.


func solve_ik(pose: Dictionary, upper: String, mid: String, end_bone: String, target: Vector3, pole: Vector3) -> void:
	var a := global_origin(pose, upper)
	var l1 := a.distance_to(global_origin(pose, mid))
	var l2 := global_origin(pose, mid).distance_to(global_origin(pose, end_bone))
	var to_target := target - a
	var d := clampf(to_target.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var dir := to_target.normalized()
	var cos_a := clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0)
	var bend := pole - dir * pole.dot(dir)
	if bend.length_squared() < 0.0001:
		bend = Vector3.UP.cross(dir)
	bend = bend.normalized()
	var knee := a + dir * (cos_a * l1) + bend * (sqrt(1.0 - cos_a * cos_a) * l1)
	aim(pose, upper, mid, knee - a)
	aim(pose, mid, end_bone, (a + dir * d) - global_origin(pose, mid))


## Keeps a support foot at `planted` (model space), knee bending forward and slightly out.


func plant_foot(pose: Dictionary, side: String, planted: Vector3) -> void:
	var out := 0.25 if side == "l" else -0.25
	solve_ik(pose, "thigh_" + side, "calf_" + side, "foot_" + side, planted, Vector3(out, 0, 1))
	point_foot(pose, side, foot_direction(guard, side))


## Points the foot (ankle → ball) along a model-space direction.


func point_foot(pose: Dictionary, side: String, direction: Vector3) -> void:
	aim(pose, "foot_" + side, "ball_" + side, direction)


func foot_direction(pose: Dictionary, side: String) -> Vector3:
	return global_origin(pose, "ball_" + side) - global_origin(pose, "foot_" + side)


## Pivots the lead (support) foot so the heel turns toward the target; optionally up on
## the ball of the foot.


func hip_turn(pose: Dictionary, degrees: float) -> void:
	var signed := degrees * -rear_sign()
	rotate_bone(pose, "pelvis", Vector3.UP, signed)
	rotate_bone(pose, "spine_02", Vector3.UP, -signed * 0.5)
	rotate_bone(pose, "neck_01", Vector3.UP, -signed * 0.4)


## Leans the torso back (positive) or forward (negative) and sideways toward the
## support side, then rights the head a little.


func shoulder_roll(pose: Dictionary, side: String, degrees: float) -> void:
	rotate_bone(pose, "clavicle_" + side, Vector3(0, 0, 1), degrees * (1.0 if side == "l" else -1.0))


func plant_both(pose: Dictionary, lead_foot: Vector3, rear_foot: Vector3) -> void:
	plant_foot(pose, lead, lead_foot)
	plant_foot(pose, rear, rear_foot)


## Victory: martial-arts salute and bow. Feet come together, right fist meets left palm
## in front of the chest, a measured bow, then upright to hold the salute. ~3.4 s.


func sample(anim: Animation, time: float) -> Dictionary:
	var pose := {}
	for i in skeleton.get_bone_count():
		var rest := skeleton.get_bone_rest(i)
		var path := NodePath(TRACK_PREFIX + skeleton.get_bone_name(i))
		var pos := rest.origin
		var rot := rest.basis.get_rotation_quaternion()
		var pt := anim.find_track(path, Animation.TYPE_POSITION_3D)
		if pt >= 0:
			pos = anim.position_track_interpolate(pt, time)
		var rt := anim.find_track(path, Animation.TYPE_ROTATION_3D)
		if rt >= 0:
			rot = anim.rotation_track_interpolate(rt, time)
		pose[i] = [pos, rot]
	return pose


func duplicate_pose(pose: Dictionary) -> Dictionary:
	var out := {}
	for i in pose:
		out[i] = pose[i].duplicate()
	return out


func global_transform(pose: Dictionary, bone: int) -> Transform3D:
	var local := Transform3D(Basis(pose[bone][1] as Quaternion), pose[bone][0] as Vector3)
	var parent := skeleton.get_bone_parent(bone)
	return local if parent < 0 else global_transform(pose, parent) * local


func global_origin(pose: Dictionary, bone_name: String) -> Vector3:
	return global_transform(pose, skeleton.find_bone(bone_name)).origin


## Rotates `bone` (and its subtree) by `degrees` around a model-space axis.


func rotate_bone(pose: Dictionary, bone_name: String, axis: Vector3, degrees: float) -> void:
	_apply_global_rotation(pose, skeleton.find_bone(bone_name), Quaternion(axis.normalized(), deg_to_rad(degrees)))


## Rotates `bone` so the direction toward `child` points along a model-space direction.


func aim(pose: Dictionary, bone_name: String, child_name: String, direction: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	var from := global_origin(pose, bone_name)
	var to := global_origin(pose, child_name)
	_apply_global_rotation(pose, bone, Quaternion((to - from).normalized(), direction.normalized()))


## Moves `bone` by a model-space offset.


func move_bone(pose: Dictionary, bone_name: String, offset: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := Basis() if parent < 0 else global_transform(pose, parent).basis
	pose[bone][0] = (pose[bone][0] as Vector3) + parent_basis.inverse() * offset


func _apply_global_rotation(pose: Dictionary, bone: int, rotation: Quaternion) -> void:
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := Basis() if parent < 0 else global_transform(pose, parent).basis
	var global_basis := global_transform(pose, bone).basis
	var new_local := parent_basis.inverse() * Basis(rotation) * global_basis
	pose[bone][1] = new_local.get_rotation_quaternion()


func make_animation(keys: Array, loop: bool) -> Animation:
	var anim := Animation.new()
	anim.length = keys[-1][0]
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var pelvis := skeleton.find_bone("pelvis")
	var pos_track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos_track, NodePath(TRACK_PREFIX + "pelvis"))
	for key in keys:
		anim.position_track_insert_key(pos_track, key[0], key[1][pelvis][0])
	for i in skeleton.get_bone_count():
		var track := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(track, NodePath(TRACK_PREFIX + skeleton.get_bone_name(i)))
		anim.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for key in keys:
			anim.rotation_track_insert_key(track, key[0], key[1][i][1])
	return anim
