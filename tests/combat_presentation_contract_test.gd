extends SceneTree
const StatusVisual=preload("res://scripts/character_status_visual.gd")
func _initialize() -> void:call_deferred("run")
func verify(world:Node,actor:CharacterBody3D) -> void:
	world.set_process(false);world.set_physics_process(false)
	actor.brain_enabled=false
	actor.status_visual.set_process(false)
	assert(actor.status_visual.get_script()==StatusVisual)
	for flags in [[false,false],[true,false],[false,true],[true,true]]:
		world.story_mode=flags[0];world.editor_animation_only=flags[1]
		world.round_active=true
		actor.health=100
		actor.freeze_time=1;actor.chill_time=1;actor.stun_time=1;actor.haste_time=1;actor.burn_time=2
		actor.update_status(0.0)
		world.vfx.clear()
		actor.status_visual.pulse_clock=0
		actor.status_visual._process(0.15)
		actor.status_visual.frozen.step()
		assert(world.vfx.motes.size()==3,"Mode flags changed status particle emission")
		assert(actor.status_visual.frozen.visible and actor.status_visual.frozen.pieces.size()==6)
		assert(actor.burn_visual.anchors.size()==6)
		actor.reset_fighter(actor.position)
		assert(actor.burn_visual==null and not actor.status_visual.frozen.visible)
	world.vfx.clear()

func verify_lifetime(world:Node) -> void:
	world.vfx.puff(Vector3.UP,"smoke_04",0,Vector2.ONE,Vector3.UP,0.04)
	assert(world.vfx.motes.size()==1)
	await create_timer(0.15).timeout
	assert(world.vfx.motes.is_empty(),"Effect lifetime depends on a mode calling vfx.step")

func run() -> void:
	# A new mode with no Story/Create scene must receive the same components.
	var bare=preload("res://scripts/combat_world.gd").new()
	root.add_child(bare)
	verify(bare,bare.spawn_combatant(0,Vector3.ZERO))
	await verify_lifetime(bare)
	bare.queue_free()
	await process_frame
	# Exercise the real Story host, not a second implementation of its behavior.
	change_scene_to_file("res://scenes/fight.tscn")
	await process_frame;await process_frame
	verify(current_scene,current_scene.fighters[0])
	await verify_lifetime(current_scene)
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while current_scene==null or not bool(current_scene.get("default_unit_ready")) or is_instance_valid(current_scene.get("loading_layer")):await process_frame
	current_scene.set_process(false);current_scene.set_physics_process(false)
	current_scene.select_group("Spells")
	verify(current_scene.field,current_scene.actor)
	await verify_lifetime(current_scene.field)
	# Guard the ownership boundary against restoring a mode-specific status loop.
	var mode_source:=FileAccess.get_file_as_string("res://scripts/battle_arena.gd").get_slice("func _physics_process",1).get_slice("func finish_run",0)
	for branch in ["if f.burn_time","if f.stun_time","if f.chill_time","if f.haste_time"]:assert(not branch in mode_source)
	var shared_source:=FileAccess.get_file_as_string("res://scripts/character_status_visual.gd")
	assert(not "story_mode" in shared_source and not "editor_animation_only" in shared_source)
	for path in ["battle_arena.gd","duel_arena.gd"]:assert(not "vfx.step(" in FileAccess.get_file_as_string("res://scripts/"+path))
	print("COMBAT PRESENTATION CONTRACT PASSED: actual Story/Create and bare new mode, identical actor component, 4 flag combinations, burn/frost/stun/chill/haste, reset and ownership guards")
	quit()
