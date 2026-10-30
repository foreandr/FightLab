extends CharacterBody3D
## Compatible Quaternius skeletal clips; Godot physics queries decide every contact.
signal contact(kind: String, attacker: int, zone: String, speed: float, fell: bool)
const BASE := "res://assets/combat/"
const StoryCharacter := preload("res://scripts/story_character.gd")
const MOVES := [
	["left_jab", "ual1/Punch_Jab", "hand_l", 0.12, 0.48, 0.86, 1.2],
	["right_cross", "ual1/Punch_Cross", "hand_r", 0.16, 0.57, 0.81, 1.8],
	["right_front_kick", "boxing/front_kick_r", "ball_r", 0.25, 0.41, 1.05, 2.5],
	["left_hook", "boxing/hook_l", "hand_l", 0.14, 0.34, 0.65, 1.7],
	["left_high_kick", "boxing/high_kick_l", "ball_l", 0.33, 0.47, 0.94, 2.8],
	["right_hook", "boxing/hook_r", "hand_r", 0.14, 0.34, 0.65, 1.7],
	["left_front_kick", "boxing/front_kick_l", "ball_l", 0.25, 0.41, 1.10, 2.5],
	["right_high_kick", "boxing/high_kick_r", "ball_r", 0.33, 0.47, 0.94, 2.8],
]
var team := 0
var story_profile: Dictionary = {}
var opponent: CharacterBody3D
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var targets: Array = []
var limb_previous := Vector3.ZERO
var move_index := -1
var move_time := 0.0
var connected := false
var cooldown := 1.0
var reaction := 0.0
var down_time := 0.0
var balance := 0.0
var landed := 0
var received := 0
var recoveries := 0
var sequence := 0
var clip := ""
var rng := RandomNumberGenerator.new()
var knock_velocity := Vector3.ZERO
var bones := {}
var paused_ai := false
var attempted_by_limb := {}
var landed_by_limb := {}

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = 0.2
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.24
	capsule.height = 1.65
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.83
	add_child(collider)
	rng.seed = 2147 + team * 7919
	cooldown = 0.5 + team * 0.7
	var gender := "Male" if team == 0 else "Female"
	if story_profile.is_empty():
		model = (load("res://assets/characters/base/Superhero_%s_FullBody.gltf" % gender) as PackedScene).instantiate()
		add_child(model)
		skeleton = model.find_child("Skeleton3D")
	else:
		var custom_look: StoryCharacter = StoryCharacter.new()
		var fight_profile := story_profile.duplicate(true)
		fight_profile["rotation"] = 0.0
		custom_look.set_profile(fight_profile)
		model = custom_look
		add_child(model)
		custom_look.set_process(false)
		skeleton = custom_look.skeleton
	for i in skeleton.get_bone_count():
		bones[skeleton.get_bone_name(i)] = i
	if story_profile.is_empty():
		customize(gender)
		attach_hair("Hair_Buzzed" if team == 0 else "Hair_Buns")
		attach_hair("Eyebrows_Regular" if team == 0 else "Eyebrows_Female")
		player = AnimationPlayer.new()
		model.add_child(player)
	else:
		# Give the fight rig its own animator rooted at the actual skinned GLTF.
		# The creator preview animator is already manually evaluated and can leave
		# imported fight clips unbound when reused after the scene transition.
		var custom_look: StoryCharacter = model as StoryCharacter
		var rig: Node3D = custom_look.model
		if is_instance_valid(custom_look.animator):
			custom_look.animator.stop()
			custom_look.animator.get_parent().remove_child(custom_look.animator)
			custom_look.animator.free()
		player = AnimationPlayer.new()
		rig.add_child(player)
		player.root_node = NodePath("..")
	if not player.has_animation_library("ual1"):
		player.add_animation_library("ual1", load(BASE + "animations/UAL1_Standard.glb"))
	player.add_animation_library("ual2", load(BASE + "animations/UAL2_Standard.glb"))
	player.add_animation_library("fight", load(BASE + "animations/fight_anims.res"))
	player.add_animation_library("boxing", load(BASE + "animations/boxing.res"))
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	play("fight/guard")
	for spec in [["Head", Vector3(0, 0.09, 0.015), 0.135, 0.28, "head"], ["spine_03", Vector3(0, -0.09, 0), 0.20, 0.51, "body"], ["pelvis", Vector3(0, -0.03, 0), 0.19, 0.32, "body"]]:
		var area := Area3D.new()
		area.collision_layer = 4
		area.collision_mask = 0
		area.monitoring = false
		area.set_meta("fighter", self)
		area.set_meta("zone", spec[4])
		var cs := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = spec[2]
		shape.height = spec[3]
		cs.shape = shape
		area.add_child(cs)
		add_child(area)
		targets.append([area, spec[0], spec[1]])

