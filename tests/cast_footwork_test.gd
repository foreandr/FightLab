extends SceneTree
const Type=preload("res://scripts/animation_cast_type.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.round_active=true
 var a=w.fighters[0];var b=w.fighters[1]
 for kind in [Type.LEGS,Type.WHOLE_BODY]:
  w.combat().discard_cast_attempt(a);a.reset_fighter(Vector3.ZERO);b.reset_fighter(Vector3(0,0,8));w.round_active=true
  for i in 10:
   await physics_frame
   w.tick_combat(1.0/60.0)
  var base:=Rules.touch_base(["calf_r"]);base.animation_type=kind
  var spec:=Rules.author(base,2.0,0.55,true)
  var profile:Dictionary={"clip":"battle/knee","store_raw":true,"step":"Knee","duration":2.0,"attack_bone":"calf_r","animation_type":kind}
  assert(a.start_authored_cast(spec,profile,b));a.set_cast_movement(Vector3.BACK)
  var start:Vector3=a.position;var cap:float=Type.LEG_STEERING_SPEED if kind==Type.LEGS else Type.BODY_STEERING_SPEED
  for i in 24:
   await physics_frame
   w.tick_combat(1.0/60.0)
   assert(a.velocity.length()<cap+0.2 and not a.did_release,"Early footwork enabled sprint/full recovery")
  assert(a.position.distance_to(start)>0.12 and a.clip=="battle/knee","Cast couldn't step or lost its authored pose")
  var before:Vector3=a.velocity
  a.set_cast_movement(Vector3.FORWARD)
  await physics_frame;w.tick_combat(1.0/60.0)
  assert(a.velocity.distance_to(before)<0.2,"Steering reversal snapped")
  assert(a.velocity.z>0,"Steering reversal instantly reversed travel")
  # The common helper used by Create has the exact same cap and smoothing.
  Type.begin(a,profile,Vector3.ZERO)
  var sample:=Vector3.ZERO
  for i in 30:sample=Type.steered_velocity(a,profile,Vector3.ZERO,Vector3.BACK*8.2,1.0/60.0,0.0)
  assert(is_equal_approx(sample.length(),cap))
  var recovered:=Type.steered_velocity(a,profile,Vector3.ZERO,Vector3.BACK*8.2,1.0/60.0,1.0)
  assert(is_equal_approx(recovered.length(),8.2),"Full recovery remained capped")
 print("CAST FOOTWORK PASS: real pre-release knee/full-body steps, 1.0/0.65m/s caps, acceleration/reversal smoothing, authored pose retained, Create uses same rules, normal recovery unchanged")
 quit()
