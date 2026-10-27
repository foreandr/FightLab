extends Node3D

# First playable combat sandbox. Uses Godot's built-in physics so it runs offline.
# Visual meshes are temporary placeholders for licensed rigged characters.
const MOVE_SPEED := 5.5
const PUNCH_REACH := 2.15
const PUNCH_IMPULSE := 8.0
const PUNCH_DURATION := 0.36

var fighter: CharacterBody3D
var opponent: RigidBody3D
var fighter_visual: Node3D
var shoulder: Node3D
var camera: Camera3D
var punch_clock := 0.0
var punch_connected := false
var punch_cooldown := 0.0
var facing := Vector3(0, 0, -1)
var opponent_initial := Vector3(0, 1.1, -4)
var hud: Label

func _ready() -> void:
	_build_world()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0
	if Input.is_key_pressed(KEY_W): move.z -= 1.0
	if Input.is_key_pressed(KEY_S): move.z += 1.0
	move = move.normalized()
	if move.length_squared() > 0.01:
		facing = move
		fighter_visual.rotation.y = atan2(-facing.x, -facing.z)
	fighter.velocity.x = move.x * MOVE_SPEED
	fighter.velocity.z = move.z * MOVE_SPEED
	if not fighter.is_on_floor():
		fighter.velocity.y -= 19.6 * delta
	else:
		fighter.velocity.y = -0.1
	fighter.move_and_slide()

	punch_cooldown = maxf(0.0, punch_cooldown - delta)
	if Input.is_key_pressed(KEY_SPACE) and punch_cooldown <= 0.0:
		punch_clock = PUNCH_DURATION
		punch_cooldown = 0.55
		punch_connected = false

	if punch_clock > 0.0:
		punch_clock = maxf(0.0, punch_clock - delta)
		var progress := 1.0 - punch_clock / PUNCH_DURATION
		# Wind-up, extension, recovery. Replace with a licensed skeletal clip later.
		var extension := sin(progress * PI)
		shoulder.rotation.x = 1.25 * extension
		if progress > 0.25 and not punch_connected:
			_try_punch()
			punch_connected = true
	else:
		shoulder.rotation.x = 0.0

	if Input.is_key_pressed(KEY_R):
		opponent.freeze = true
		opponent.linear_velocity = Vector3.ZERO
		opponent.angular_velocity = Vector3.ZERO
		opponent.global_position = opponent_initial
		opponent.global_rotation = Vector3.ZERO
		opponent.freeze = false

	camera.global_position = camera.global_position.lerp(fighter.global_position + Vector3(0, 5.0, 9.0), clampf(delta * 5.0, 0.0, 1.0))
	camera.look_at(fighter.global_position + Vector3(0, 1.1, -1.0), Vector3.UP)

func _try_punch() -> void:
	var toward := opponent.global_position - (fighter.global_position + Vector3.UP)
	var horizontal := Vector3(toward.x, 0.0, toward.z)
	if horizontal.length() > PUNCH_REACH or horizontal.length() < 0.01:
		return
	var direction := horizontal.normalized()
	if facing.dot(direction) < 0.4:
		return
	# The target is an actual RigidBody3D; Godot's physics solver handles the impulse.
	opponent.apply_central_impulse(direction * PUNCH_IMPULSE + Vector3.UP * 2.2)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.16, 0.21)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 1.0)
	env.ambient_light_energy = 0.65
	environment.environment = env
	add_child(environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48, -25, 0)
	sunlight.light_energy = 1.7
	add_child(sunlight)

	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	add_child(floor_body)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(40, 0.5, 40)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.25
	floor_body.add_child(floor_shape)
	_box_mesh(floor_body, Vector3(40, 0.5, 40), Vector3(0, -0.25, 0), Color(0.24, 0.28, 0.32))

	fighter = CharacterBody3D.new()
	fighter.name = "Player"
	fighter.position = Vector3(0, 0.05, 2)
	add_child(fighter)
	var body_collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.37
	capsule.height = 1.9
	body_collider.shape = capsule
	body_collider.position.y = 0.95
	fighter.add_child(body_collider)
	fighter_visual = Node3D.new()
	fighter_visual.name = "TemporaryFighterVisual"
	fighter.add_child(fighter_visual)
	_make_person(fighter_visual, Color(0.14, 0.59, 0.96), true)

	opponent = RigidBody3D.new()
	opponent.name = "PhysicsOpponent"
	opponent.mass = 3.0
	opponent.position = opponent_initial
	opponent.linear_damp = 0.55
	opponent.angular_damp = 1.3
	add_child(opponent)
	var opponent_collider := CollisionShape3D.new()
	var target_shape := CapsuleShape3D.new()
	target_shape.radius = 0.39
	target_shape.height = 2.0
	opponent_collider.shape = target_shape
	opponent.add_child(opponent_collider)
	var opponent_visual := Node3D.new()
	opponent.name = "PhysicsOpponent"
	opponent.add_child(opponent_visual)
	_make_person(opponent_visual, Color(0.98, 0.38, 0.26), false)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 62
	camera.position = Vector3(0, 5, 11)
	add_child(camera)

	var overlay := CanvasLayer.new()
	add_child(overlay)
	hud = Label.new()
	hud.text = "FIGHTLAB  |  WASD move  |  SPACE punch  |  R reset opponent"
	hud.position = Vector2(22, 20)
	hud.add_theme_font_size_override("font_size", 18)
	overlay.add_child(hud)

func _make_person(root: Node3D, tint: Color, is_player: bool) -> void:
	_capsule_mesh(root, 0.38, 1.2, Vector3(0, 1.08 if is_player else 0, 0), tint)
	_sphere_mesh(root, 0.27, Vector3(0, 1.92 if is_player else 0.83, 0), Color(0.91, 0.74, 0.58))
	var limb_y := 1.38 if is_player else 0.30
	_box_mesh(root, Vector3(0.22, 0.85, 0.24), Vector3(-0.23, 0.44 if is_player else -0.65, 0), tint.darkened(0.22))
	_box_mesh(root, Vector3(0.22, 0.85, 0.24), Vector3(0.23, 0.44 if is_player else -0.65, 0), tint.darkened(0.22))
	_box_mesh(root, Vector3(0.20, 0.73, 0.22), Vector3(-0.53, limb_y, 0), tint)
	if is_player:
		shoulder = Node3D.new()
		shoulder.position = Vector3(0.53, 1.65, 0)
		root.add_child(shoulder)
		_box_mesh(shoulder, Vector3(0.22, 0.74, 0.22), Vector3(0, -0.34, -0.05), tint)
		_sphere_mesh(shoulder, 0.16, Vector3(0, -0.71, -0.05), Color(0.91, 0.74, 0.58))
	else:
		_box_mesh(root, Vector3(0.20, 0.73, 0.22), Vector3(0.53, limb_y, 0), tint)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.83
	return mat

func _box_mesh(root: Node, size: Vector3, location: Vector3, tint: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(tint)
	instance.position = location
	root.add_child(instance)

func _sphere_mesh(root: Node, radius: float, location: Vector3, tint: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = 2.0 * radius
	instance.mesh = mesh
	instance.material_override = _material(tint)
	instance.position = location
	root.add_child(instance)

func _capsule_mesh(root: Node, radius: float, height: float, location: Vector3, tint: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.material_override = _material(tint)
	instance.position = location
	root.add_child(instance)
