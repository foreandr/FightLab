extends SceneTree
## Adapted from clintcan/3d-fighter, copyright 2026 Clint Christopher Canada, MIT.
## See assets/combat/licenses/3d-fighter-MIT.txt. FightLab adapts hooks and kicks.
## Bakes bilateral skeletal clips with dense support-foot anchoring.
## Run: godot --headless --path . -s res://scripts/vendor/build_sparring_clips.gd
## Pose dictionaries hold bone-local [position, rotation]; +Z faces the opponent.

const MODEL := "res://assets/characters/base/Superhero_Male_FullBody.gltf"
const UAL1 := "res://assets/combat/animations/UAL1_Standard.glb"
const TRACK_PREFIX := "Armature/Skeleton3D:"

var skeleton: Skeleton3D
var ual1: AnimationLibrary
var guard: Dictionary
var rear := "r" # striking side; can be the lead leg in the unchanged guard
var lead := "l"


func _initialize() -> void:
	var model := (load(MODEL) as PackedScene).instantiate()
	skeleton = model.find_child("Skeleton3D") as Skeleton3D
	ual1 = load(UAL1)
	guard = sample(ual1.get_animation("Punch_Jab"), 0.0)
	var lib := AnimationLibrary.new()
	for side in ["r", "l"]:
		rear = side
		lead = "l" if side == "r" else "r"
		lib.add_animation("hook_" + side, build_boxing_hook())
		lib.add_animation("front_kick_" + side, build_front_kick())
		lib.add_animation("high_kick_" + side, build_high_kick())
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
	plant_foot(load_pose, "l", lf)
	plant_foot(load_pose, "r", rf)
	var shoulder := global_origin(load_pose, "upperarm_" + rear)
	solve_ik(load_pose, "upperarm_" + rear, "lowerarm_" + rear, "hand_" + rear, shoulder + Vector3(rear_sign() * 0.22, -0.07, 0.28), Vector3(rear_sign(), 0.1, 0.1))
	var strike := duplicate_pose(guard)
	hip_turn(strike, 30.0)
	move_bone(strike, "pelvis", Vector3(0, -0.015, 0.045))
	plant_foot(strike, "l", lf)
	plant_foot(strike, "r", rf)
	shoulder = global_origin(strike, "upperarm_" + rear)
	solve_ik(strike, "upperarm_" + rear, "lowerarm_" + rear, "hand_" + rear, Vector3(-rear_sign() * 0.08, 1.40, 0.58), Vector3(rear_sign(), 0.2, 0.1))
	shoulder_roll(strike, rear, 8.0)
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


func build_front_kick() -> Animation:
	var s := rear_sign()
	var lead_foot := global_origin(guard, "foot_" + lead)
	var rear_foot := global_origin(guard, "foot_" + rear)

	var load := duplicate_pose(guard)
	move_bone(load, "pelvis", Vector3(-s * 0.03, -0.02, 0.025))
	plant_foot(load, lead, lead_foot)
	plant_foot(load, rear, rear_foot + Vector3(0, 0.03, 0))
	point_foot(load, rear, Vector3(0, -0.6, 0.8)) # heel lifts as weight leaves the rear leg

	var chamber := duplicate_pose(guard)
	move_bone(chamber, "pelvis", Vector3(-s * 0.07, -0.035, 0.05))
	hip_turn(chamber, 15.0)
	lean(chamber, 8.0, 0.0)
	plant_foot(chamber, lead, lead_foot)
	var hip := global_origin(chamber, "thigh_" + rear)
	solve_ik(chamber, "thigh_" + rear, "calf_" + rear, "foot_" + rear,
		hip + Vector3(s * 0.02, -0.32, 0.28), Vector3(0, 0.4, 1))
	point_foot(chamber, rear, Vector3(0, -0.7, 0.7))
	swing_rear_arm(chamber, 0.18)

	var strike := duplicate_pose(guard)
	move_bone(strike, "pelvis", Vector3(-s * 0.08, -0.025, 0.10)) # hip thrust into the target
	hip_turn(strike, 22.0)
	lean(strike, 16.0, 0.0)
	plant_foot(strike, lead, lead_foot)
	pivot_support_foot(strike, 20.0, false)
	hip = global_origin(strike, "thigh_" + rear)
	solve_ik(strike, "thigh_" + rear, "calf_" + rear, "foot_" + rear,
		Vector3(hip.x * 0.5, 1.08, hip.z + 0.82), Vector3(0, 1, 0.2))
	point_foot(strike, rear, Vector3(0, 0.35, 0.94)) # sole to target, ball of the foot leads
	swing_rear_arm(strike, 0.28)

	var recoil := duplicate_pose(chamber)
	move_bone(recoil, "pelvis", Vector3(0, 0, -0.02))

	return make_planted_animation([[0.0, guard], [0.09, load], [0.20, chamber], [0.36, strike],
		[0.39, strike], [0.54, recoil], [0.72, load], [0.90, guard]])


