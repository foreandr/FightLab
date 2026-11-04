extends Node
## Only renders the six visible cards; catalog size never creates more viewports.
var jobs: Array[Dictionary] = []
var busy := false
static var cache: Dictionary = {}
static var cache_order: Array[String] = []
func request(profile: Dictionary, slot: String, target: TextureRect) -> void:
	var key := str(profile.hash()) + slot
	if cache.has(key): target.texture = cache[key]; return
	jobs.append({"profile":profile,"slot":slot,"target":weakref(target),"key":key})
func _process(_delta: float) -> void:
	if busy or jobs.is_empty(): return
	busy = true
	var job: Dictionary = jobs.pop_front()
	if job.target.get_ref() == null: busy = false; return
	var viewport := SubViewport.new(); viewport.size = Vector2i(220,180); viewport.own_world_3d = true; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(viewport)
	var world := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("102433"); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.8; world.environment = env; viewport.add_child(world)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-30,-25,0); light.light_energy = 1.5; viewport.add_child(light)
	var model := preload("res://scripts/story_character.gd").new(); viewport.add_child(model); model.set_profile(job.profile)
	if model.animator != null:
		model.animator.seek(0.1,true)
		model.animator.pause()
	var camera := Camera3D.new(); viewport.add_child(camera)
	var center := Vector3(0,1,0); var distance := 3.2
	match str(job.slot):
		"hair", "wardrobe_hat", "wardrobe_mask", "wardrobe_earrings": center.y = 1.65; distance = 1.0
		"wardrobe_shirt", "wardrobe_arms", "wardrobe_necklace", "wardrobe_shoulders", "wardrobe_bracelet": center.y = 1.15; distance = 2.0
		"wardrobe_pants": center.y = 0.6; distance = 2.2
		"wardrobe_hands": center.y = 0.95; distance = 2.1
		"wardrobe_belt": center.y = 0.88; distance = 1.7
		"wardrobe_boots": center.y = 0.23; distance = 1.6
	camera.fov = 32; camera.position = center + Vector3(0.3,0.05,distance); camera.look_at(center)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not is_inside_tree(): return
	var texture := ImageTexture.create_from_image(viewport.get_texture().get_image()); cache[job.key] = texture
	cache_order.append(job.key)
	while cache_order.size() > 128: cache.erase(cache_order.pop_front())
	var target: TextureRect = job.target.get_ref()
	if is_instance_valid(target): target.texture = texture
	viewport.queue_free(); busy = false
