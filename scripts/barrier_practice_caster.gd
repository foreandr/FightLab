extends Node
## Practice-scene adapter: cadence/placement only; actor/runtime own the cast.
const INTERVAL:=4.0
var builder:Control
var unit:CharacterBody3D
var enabled:=false
var clock:=0.0
var casts_started:=0
var melee_only:=false
var paused:=false
func configure(owner_builder:Control,punch_only:=false)->void:
	builder=owner_builder
	melee_only=punch_only
	var field=builder.editor.field
	unit=field.spawn_combatant(1,Vector3.ZERO,preload("res://scripts/creation_bot_outfit.gd").profile(1))
	unit.name="BarrierTestPuncher" if melee_only else "BarrierTestCaster"
	unit.set_meta("barrier_test_caster",true)
	unit.brain_enabled=false;unit.practice_return_enabled=true;unit.editor_pose_locked=false
	unit.practice_face_rival=true
	unit.practice_damageable_dummy=true
	preload("res://scripts/fighter_overhead_tag.gd").attach(unit,"Punch tester" if melee_only else "Projectile tester")
	for profile in preload("res://scripts/animation_catalog.gd").entries():
		if profile.title=="Left jab":unit.practice_spell_animation=profile.duplicate(true);break
	unit.practice_spell_animation["duration"]=1.0
	unit.practice_release_fraction=0.5
	var rules=preload("res://scripts/combat_spell_rules.gd")
	var base:Dictionary=rules.allocate(rules.projectile_base("Fire"),{"size":0.4,"speed":0.4,"effect":0.2},"Fire",1.0)
	unit.practice_projectile_spec=rules.author(base,1.0,0.5,true)
	unit.practice_projectile_spec["id"]="barrier_test_fireball"
	unit.practice_projectile_spec["animation"]="palm_fireball"
	unit.practice_projectile_spec["hand"]="hand_l"
	reset()
func wanted()->bool:
	return is_instance_valid(builder) and builder.is_visible_in_tree() and builder.demo_choice_selected and builder.creation_step=="shield" and builder.spell_delivery_type()=="Barrier"
func reset()->void:
	clock=0.0
	set_paused(false)
	if not is_instance_valid(unit):return
	var home:Vector3=builder.editor.actor.global_position+builder.editor.actor.global_basis.z*1.25 if melee_only else builder.editor.target.practice_home-builder.editor.target.global_basis.x*3.0
	unit.practice_home=builder.editor.field.surface_placement(home)
	unit.global_position=unit.practice_home;unit.velocity=Vector3.ZERO
	unit.rival=builder.editor.actor
	var toward:Vector3=unit.rival.global_position-unit.global_position
	unit.rotation.y=atan2(toward.x,toward.z)
	unit.editor_pose_locked=false;unit.brain_enabled=false;unit.practice_return_enabled=true
	unit.mode="review"
	set_enabled(wanted())
func set_enabled(value:bool)->void:
	if not is_instance_valid(unit):return
	if enabled==value and unit.visible==value:return
	if enabled!=value:
		clock=0.0
		if not value:
			builder.editor.field.combat().interrupt_cast_attempt(unit)
			builder.editor.field.combat().finish_cast(unit)
			unit.mode="review"
	enabled=value;unit.visible=value
	unit.collision_layer=(128<<unit.team) if value else 0
	for item in unit.targets:item[0].collision_layer=(8<<unit.team) if value else 0
	for item in unit.limb_targets:item[0].collision_layer=(8<<unit.team) if value else 0
func set_paused(value:bool)->void:
	paused=value
	if is_instance_valid(unit):unit.set_practice_paused(value)
func _physics_process(delta:float)->void:
	set_enabled(wanted())
	if not enabled or paused or unit.health<=0.0:return
	var target=builder.editor.actor
	if not is_instance_valid(target) or target.health<=0.0:return
	unit.rival=target
	# Supply ordinary aim input from the actual left-hand emitter, not the pelvis.
	var origin:Vector3=builder.editor.field.fighter_hand(unit,"hand_l")
	var direction:Vector3=(target.bone_point("spine_03")-origin).normalized()
	unit.practice_projectile_spec["aim_direction"]=direction
	if unit.mode=="cast":unit.current_spell["aim_direction"]=direction
	clock+=delta
	if clock<INTERVAL:return
	clock=fmod(clock,INTERVAL)
	if melee_only:
		unit.start_left_jab()
	else:unit.start_cast(false)
	if unit.mode in ["cast","punch"]:casts_started+=1