func customize(gender: String) -> void:
	var outfit_name := "brutus" if team == 0 else "rhea"
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(surface)
			if original == null:
				continue
			var mat := original.duplicate() as StandardMaterial3D
			mat.roughness = 0.8
			mat.metallic_specular = 0.25
			if mat.resource_name.begins_with("MI_Superhero"):
				var filename := "T_Superhero_Male_Light.png" if gender == "Male" else "T_Superhero_Female_Dark_BaseColor.png"
				mat.albedo_texture = load("res://assets/characters/base/" + filename)
				mesh.mesh = load(BASE + "outfits/%s_body.res" % outfit_name)
				var outfit := MeshInstance3D.new()
				outfit.mesh = load(BASE + "outfits/%s_outfit.res" % outfit_name)
				outfit.skin = mesh.skin
				skeleton.add_child(outfit)
				outfit.skeleton = outfit.get_path_to(skeleton)
				for slot in outfit.mesh.get_surface_count():
					var cloth := StandardMaterial3D.new()
					cloth.albedo_color = (Color("9c2639") if team == 0 else Color("245d9c")) if slot == 0 else Color("222b38")
					if slot == 2:
						cloth.albedo_color = Color("c5c9cc")
					cloth.roughness = 0.92
					cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
					outfit.set_surface_override_material(slot, cloth)
			mesh.set_surface_override_material(surface, mat)

func attach_hair(piece_name: String) -> void:
	var piece := (load(BASE + "hair/%s.gltf" % piece_name) as PackedScene).instantiate()
	for mesh: MeshInstance3D in piece.find_children("*", "MeshInstance3D", true, false):
		mesh.owner = null
		mesh.get_parent().remove_child(mesh)
		skeleton.add_child(mesh)
		mesh.skeleton = mesh.get_path_to(skeleton)
		for surface in mesh.mesh.get_surface_count():
			var mat := mesh.mesh.surface_get_material(surface).duplicate() as StandardMaterial3D
			mat.albedo_color = Color("47352e") if team == 0 else Color("251e21")
			mat.roughness = 0.9
			mesh.set_surface_override_material(surface, mat)
	piece.free()

func bone_point(bone: String, offset := Vector3.ZERO) -> Vector3:
	return skeleton.global_transform * (skeleton.get_bone_global_pose(bones[bone]) * offset)

func play(name_: String, speed := 1.0) -> void:
	if clip != name_:
		clip = name_
		player.play(name_, 0.10, speed)

