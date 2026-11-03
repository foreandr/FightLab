extends SceneTree
var w
var a
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func settle():
 w.clear_battle_effects();w.combat().discard_cast_attempt(a)
 a.reset_fighter(Vector3(-5,0,0));w.fighters[1].reset_fighter(Vector3(5,0,0));w.round_active=true
 for i in 10:
  await physics_frame
  w.tick_combat(1.0/60.0)
 assert(a.is_on_floor())
func hop(hold:float)->Vector2:
 await settle()
 var spent:float=a.stamina_spent;var peak:=0.0;var airborne_time:=0.0;var airborne:=false
 assert(a.start_motion_jump(1.0,true))
 assert(not a.start_motion_jump(1.0,true),"Repeated takeoff charged twice")
 for i in 150:
  if a.mode!="takeoff":
   if airborne_time>=hold:a.set_motion_jump_held(false)
   airborne_time+=1.0/60.0
  await physics_frame
  w.tick_combat(1.0/60.0)
  peak=maxf(peak,a.position.y-w.ground_height(a.position))
  if not a.is_on_floor():airborne=true
  if airborne and a.is_on_floor():break
 assert(airborne and a.is_on_floor(),"Jump did not land")
 return Vector2(peak,a.stamina_spent-spent)
func dash(hold:float)->Vector2:
 await settle()
 var origin:Vector3=a.position;var spent:float=a.stamina_spent
 assert(a.start_motion_dash(2,1.0,true))
 for i in 40:
  if float(i)/60.0>=hold:a.set_motion_dash_held(false)
  await physics_frame
  w.tick_combat(1.0/60.0)
  if a.mode!="motion_dash":break
 return Vector2(origin.distance_to(a.position),a.stamina_spent-spent)
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 w=current_scene;w.set_physics_process(false);a=w.fighters[0]
 var hops:Array[Vector2]=[];var dashes:Array[Vector2]=[]
 for duration in [0.0,0.12,0.3]:
  hops.append(await hop(duration));dashes.append(await dash(duration))
 for i in [1,2]:
  assert(hops[i].x>hops[i-1].x and hops[i].y>hops[i-1].y,"Jump hold did not increase height AND stamina")
  assert(dashes[i].x>dashes[i-1].x and dashes[i].y>dashes[i-1].y,"Dash hold did not increase distance AND stamina")
 assert(is_equal_approx(hops[0].y,4.0) and is_equal_approx(hops[2].y,12.0))
 assert(is_equal_approx(dashes[0].y,4.0) and is_equal_approx(dashes[2].y,12.0))
 await settle();a.stamina=3
 assert(not a.start_motion_jump(0.0) and not a.start_motion_dash(0,0.0))
 await settle();assert(a.start_motion_dash(2,0.2));assert(is_equal_approx(a.mode_length,0.124))
 print("VARIABLE MOTION PASS: tap / medium / held jumps (height,cost) ",hops,"; dashes (distance,cost) ",dashes,"; insufficient stamina, duplicate takeoff, CPU/script fractional distance")
 quit()