## Roundhouse (mawashi-geri) to the head with the rear leg: weight shifts onto the lead
## foot, the knee chambers out to the side, the hips turn over as the support heel pivots
## toward the target, and the leg whips through with a pointed foot. The torso leans away
## and the striking-side arm counterbalances while the other hand maintains guard.


func build_high_kick() -> Animation:
	var s := rear_sign()
	var lead_foot := global_origin(guard, "foot_" + lead)
	var rear_foot := global_origin(guard, "foot_" + rear)
	var toward_support := Vector3(-s, 0, 0)

	var load := duplicate_pose(guard)
	move_bone(load, "pelvis", Vector3(0, -0.02, 0.05) + toward_support * 0.05)
	hip_turn(load, 20.0)
	plant_foot(load, lead, lead_foot)
	plant_foot(load, rear, rear_foot + Vector3(0, 0.04, 0))
	point_foot(load, rear, Vector3(0, -0.7, 0.7))
	pivot_support_foot(load, 25.0, false)

	var chamber := duplicate_pose(guard)
	move_bone(chamber, "pelvis", Vector3(0, -0.06, 0.08) + toward_support * 0.07)
	hip_turn(chamber, 60.0)
	lean(chamber, 10.0, 8.0)
	plant_foot(chamber, lead, lead_foot + Vector3(0, 0.015, 0))
	pivot_support_foot(chamber, 60.0, true)
	var hip := global_origin(chamber, "thigh_" + rear)
	# Knee up and out to the side, lower leg folded back behind it.
	solve_ik(chamber, "thigh_" + rear, "calf_" + rear, "foot_" + rear,
		hip + Vector3(s * 0.42, 0.02, -0.02), Vector3(-s * 0.2, 0.3, 1))
	point_foot(chamber, rear, Vector3(s * 0.6, -0.2, -0.6))
	swing_rear_arm(chamber, 0.30)

	var strike := duplicate_pose(guard)
	move_bone(strike, "pelvis", Vector3(0, -0.07, 0.1) + toward_support * 0.09)
	hip_turn(strike, 95.0)
	lean(strike, 20.0, 18.0)
	plant_foot(strike, lead, lead_foot + Vector3(0, 0.02, 0))
	pivot_support_foot(strike, 115.0, true)
	hip = global_origin(strike, "thigh_" + rear)
	var target := Vector3(-s * 0.04, 1.43, 0.74)
	solve_ik(strike, "thigh_" + rear, "calf_" + rear, "foot_" + rear, target, Vector3(0, 1, -0.3))
	point_foot(strike, rear, (target - global_origin(strike, "calf_" + rear)).normalized() + Vector3(-s * 0.3, 0, 0))
	swing_rear_arm(strike, 0.55)

	# Raise outside the torso first; the strike then sweeps sideways at head height.
	var outside := duplicate_pose(strike)
	var outside_target := Vector3(s * 0.34, 1.43, 0.62)
	solve_ik(outside, "thigh_" + rear, "calf_" + rear, "foot_" + rear, outside_target, Vector3(s * 0.2, 1, -0.3))
	point_foot(outside, rear, (outside_target - global_origin(outside, "calf_" + rear)).normalized())
	var follow := duplicate_pose(strike)
	hip_turn(follow, 8.0)
	var follow_target := Vector3(-s * 0.20, 1.43, 0.77)
	solve_ik(follow, "thigh_" + rear, "calf_" + rear, "foot_" + rear, follow_target, Vector3(0, 1, -0.3))
	point_foot(follow, rear, (follow_target - global_origin(follow, "calf_" + rear)).normalized())

	var recoil := duplicate_pose(chamber)
	hip_turn(recoil, -10.0)

	return make_planted_animation([[0.0, guard], [0.10, load], [0.23, chamber], [0.33, outside],
		[0.40, strike], [0.46, follow], [0.63, recoil], [0.83, load], [1.02, guard]])


