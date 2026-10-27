extends Node3D
## Actual collision-driven rigid bodies and positional joints drive the skin.
var fighter: CharacterBody3D
var bodies := {}
var bindings := {}
var saved := {}
var age := 0.0
var peak_height := 0.0
var floor_contacts := 0
var total_mass := 0.0
var returned := false
var setup_phase := 0
var initial_velocity := Vector3.ZERO
var initial_impulse := Vector3.ZERO
var initial_point := Vector3.ZERO
var land_sounded := false
var previous_velocities := {}
var settled_time := 0.0

func build(owner_: CharacterBody3D, impulse: Vector3, point: Vector3) -> void:
	fighter = owner_
	var skeleton: Skeleton3D = fighter.skeleton
	for i in skeleton.get_bone_count():
		saved[i] = [skeleton.get_bone_pose_position(i), skeleton.get_bone_pose_rotation(i)]
	part("pelvis", "pelvis", "spine_01", 0.16, 14, ["pelvis"])
	part("chest", "spine_01", "neck_01", 0.17, 22, ["spine_01", "spine_02", "spine_03", "neck_01"])
	part("head", "neck_01", "Head", 0.12, 5, ["Head"])
	for side in ["l", "r"]:
		part("arm_"+side, "upperarm_"+side, "lowerarm_"+side, 0.075, 2.5, ["upperarm_"+side])
		part("forearm_"+side, "lowerarm_"+side, "hand_"+side, 0.065, 1.5, ["lowerarm_"+side, "hand_"+side])
		part("thigh_"+side, "thigh_"+side, "calf_"+side, 0.095, 8, ["thigh_"+side])
		part("calf_"+side, "calf_"+side, "foot_"+side, 0.075, 5, ["calf_"+side, "foot_"+side, "ball_"+side])
	var initial := fighter.velocity.limit_length(22)
	var terminal: bool=fighter.health<=0
	var horizontal := Vector3(initial.x,0,initial.z).limit_length(10.0 if terminal else 6.0)
	initial=horizontal+Vector3.UP*clampf(initial.y,-18 if terminal else -5,18)
	initial_velocity=initial
	initial_impulse=impulse
	initial_point=point
	peak_height = bodies.pelvis.global_position.y

func part(name_: String, from: String, to: String, radius: float, mass_: float, bones: Array) -> void:
	var a: Vector3 = fighter.bone_point(from)
	var b: Vector3 = fighter.bone_point(to)
	if name_ == "head":
		b += Vector3.UP * 0.16
	var body := RigidBody3D.new()
	body.name = name_
	body.mass = mass_
	body.freeze=true
	total_mass += mass_
	body.gravity_scale = 1.8
	body.linear_damp = 0.10
	body.angular_damp = 1.8
	body.continuous_cd = true
	body.collision_layer = 1024
	body.collision_mask = 1 | 128 | 256 | 512
	body.contact_monitor = true
	body.max_contacts_reported = 4
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = maxf(radius * 2, a.distance_to(b))
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	body.global_position = (a + b) * 0.5
	body.global_basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
	bodies[name_] = body
	for bone in bones:
		var world: Transform3D = fighter.skeleton.global_transform * fighter.skeleton.get_bone_global_pose(fighter.skeleton.find_bone(bone))
		bindings[bone] = [body, body.global_transform.affine_inverse() * world]

func joint(a: String, b: String, bone: String, swing: float, twist: float) -> void:
	var link := PinJoint3D.new()
	add_child(link)
	link.global_position = fighter.bone_point(bone)
	var direction: Vector3 = (bodies[b].global_position - link.global_position).normalized()
	if direction.length() > 0.1:
		link.global_basis = Basis(Quaternion(Vector3.RIGHT, direction))
	link.node_a = link.get_path_to(bodies[a])
	link.node_b = link.get_path_to(bodies[b])
	link.set_param(PinJoint3D.PARAM_BIAS,0.22)
	link.set_param(PinJoint3D.PARAM_DAMPING,1.0)
	link.set_param(PinJoint3D.PARAM_IMPULSE_CLAMP,25.0)

