extends RefCounted
## Reduced articulated impact model: angular momentum, constrained damped joints
## and support loss. Animation supplies the moving equilibrium, not the reaction.
const BODY_MASS := 75.0
var joints := {}
var saved_pose := {}
var support_loss := 0.0
var last_impact := {}
var peak_angle := 0.0
var impacts := 0
var by_zone := {}
var frame_basis := Basis.IDENTITY

func _init() -> void:
	# Model-space principal inertias and angular limits (radians).
	add_joint("pelvis", Vector3(1.8, 1.5, 1.8), Vector3(0.24, 0.26, 0.25), 9.0)
	add_joint("spine_01", Vector3(0.85, 0.75, 0.85), Vector3(0.32, 0.38, 0.30), 10.0)
	add_joint("spine_03", Vector3(0.62, 0.48, 0.62), Vector3(0.29, 0.40, 0.29), 11.0)
	add_joint("neck_01", Vector3(0.075, 0.055, 0.075), Vector3(0.40, 0.42, 0.40), 13.0)
	add_joint("Head", Vector3(0.045, 0.035, 0.045), Vector3(0.32, 0.34, 0.30), 14.0)
	for side in ["l", "r"]:
		add_joint("thigh_" + side, Vector3(0.35, 0.18, 0.35), Vector3(0.50, 0.18, 0.34), 11.0)
		add_joint("calf_" + side, Vector3(0.16, 0.10, 0.16), Vector3(0.65, 0.08, 0.10), 12.0)
		add_joint("upperarm_" + side, Vector3(0.12, 0.10, 0.12), Vector3(0.40, 0.30, 0.40), 12.0)
		add_joint("lowerarm_" + side, Vector3(0.065, 0.045, 0.065), Vector3(0.35, 0.16, 0.18), 13.0)

func add_joint(bone: String, inertia: Vector3, limit: Vector3, frequency: float) -> void:
	joints[bone] = {"angle":Vector3.ZERO, "omega":Vector3.ZERO, "inertia":inertia, "limit":limit, "frequency":frequency}

func restore(skeleton: Skeleton3D) -> void:
	for bone in saved_pose:
		var index := skeleton.find_bone(bone)
		skeleton.set_bone_pose_rotation(index, saved_pose[bone][0])
		skeleton.set_bone_pose_position(index, saved_pose[bone][1])
	saved_pose.clear()

func reset(skeleton: Skeleton3D) -> void:
	restore(skeleton)
	for joint in joints.values():
		joint.angle = Vector3.ZERO
		joint.omega = Vector3.ZERO
	support_loss = 0
	last_impact = {}

func joint_impulse(skeleton: Skeleton3D, bone: String, point: Vector3, impulse: Vector3, share: float) -> Vector3:
	if not joints.has(bone):
		return Vector3.ZERO
	var pivot := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin
	var torque := frame_basis.inverse() * ((point - pivot).cross(impulse) * share)
	var j: Dictionary = joints[bone]
	j.omega = (j.omega + torque / j.inertia).clamp(Vector3.ONE * -8.0, Vector3.ONE * 8.0)
	return torque

func hit(skeleton: Skeleton3D, point: Vector3, impulse: Vector3, zone: String, bone: String, grounded: bool, actor_basis := Basis.IDENTITY) -> void:
	frame_basis = actor_basis
	var torque_log := {}
	var blocked := zone == "shield"
	var leg := zone.begins_with("leg")
	var head := zone == "head"
	var arm := zone.begins_with("arm") or blocked
	var primary := bone if joints.has(bone) else "spine_03"
	torque_log[primary] = joint_impulse(skeleton, primary, point, impulse, 0.045 if head else 0.16)
	if head:
		torque_log["neck_01"] = joint_impulse(skeleton, "neck_01", point, impulse, 0.075)
		torque_log["spine_03"] = joint_impulse(skeleton, "spine_03", point, impulse, 0.055)
	elif leg:
		var side := "l" if bone.ends_with("_l") else "r"
		if primary != "thigh_" + side:
			joint_impulse(skeleton, "thigh_" + side, point, impulse, 0.18)
		# Support-foot disruption bends the struck knee; joint limits prevent a
		# sideways hyperextension. Severity follows impulse rather than damage.
		joints["calf_" + side].omega.x += minf(5.0, impulse.length() / 48.0)
	elif arm:
		var side := "l" if bone.ends_with("_l") else "r"
		if primary != "upperarm_" + side:
			joint_impulse(skeleton, "upperarm_" + side, point, impulse, 0.10)
	else:
		torque_log["spine_01"] = joint_impulse(skeleton, "spine_01", point, impulse, 0.10)
	joint_impulse(skeleton, "pelvis", point, impulse, 0.025 if blocked else (0.065 if leg else 0.045))
	var loss := impulse.length() / 370.0 * (1.5 if leg else (0.55 if head else 0.8))
	if blocked:
		loss *= 0.15
	support_loss = minf(1.6, support_loss + loss * (1.0 if grounded else 0.35))
	impacts += 1
	by_zone[zone] = by_zone.get(zone, 0) + 1
	last_impact = {"zone":zone, "bone":bone, "point":point, "impulse":impulse, "torques":torque_log, "support_loss":support_loss}

func step(delta: float) -> void:
	var steps := maxi(1, ceili(delta * 120.0))
	var dt := delta / steps
	for substep in steps:
		for bone in joints:
			var j: Dictionary = joints[bone]
			var target := Vector3.ZERO
			# Bending knees supplies compliant support while balance recovers.
			if bone.begins_with("calf_"):
				target.x = support_loss * 0.14
			var acceleration: Vector3 = (target - j.angle) * j.frequency * j.frequency - j.omega * j.frequency * 1.5
			j.omega += acceleration * dt
			j.angle += j.omega * dt
			for axis in 3:
				if absf(j.angle[axis]) > j.limit[axis]:
					j.angle[axis] = clampf(j.angle[axis], -j.limit[axis], j.limit[axis])
					j.omega[axis] *= -0.12
			peak_angle = maxf(peak_angle, j.angle.length())
		support_loss = maxf(0, support_loss - dt * 0.85)

func apply(skeleton: Skeleton3D, grounded: bool, actor_basis := Basis.IDENTITY) -> void:
	var frame_to_model := skeleton.global_basis.inverse() * actor_basis
	for bone in joints:
		var index := skeleton.find_bone(bone)
		saved_pose[bone] = [skeleton.get_bone_pose_rotation(index), skeleton.get_bone_pose_position(index)]
		var angle: Vector3 = joints[bone].angle
		if angle.length_squared() < 0.0000001:
			continue
		var global_basis := skeleton.get_bone_global_pose(index).basis
		var parent := skeleton.get_bone_parent(index)
		var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
		var offset := frame_to_model * Basis(Quaternion(angle.normalized(), angle.length())) * frame_to_model.inverse()
		skeleton.set_bone_pose_rotation(index, (parent_basis.inverse() * offset * global_basis).get_rotation_quaternion())
	if grounded and support_loss > 0.01:
		var pelvis := skeleton.find_bone("pelvis")
		var parent := skeleton.get_bone_parent(pelvis)
		var basis_ := skeleton.get_bone_global_pose(parent).basis
		var down := skeleton.global_basis.inverse() * Vector3.DOWN
		skeleton.set_bone_pose_position(pelvis, skeleton.get_bone_pose_position(pelvis) + basis_.inverse() * down * minf(0.12, support_loss * 0.10))
