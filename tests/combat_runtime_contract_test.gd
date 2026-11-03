extends SceneTree
const Burn=preload("res://scripts/burn_rules.gd")
## A new mode with no Create/Story scene inherits the actual combat pipeline.
const Rules=preload("res://scripts/combat_spell_rules.gd")
const Pose=preload("res://scripts/spell_cast_motion.gd")
const World=preload("res://scripts/combat_world.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("COMBAT RUNTIME CONTRACT FAILED: "+message)
	quit(1)
	return false

func run() -> void:
	var world=World.new()
	world.name="EntirelyNewMode"
	root.add_child(world)
	world.set_physics_process(false)
	var floor_body:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(30,0.2,30)
	collision.shape=box
	floor_body.position.y=-0.1
	floor_body.add_child(collision)
	world.add_child(floor_body)
	var actor:CharacterBody3D=world.spawn_combatant(0,Vector3.ZERO)
	var target:CharacterBody3D=world.spawn_combatant(1,Vector3(0,0,4))
	actor.brain_enabled=false;target.brain_enabled=false
	actor.editor_pose_locked=true;target.editor_pose_locked=true
	target.practice_god_mode=true
	actor.invulnerability=0.0;target.invulnerability=0.0
	world.round_active=true
	actor.update_targets();target.update_targets()
	await physics_frame
	await physics_frame
	var base:=Rules.allocate(preload("res://scripts/basic_projectile.gd").spec("None",0.16),{"size":0.5,"speed":0.5},"None",1.0)
	base.mana=10.0;base.mana_percent=10.0
	var absolute_cost:=base.duplicate(true)
	absolute_cost.erase("mana_percent")
	if not check(is_equal_approx(Rules.mana_cost(Rules.author(absolute_cost,1.0,0.3,true)),10.0*pow(2.0,0.7)),"Authoring replaced an absolute mana cost with zero percent"):return
	var spec:=Rules.author(base,1.0,0.3,true)
	if not check(is_equal_approx(float(Rules.neutral_projectile().damage),10.0),"Reusable default factory lost the neutral benchmark"):return
	spec.aim_direction=(target.bone_point("spine_03")-actor.bone_point("hand_r")).normalized()
	var snapshot:=spec.duplicate(true)
	actor.stamina=9;actor.mana=100
	if not check(not world.combat().release(actor,spec,actor.bone_point("hand_r")) and actor.stamina==9 and actor.mana==100 and world.shots.is_empty(),"Failed cast spent resources or spawned a shot"):return
	actor.stamina=100
	var before:float=target.damage_taken
	if not check(world.combat().release(actor,spec,actor.bone_point("hand_r")) and is_equal_approx(actor.mana,100.0-Rules.mana_cost(spec)) and actor.stamina==90,"Independent mode did not pay its authored release-time cost"):return
	for frame in 100:
		world.step_shots(1.0/60.0)
		if world.shots.is_empty():break
	if not check(is_equal_approx(target.damage_taken-before,10.0),"Independent mode's actual unblocked projectile did not deal 10"):return
	if not check(spec==snapshot,"Execution mutated the authored spell"):return
	actor.mana=90;actor.stamina=90
	actor.mana_delay=0.5;actor.stamina_delay=0.5
	actor.recover_idle_resources(0.25)
	if not check(actor.mana==90 and actor.stamina==90,"Resource recovery ignored the shared delay"):return
	actor.recover_idle_resources(0.5)
	if not check(actor.mana==actor.stamina and actor.mana>90,"Resource pools recovered differently in the new mode"):return
	var fire:=spec.duplicate(true)
	fire.projectile_element="Fire";fire.potency=2.0
	world.story_mode=true
	target.receive_status(actor,fire)
	if not check(target.burn_time==5.0 and is_equal_approx(target.burn_damage,2.0*Burn.TICK_DAMAGE),"Explicit elemental spells lost their effect in Story"):return
	world.story_mode=false
	Pose.pose(actor,{"store_raw":true,"clip":"duel/run"},0.1)
	var first:=Pose.capture(actor)
	Pose.pose(actor,{"store_raw":true,"clip":"duel/run"},0.65)
	var second:=Pose.capture(actor)
	var changed:=false
	for index in first.size():
		if not first[index].is_equal_approx(second[index]):changed=true;break
	if not check(changed,"Independent mode sampled a static animation"):return
	Pose.blend_from(actor,first,0.0)
	var restored:=Pose.capture(actor)
	for index in first.size():
		if not check(first[index].is_equal_approx(restored[index]),"Shared animation transition did not restore its captured pose"):return
	target.invulnerability=0.0
	target.update_targets()
	await physics_frame
	var point:Vector3=target.bone_point("spine_03")
	var strike:Dictionary={"id":"new_mode_punch","clock":0.5,"begin":0.0,"end":1.0,"previous":point-Vector3.BACK*0.12,"limb":point+Vector3.BACK*0.12,"forward":Vector3.BACK,"damage":10.0,"dynamic_damage":false}
	before=target.damage_taken
	strike.connected=preload("res://scripts/melee_contact.gd").resolve(actor,strike,1.0/60.0)
	if not check(strike.connected and is_equal_approx(target.damage_taken-before,10.0),"Shared swept melee contact failed in the independent mode"):return
	preload("res://scripts/melee_contact.gd").resolve(actor,strike,1.0/60.0)
	if not check(is_equal_approx(target.damage_taken-before,10.0),"One melee contact was counted twice"):return
	actor.health=100
	world.combat().dispatch(actor,{"id":"heal","effect":"heal","heal_amount":15.0},actor.global_position)
	if not check(actor.health==115,"Shared heal dispatch failed"):return
	world.combat().dispatch(actor,{"id":"armor","effect":"armor"},actor.global_position)
	world.combat().dispatch(actor,{"id":"haste","effect":"haste"},actor.global_position)
	if not check(actor.armor_hp==0 and actor.haste_time==14,"Cosmetic armor or shared haste dispatch failed"):return
	actor.editor_pose_locked=false;target.editor_pose_locked=false
	actor.mode="idle";target.mode="idle"
	for frame in 5:world.tick_combat(1.0/60.0)
	# The same timed self barrier must work without a Create or Story host.
	target.invulnerability=0.0;target.cleanse_burn()
	world.combat().dispatch(target,{"effect":"self_barrier","shield_strength":25.0,"shield_duration":0.5},target.global_position)
	var barrier_hp:float=target.health
	if not check(world.combat().apply_impact(actor,target,{"effect":"orb","damage":10.0},target.bone_point("spine_03"),Vector3.BACK),"Independent mode barrier contact failed"):return
	if not check(target.health==barrier_hp and is_equal_approx(target.self_barrier.remaining,15.0),"Independent mode barrier did not absorb damage"):return
	target.update_status(0.51)
	if not check(not target.self_barrier.active(),"Independent mode barrier failed to expire"):return
	actor.practice_god_mode=true
	var raw:=spec.duplicate(true)
	raw.mana=1000;raw.mana_percent=1000;raw.stamina_cost=1000
	if not check(world.combat().authorize_cast(actor,raw) and actor.mana==100 and actor.stamina==100,"God mode is not honored by the new-mode cast path"):return
	print("COMBAT RUNTIME CONTRACT PASSED: independent mode, real 10/10/10 hit, release-time mana, atomic failure, immutable spell, shared recovery, Story elemental effect, moving animation and transitions, God mode")
	quit()
