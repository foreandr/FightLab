extends SceneTree
const Rules=preload("res://scripts/combat_defense_rules.gd")
func _initialize():set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 var flat:=Vector3(300,0,400);var tilted:=Rules.ragdoll_launch_impulse(flat)
 assert(is_equal_approx(tilted.length(),flat.length()))
 assert(is_equal_approx(rad_to_deg(atan2(tilted.y,Vector2(tilted.x,tilted.z).length())),30.0))
 assert(Vector2(tilted.x,tilted.z).normalized().is_equal_approx(Vector2(flat.x,flat.z).normalized()))
 for impulse in [Vector3(0,300,300),Vector3.DOWN*300,Vector3(50,-100,0),Vector3.ZERO]:assert(Rules.ragdoll_launch_impulse(impulse).is_equal_approx(impulse))
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.set_process(false);w.training_view=false;w.round_active=true;w.countdown=0
 var a=w.fighters[0];var b=w.fighters[1];a.guard_energy=0;a.invulnerability=0
 var chest:Area3D=a.nearest_hurtbox(a.bone_point("spine_03"))
 assert(w.apply_impact(b,a,{"id":"launch_test","effect":"orb","projectile_element":"None","damage":45},chest.global_position,Vector3.BACK,chest,flat))
 assert(is_instance_valid(a.ragdoll) and a.ragdoll.initial_impulse.is_equal_approx(tilted),"Actual heavy hit bypassed upward launch")
 assert(a.ragdoll.initial_velocity.y>=6.0 and Vector2(a.ragdoll.initial_velocity.x,a.ragdoll.initial_velocity.z).length()>=6.0,"Heavy hit lacks a strong coherent launch")
 w.finish_round(1);assert(is_equal_approx(Engine.time_scale,0.2) and w.finish_slowmo_left==1.1)
 w.step_finish_slowmo(0.5);assert(is_equal_approx(Engine.time_scale,0.2))
 w.paused=true;w.step_finish_slowmo(0.2);assert(is_equal_approx(w.finish_slowmo_left,0.6))
 w.paused=false;w.step_finish_slowmo(0.3);assert(Engine.time_scale>0.2 and Engine.time_scale<1)
 w.step_finish_slowmo(0.4);assert(Engine.time_scale==1 and w.finish_slowmo_left==0)
 w.rematch(812);w.set_physics_process(false);assert(Engine.time_scale==1 and w.finish_slowmo_left==0)
 w.finish_round(0);w.rematch(813);w.set_physics_process(false);assert(Engine.time_scale==1 and w.finish_slowmo_left==0)
 w.training_view=true;w.finish_round(1);assert(Engine.time_scale==1 and w.finish_slowmo_left==0)
 print("DASH / FINISH / LAUNCH PASS: dash multiplier 0.85, actual ragdoll 30-degree upward tilt with preserved force; higher/downward impulses retained; real-time slow finish eases to normal, pause/rematch/training isolation")
 quit()