## Low kick from a crouch: sink onto the lead leg and shoot the rear leg out along the
## canvas, foot flat and pointed, lead hand dropping toward the floor. Impact 0.18 s.


func pivot_support_foot(pose: Dictionary, degrees: float, on_ball: bool) -> void:
	var base := foot_direction(guard, lead)
	var dir := base.rotated(Vector3.UP, deg_to_rad(degrees * -rear_sign()))
	if on_ball:
		dir.y -= 0.22 * Vector2(dir.x, dir.z).length()
	point_foot(pose, lead, dir)


## Turns the hips by `degrees` (positive brings the rear hip forward). Shoulders follow
## about half way and the head stays on the target.


func lean(pose: Dictionary, back_degrees: float, side_degrees: float) -> void:
	rotate_bone(pose, "spine_01", Vector3.RIGHT, -back_degrees * 0.6)
	rotate_bone(pose, "spine_02", Vector3.RIGHT, -back_degrees * 0.4)
	rotate_bone(pose, "spine_01", Vector3(0, 0, 1), -rear_sign() * side_degrees)
	rotate_bone(pose, "neck_01", Vector3.RIGHT, back_degrees * 0.4)


## Rear arm swings down and back to counterbalance a kick (amount 0..1); lead arm keeps
## the guard.


func swing_rear_arm(pose: Dictionary, amount: float) -> void:
	var s := rear_sign()
	var upper := Vector3(s * 0.35, -0.2, 0.25).lerp(Vector3(s * 0.35, -0.85, -0.45), amount)
	var lower := Vector3(0, 0.4, 0.6).lerp(Vector3(s * 0.1, -0.95, -0.15), amount)
	aim(pose, "upperarm_" + rear, "lowerarm_" + rear, upper)
	aim(pose, "lowerarm_" + rear, "hand_" + rear, lower)


## Places a hand at `target` (model space), elbow bending back and out.


## Bake dense poses, then solve the support leg at every sample. The ball of the
## foot anchors the pivot; sparse cubic interpolation otherwise slides/lifts it.
func make_planted_animation(keys: Array) -> Animation:
	var baked := []
	var anchor := global_origin(guard, "ball_" + lead)
	var length: float = keys[-1][0]
	var segment := 0
	for frame in range(int(round(length * 60.0)) + 1):
		var t := minf(frame / 60.0, length)
		while segment < keys.size() - 2 and t > keys[segment + 1][0]:
			segment += 1
		var f := clampf((t - keys[segment][0]) / (keys[segment + 1][0] - keys[segment][0]), 0, 1)
		f = f * f * (3 - 2 * f)
		var pose := {}
		for bone in skeleton.get_bone_count():
			var from: Array = keys[segment][1][bone]
			var to: Array = keys[segment + 1][1][bone]
			pose[bone] = [(from[0] as Vector3).lerp(to[0], f), (from[1] as Quaternion).slerp(to[1], f)]
		var direction := foot_direction(pose, lead)
		for iteration in 2:
			var ankle := global_origin(pose, "foot_" + lead)
			var ball := global_origin(pose, "ball_" + lead)
			plant_foot(pose, lead, ankle + anchor - ball)
			point_foot(pose, lead, direction)
		baked.append([t, pose])
	baked[-1][0] = length
	var anim := make_animation(baked, false)
	for track in anim.get_track_count():
		anim.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	return anim