func step(delta: float) -> bool:
	age += delta
	if setup_phase==0:
		joint("pelvis", "chest", "spine_01", 0.5, 0.4)
		joint("chest", "head", "neck_01", 0.65, 0.6)
		for side in ["l", "r"]:
			joint("chest", "arm_"+side, "upperarm_"+side, 1.25, 0.9)
			joint("arm_"+side, "forearm_"+side, "lowerarm_"+side, 1.3, 0.15)
			joint("pelvis", "thigh_"+side, "thigh_"+side, 1.0, 0.55)
			joint("thigh_"+side, "calf_"+side, "calf_"+side, 1.1, 0.12)
		setup_phase=1
		return false
	if setup_phase==1:
		var center: Vector3=bodies.pelvis.global_position
		var spin: Vector3=((initial_point-center).cross(initial_impulse)/12.0).limit_length(3.5)
		for body in bodies.values():
			body.freeze=false
			body.linear_velocity=initial_velocity+spin.cross(body.global_position-center)
			body.angular_velocity=spin
		setup_phase=2
		return false
	peak_height = maxf(peak_height, bodies.pelvis.global_position.y)
	for bone in bindings:
		var item: Array = bindings[bone]
		var world: Transform3D = item[0].global_transform * item[1]
		var index: int = fighter.skeleton.find_bone(bone)
		var global_pose: Transform3D = fighter.skeleton.global_transform.affine_inverse() * world
		var parent: int = fighter.skeleton.get_bone_parent(index)
		var local: Transform3D = fighter.skeleton.get_bone_global_pose(parent).affine_inverse() * global_pose if parent >= 0 else global_pose
		fighter.skeleton.set_bone_pose_position(index, local.origin)
		fighter.skeleton.set_bone_pose_rotation(index, local.basis.orthonormalized().get_rotation_quaternion())
	fighter.velocity = bodies.pelvis.linear_velocity
	var previous_average:=Vector3.ZERO
	var current_floor_contacts:=0
	for body in bodies.values():
		previous_average+=previous_velocities.get(body.get_instance_id(),body.linear_velocity)*body.mass/total_mass
	for body in bodies.values():
		for collider in body.get_colliding_bodies():
			if collider.has_meta("arena_wall"):
				var normal: Vector3=collider.get_meta("inward_normal")
				var incoming: Vector3=previous_velocities.get(body.get_instance_id(),body.linear_velocity)
				if -previous_average.dot(normal)>-incoming.dot(normal):
					incoming=previous_average
				fighter.wall_crash(body.global_position,normal,maxf(0,-incoming.dot(normal)),incoming)
			elif collider.collision_layer & 1:
				floor_contacts+=1
				current_floor_contacts+=1
		previous_velocities[body.get_instance_id()]=body.linear_velocity
	if floor_contacts>0 and age>0.2 and not land_sounded:
		land_sounded=true
		fighter.arena.audio.impact("land",location(),0.85)
	var stable: bool=current_floor_contacts>0 and minf(bodies.pelvis.global_position.y,bodies.chest.global_position.y)<0.7 and bodies.pelvis.linear_velocity.length()<1.5 and bodies.chest.linear_velocity.length()<1.8 and bodies.chest.angular_velocity.length()<3.0
	settled_time=settled_time+delta if stable else 0.0
	return age>1.4 and settled_time>=0.35

func location() -> Vector3:
	return bodies.pelvis.global_position if bodies.has("pelvis") else fighter.global_position

func add_impulse(impulse: Vector3,point: Vector3) -> void:
	settled_time=0
	if setup_phase<2:
		initial_velocity=(initial_velocity+impulse/total_mass).limit_length(22)
		initial_impulse+=impulse
		initial_point=point
		return
	var center:=location()
	var average:=Vector3.ZERO
	for body in bodies.values():
		average+=body.linear_velocity*body.mass/total_mass
	var change: Vector3=(average+impulse/total_mass).limit_length(22)-average
	var spin: Vector3=((point-center).cross(impulse)/12.0).limit_length(2.0)
	for body in bodies.values():
		body.apply_central_impulse((change+spin.cross(body.global_position-center))*body.mass)
		body.apply_torque_impulse(body.get_inverse_inertia_tensor().inverse()*spin)

func restore_pose() -> void:
	for i in saved:
		fighter.skeleton.set_bone_pose_position(i, saved[i][0])
		fighter.skeleton.set_bone_pose_rotation(i, saved[i][1])
