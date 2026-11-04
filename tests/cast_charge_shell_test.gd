extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 var world=load("res://scripts/spell_creation_world.gd").new();root.add_child(world);world.set_physics_process(false)
 var actor=world.spawn_combatant(0,Vector3.ZERO,load("res://scripts/creation_bot_outfit.gd").profile(0))
 actor.editor_pose_locked=true
 var feedback=load("res://scripts/cast_charge_feedback.gd").new();actor.add_child(feedback);feedback.setup(actor)
 assert(not feedback.overlays.is_empty())
 assert(feedback.overlays==load("res://scripts/body_barrier_overlay.gd").apply(actor.skeleton),"Charge duplicated the shared barrier shell")
 feedback.begin("hand_l")
 var last:=0.0
 for progress in [0.34,0.67,1.0]:
  feedback.progress(progress);feedback.pulse=0.0;feedback.refresh()
  var strength:float=feedback.overlays[0].get_shader_parameter("barrier_strength")
  assert(strength>last);last=strength
  assert(not actor.self_barrier.active(),"Visual charge granted shielding")
 actor.self_barrier.activate(actor,10.0,1.0)
 feedback.finish();feedback._process(0.3)
 assert(is_zero_approx(feedback.fade))
 assert(actor.self_barrier.active() and is_equal_approx(float(feedback.overlays[0].get_shader_parameter("barrier_strength")),1.0),"Charge ending erased a real shield")
 actor.self_barrier.clear()
 assert(is_zero_approx(float(feedback.overlays[0].get_shader_parameter("barrier_strength"))))
 print("CHARGE SHELL PASS: shared whole-body barrier visual, increasing tiers, no shield granted, release preserves real shields, clean fade")
 quit()
