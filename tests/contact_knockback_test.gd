extends SceneTree
const Rules=preload("res://scripts/combat_defense_rules.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.round_active=true
 var a=w.fighters[0];var b=w.fighters[1]
 var impulse:=Vector3.BACK*120.0
 assert(Rules.contact_body_impulse({"effect":"touch"},10,impulse).length()==24.0)
 for spec in [{"effect":"projectile"},{"effect":"touch","launch":true},{"effect":"touch","charge":1.0}]:
  assert(Rules.contact_body_impulse(spec,10,impulse)==impulse)
 assert(Rules.contact_body_impulse({"effect":"touch"},40,impulse)==impulse)
 a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,0.75));a.rotation.y=0;b.rotation.y=PI
 for i in 10:
  await physics_frame
  w.tick_combat(1.0/60.0)
 b.guard_energy=0
 var brain=w.brains[0];var kick:Dictionary=brain.loadout[7];var punch:Dictionary=brain.loadout[1]
 assert(a.start_authored_cast(kick.spec,kick.profile,b))
 var linked:=false;var first_damage:=0.0
 for i in 140:
  await physics_frame
  w.tick_combat(1.0/60.0)
  if not linked and b.damage_taken>0 and a.mode=="cast" and a.cast_time>=a.mode_length*0.58:
   first_damage=b.damage_taken
   assert(a.flat_distance()<1.0,"Ordinary kick shoved victim outside punching distance")
   linked=a.chain_touch_cast(punch.spec,punch.profile)
  if linked and b.damage_taken>first_damage+0.1:break
 assert(linked and b.damage_taken>first_damage+0.1,"Real kick into punch did not connect")
 print("CONTACT KNOCKBACK PASS: real kick -> punch connects without repositioning; small body push, full pose impact, projectile/launch/heavy exceptions retained")
 quit()
