extends SceneTree
const Clash=preload("res://scripts/melee_clash.gd")
func _initialize():set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 # Sweeps must meet at the same instant, not just cross the same space.
 assert(Clash.contact_time(Vector3(-1,0,0),Vector3(1,0,0),0.1,Vector3(1,0,0),Vector3(-1,0,0),0.1)>0)
 assert(Clash.contact_time(Vector3(-1,0,0),Vector3(1,0,0),0.1,Vector3(-1,1,0),Vector3(1,1,0),0.1)<0)
 assert(Clash.contact_time(Vector3(-1,0,0),Vector3(1,0,0),0.01,Vector3(0,-2,0),Vector3(0,0,0),0.01)<0)
 assert(Clash.contact_time(Vector3(-10,0,0),Vector3(10,0,0),0.1,Vector3(10,0,0),Vector3(-10,0,0),0.1)>0)
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);var a=w.fighters[0];var b=w.fighters[1]
 var found:=false
 for gap in [0.8,1.1,1.4]:
  for offset in [-0.2,0.0,0.2]:
   w.clear_battle_effects();w.combat().discard_cast_attempt(a);w.combat().discard_cast_attempt(b)
   a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(offset,0,gap));a.rotation.y=0;b.rotation.y=PI;w.round_active=true;w.events.clear()
   for i in 5:await physics_frame;w.tick_combat(1.0/60)
   a.guard_energy=0;b.guard_energy=0
   var left:Dictionary=w.brains[0].loadout[1];var right:Dictionary=w.brains[1].loadout[4]
   a.start_authored_cast(left.spec,left.profile,b);b.start_authored_cast(right.spec,right.profile,a)
   for i in 60:
    await physics_frame;w.tick_combat(1.0/60)
    for event in w.events:
     if event.event=="melee_clash":
      print("REAL CLASH gap=",gap," offset=",offset," hp=",a.health,"/",b.health," modes=",a.mode,"/",b.mode," ",event)
      assert(a.health==a.MAX_HEALTH and b.health==b.MAX_HEALTH and a.mode=="cast" and b.mode=="cast")
      assert(event.a_stamina==2 and event.b_stamina==2 and a.touch_parry_recovery==0 and b.touch_parry_recovery==0)
      var count:int=w.events.filter(func(e):return e.event=="melee_clash").size()
      Clash.resolve(w.combat(),1.0/60)
      assert(w.events.filter(func(e):return e.event=="melee_clash").size()==count,"Clash charged twice")
      found=true;break
    if found:break
   if found:break
  if found:break
 assert(found,"No actual simultaneous jab/cross produced a geometric clash")
 print("MELEE CLASH REAL PASS")
 quit()
