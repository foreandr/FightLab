extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize():call_deferred("run")
func run():
 var world=load("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var victim=world.spawn_combatant(0,Vector3.ZERO)
 var attacker=world.spawn_combatant(1,Vector3(0,0,1.5))
 victim.editor_pose_locked=true;attacker.editor_pose_locked=true
 var shield:Dictionary=Rules.author(Rules.self_barrier_base(),1.0,0.3,false);shield.shield_strength=30.0
 for element in ["None","Fire"]:
  for sample in [[0.0,0.06,3],[PI/2,0.06,2],[0.0,0.2,1]]:
   victim.self_barrier.clear();victim.parry_cast_haste.clear();victim.cleanse_burn()
   victim.rotation.y=sample[0];victim.invulnerability=0;victim.mana=50;victim.stamina=50
   attacker.mana=100;attacker.stamina=100
   victim.update_targets();attacker.update_targets()
   await physics_frame;await physics_frame
   assert(world.combat().release(victim,shield,victim.global_position))
   victim.self_barrier.age=sample[1]
   var touch:Dictionary=Rules.author(Rules.touch_base(["hand_r"],element),1.0,0.3,true)
   touch.id="touch_parry_"+element
   assert(world.combat().release(attacker,touch,attacker.bone_point("hand_r")))
   var point:Vector3=victim.bone_point("spine_03")-Vector3.UP*0.08
   var hp:float=victim.health
   # Actual swept-limb collision resolver, not a direct barrier.resolve_hit call.
   assert(preload("res://scripts/melee_contact.gd").resolve(attacker,{"id":touch.id,"clock":0.5,"begin":0.0,"end":1.0,"previous":point+Vector3.BACK*0.5,"limb":point+Vector3.FORWARD*0.1,"forward":Vector3.FORWARD,"radius":0.14,"min_speed":0.0,"dynamic_damage":false,"pre_scaled":true,"damage":touch.damage,"metadata":touch},1.0/60.0))
   var event:Dictionary=world.events.back()
   assert(event.tier==sample[2] and event.delivery_type=="Touch" and event.spell==touch.id)
   assert(victim.health==hp)
   assert(victim.get_node("BlockTierFeedback").text==["","BLOCK","PERFECT","DIRECTIONAL PERFECT"][int(sample[2])])
   if sample[2]==3:assert(victim.mana==50 and victim.stamina==50 and victim.parry_cast_haste.stacks==2)
   if sample[2]==2:assert(victim.mana==45 and victim.stamina==50 and victim.parry_cast_haste.stacks==1)
   assert((victim.burn_time>0)==(element=="Fire" and sample[2]==1))
   world.combat().discard_cast_attempt(attacker)
 print("TOUCH PARRY PASS: physical/fire swept limb hits give gold facing/timing, blue timing-only, normal block; effects blocked, refunds, zero perfect impact stamina, haste and feedback")
 quit()
