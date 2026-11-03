extends SceneTree
const Defense=preload("res://scripts/combat_defense_rules.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);var brain=w.brains[0];var a=brain.actor;var b=a.rival
 var heavy:Array[Dictionary]=[]
 for item in brain.loadout:
  if str(item.spec.id).begins_with("cpu_impact_"):heavy.append(item)
 assert(heavy.size()==5 and Defense.RAGDOLL_DAMAGE==40)
 for item in heavy:
  assert(Defense.ragdolls(float(item.spec.damage)),"Heavy choice is below body knockdown threshold: "+str(item.title))
  assert(float(item.spec.stamina_cost)>=27 and item.duration>=3.0)
  w.clear_battle_effects();w.combat().discard_cast_attempt(a);w.events.clear()
  var gap:=6.0 if item.kind=="projectile" else (0.5 if "knee" in str(item.title).to_lower() else (0.75 if "cross" in str(item.title).to_lower() else 1.0))
  a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,gap));a.rotation.y=0;b.rotation.y=PI;w.round_active=true
  a.damage_dealt=0;b.damage_taken=0
  for i in 10:
   await physics_frame
   w.tick_combat(1.0/60.0)
  b.guard_energy=0
  assert(a.start_authored_cast(item.spec,item.profile,b))
  for i in 270:
   await physics_frame
   w.tick_combat(1.0/60.0)
   if is_instance_valid(b.ragdoll):break
  assert(b.health>0 and is_instance_valid(b.ragdoll),"Real surviving-target knockdown failed: "+str(item.title))
  print("HEAVY CONTACT ",item.title," physical=",b.last_physical_impact_damage," remaining HP=",b.health)
 # Heavy melee is a risky choice when an alert opponent can defend, and a
 # useful punish when that opponent is exhausted. It is never an automatic quota.
 var item:Dictionary=heavy[2]
 b.reset_fighter(Vector3.BACK*0.75);a.reset_fighter(Vector3.ZERO)
 b.stamina=100;b.mana=100
 var alert:float=brain.melee_score(item,0.75)
 b.stamina=5;b.mana=3
 assert(brain.melee_score(item,0.75)>alert*2.0)
 print("HEAVY IMPACT PASS: two charged speed-focused projectiles and three heavy Touch strikes, actual nonlethal physical knockdowns for all five, normal threshold unchanged, resource costs and punish scoring")
 quit()
