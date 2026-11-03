extends SceneTree
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func area_for(actor:Node,zone:String)->Area3D:
 for pair in actor.targets+actor.limb_targets:
  if str(pair[0].get_meta("zone",""))==zone:return pair[0]
 return null
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var world=current_scene
 await create_timer(0.2).timeout
 world.set_physics_process(false);world.round_active=true
 var attacker=world.fighters[0];var victim=world.fighters[1]
 var durations:Array[float]=[]
 for example in [["chest",10.0],["head",10.0],["chest",30.0]]:
  victim.reset_fighter(victim.position);victim.guard_energy=0;victim.invulnerability=0
  var area:=area_for(victim,str(example[0]));assert(area!=null)
  var before:float=victim.health
  assert(world.apply_impact(attacker,victim,{"id":"recovery_test","effect":"touch","projectile_element":"None","damage":example[1]},area.global_position,Vector3.BACK,area,Vector3.BACK*20))
  assert(victim.mode=="hit" and victim.combat_reaction_active())
  var duration:float=victim.mode_length;durations.append(duration)
  assert(duration<0.27 and victim.clip==preload("res://scripts/combat_hit_regions.gd").reaction(str(example[0])))
  assert(is_equal_approx(before-victim.health,float(example[1])*(2.0 if example[0]=="head" else 1.0)))
  victim.tick(duration+0.005)
  assert(not victim.combat_reaction_active(),"Finished flinch still prevents counter action")
  var attack:Dictionary=preload("res://scripts/cpu_duel_loadout.gd").build()[1]
  assert(victim.start_authored_cast(attack.spec,attack.profile),"Could not counter immediately after flinch")
 assert(durations[0]<0.18 and durations[1]>durations[0] and durations[2]>durations[0])
 victim.reset_fighter(victim.position);victim.guard_energy=0;victim.invulnerability=0
 var chest:=area_for(victim,"chest")
 world.apply_impact(attacker,victim,{"id":"heavy_test","effect":"touch","projectile_element":"None","damage":40.0},chest.global_position,Vector3.BACK,chest,Vector3.BACK*300)
 assert(is_instance_valid(victim.ragdoll),"Shorter flinch removed heavy-hit ragdoll")
 victim.reset_fighter(victim.position);victim.stun_time=0.5
 victim.tick(0.2)
 assert(victim.combat_reaction_active() and victim.stun_time>0,"Physical tuning shortened explicit spell stun")
 print("HIT RECOVERY PASS: body/head/heavier flinches ",durations,"; real immediate counter casts, unchanged damage/clips, heavy ragdoll and explicit stun retained")
 quit()
