extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false);w.training_view=false;w.rematch(812);w.set_physics_process(false)
 var label=preload("res://scripts/round_countdown_label.gd").new();root.add_child(label)
 for i in 3:
  label.display(w.countdown,w.begin_flash);assert(label.text==str(3-i))
  for frame in 60:w._physics_process(1.0/60.0)
 assert(w.round_active and w.elapsed==0 and w.begin_flash>0)
 label.display(w.countdown,w.begin_flash);assert(label.text=="BEGIN")
 assert(w.casts.is_empty() and w.fighters[0].stamina==100 and w.time_remaining()==120)
 w.rematch(813);w.set_physics_process(false);w.paused=true;w._physics_process(1.0);assert(w.countdown==3)
 w.paused=false;Engine.time_scale=0.5
 w._physics_process(0.5);assert(is_equal_approx(w.countdown,2.0),"Slowmo changed real countdown duration")
 Engine.time_scale=1.0
 w.rematch(814);w.set_physics_process(false);assert(w.countdown==3 and w.begin_flash==0)
 label.display(0,0);assert(not label.visible)
 print("COUNTDOWN PASS: 3/2/1/BEGIN, no premature action/resources/match time, pause, slowmo wall time, rematch reset")
 quit()