func step(delta: float) -> void:
	if opponent == null:
		return
	cooldown = maxf(0, cooldown - delta)
	balance = maxf(0, balance - delta * 0.20)
	var toward := opponent.global_position - global_position
	toward.y = 0
	var distance := toward.length()
	var direction := toward.normalized()
	var moving := Vector3.ZERO
	if down_time > 0:
		down_time -= delta
		if down_time > 1.5:
			play("ual1/Death01")
			if player.current_animation_position > 1.9:
				player.speed_scale = 0
		else:
			player.speed_scale = 1
			play("ual2/LayToIdle")
		if down_time <= 0:
			recoveries += 1
			cooldown = 0.7
			balance = 0
	elif reaction > 0:
		reaction -= delta
	elif move_index >= 0:
		move_time += delta
		if move_time >= player.current_animation_length:
			move_index = -1
			cooldown = rng.randf_range(0.3, 0.7)
	else:
		player.speed_scale = 1
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(delta * 9, 1))
		var desired: float = MOVES[(sequence + team * 2) % MOVES.size()][5]
		if not paused_ai and opponent.down_time <= 0:
			if distance > desired + 0.05:
				moving = direction * 0.65
			elif distance < desired - 0.10:
				moving = -direction * 0.4
			elif cooldown <= 0 and opponent.reaction <= 0:
				start_move((sequence + team * 2) % MOVES.size())
				sequence += 1
		if move_index < 0:
			play("fight/walk_guard" if moving.length() > 0.1 else "fight/guard", 0.8)
			if moving.dot(direction) < -0.1:
				player.speed_scale = -1
	velocity.x = moving.x + knock_velocity.x
	velocity.z = moving.z + knock_velocity.z
	knock_velocity = knock_velocity.move_toward(Vector3.ZERO, delta * 4.0)
	velocity.y = -0.1 if is_on_floor() else velocity.y - 18.0 * delta
	move_and_slide()
	position.x = clampf(position.x, -2.8, 2.8)
	position.z = clampf(position.z, -2.3, 2.3)
	player.advance(delta)
	var lowest := INF
	for bone in ["foot_l", "foot_r", "ball_l", "ball_r"]:
		var i: int = bones[bone]
		lowest = minf(lowest, skeleton.get_bone_global_pose(i).origin.y - skeleton.get_bone_global_rest(i).origin.y - 0.01)
	model.position.y = maxf(0, -lowest)

func start_move(index: int) -> void:
	player.speed_scale = 1
	move_index = index
	var limb: String = MOVES[index][2]
	attempted_by_limb[limb] = attempted_by_limb.get(limb, 0) + 1
	move_time = 0
	connected = false
	play(MOVES[index][1])
	limb_previous = bone_point(MOVES[index][2])

func update_targets() -> void:
	for target in targets:
		target[0].global_position = bone_point(target[1], target[2])
		target[0].global_basis = skeleton.global_basis * skeleton.get_bone_global_pose(bones[target[1]]).basis
		target[0].force_update_transform()

func detect_contact(delta: float) -> void:
	if move_index < 0:
		return
	var move: Array = MOVES[move_index]
	var current := bone_point(move[2])
	var displacement := current - limb_previous
	var speed := displacement.length() / delta
	var toward := (opponent.global_position - global_position).normalized()
	var outbound := displacement.dot(toward) > 0.001
	if not connected and move_time >= move[3] and move_time <= move[4] and speed > 1.2 and outbound:
		var shape := SphereShape3D.new()
		shape.radius = 0.09 if "kick" not in move[0] else 0.075
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.collision_mask = 4
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var excluded: Array[RID] = []
		for target in targets:
			excluded.append(target[0].get_rid())
		query.exclude = excluded
		var samples := maxi(1, ceili(displacement.length() / 0.035))
		for sample in samples + 1:
			query.transform = Transform3D(Basis.IDENTITY, limb_previous.lerp(current, float(sample) / samples))
			var results := get_world_3d().direct_space_state.intersect_shape(query, 4)
			if not results.is_empty():
				var area: Area3D = results[0].collider
				var victim = area.get_meta("fighter")
				if victim.down_time <= 0:
					var zone: String = area.get_meta("zone")
					var fell: bool = victim.receive_hit(displacement.normalized(), speed, move[6], zone)
					connected = true
					landed += 1
					landed_by_limb[move[2]] = landed_by_limb.get(move[2], 0) + 1
					contact.emit(move[0], team, zone, speed, fell)
					break
	limb_previous = current

func receive_hit(direction: Vector3, speed: float, power: float, zone: String) -> bool:
	received += 1
	move_index = -1
	var horizontal := Vector3(direction.x, 0, direction.z).normalized()
	if horizontal.length() < 0.1:
		horizontal = (global_position - opponent.global_position).normalized()
	knock_velocity = horizontal * clampf(speed * 0.16 * power, 0.3, 1.8)
	balance += power * clampf(speed / 4, 0.35, 1.2)
	var fell := balance > 6.5
	player.speed_scale = 1
	if fell:
		down_time = 4.0
		reaction = 0
		play("ual1/Death01")
	else:
		reaction = 0.45 if zone == "head" else 0.38
		play("ual1/Hit_Head" if zone == "head" else "ual1/Hit_Chest")
	cooldown = reaction + 0.3
	return fell
