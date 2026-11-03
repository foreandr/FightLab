extends SceneTree
func _initialize():
 set_meta("ai_learning_enabled",false)
 call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 var w=current_scene;w.set_physics_process(false)
 assert(w.time_remaining()==120)
 w._process(0);assert(w.timer_label.text=="2:00")
 for item in [[w.hitboxes_button,KEY_2],[w.numbers_button,KEY_3]]:
  var button:Button=item[0];var initial:=button.button_pressed
  button.pressed.emit();assert(button.button_pressed!=initial)
  var key:=InputEventKey.new();key.keycode=item[1];key.pressed=true;w._unhandled_input(key)
  assert(button.button_pressed==initial,"Keyboard toggle did not update button highlight")
 assert(w.hitboxes_button.button_pressed==w.projectile_hitboxes_visible)
 assert(w.numbers_button.button_pressed==w.combat_numbers_visible)
 var a=w.fighters[0];var b=w.fighters[1]
 w.countdown=0;w.round_active=true
 a.mana=10;a.stamina=10;a.mana_delay=0;a.stamina_delay=0;a.mode="idle";a.guard_energy=0;a.guard_recovery=0
 a.recover_resources(0.5)
 assert(a.mana==27 and a.stamina==27,"Shared recovery is not 34 per second for both pools")
 assert(a.guard_energy==8.5,"Unrequested guard recovery was changed")
 a.mana=10;a.stamina=10;a.mana_delay=0;a.stamina_delay=0
 a.recover_idle_resources(0.5);assert(a.mana==27 and a.stamina==27,"Editor/idle route uses different recovery")
 a.mana_delay=0.5;a.stamina_delay=0.5;a.recover_resources(0.1)
 assert(a.mana==27 and a.stamina==27,"Recovery delay was bypassed")
 w.elapsed=115;a.health=80;b.health=70
 var policy=preload("res://scripts/ai/adaptive_policy.gd").new()
 var ahead:String=policy.state(a);a.health=60;var behind:String=policy.state(a)
 assert(ahead.begins_with("end1|") and behind.begins_with("end-1|") and ahead!=behind)
 a.health=80
 b.global_position=a.global_position+Vector3.BACK
 var decision_brain=w.brains[0];decision_brain.policy=policy;policy.configure({},7,false,0)
 var strikes:Array[Dictionary]=[decision_brain.loadout[1]];var scores:Array[float]=[5.0]
 assert(decision_brain.adaptive_decision(1.0,strikes,scores) and a.mode=="retreat","Ahead AI cannot prefer protecting its lead")
 a.health=60
 assert(decision_brain.adaptive_decision(1.0,strikes,scores) and a.mode=="cast","Behind AI cannot prefer attacking the deficit")
 a.health=80
 w.elapsed=119.95
 for brain in w.brains:brain.think_left=99
 w.paused=true;w._physics_process(0.1);assert(w.elapsed==119.95)
 w.paused=false;w._physics_process(0.1)
 assert(w.match_winner==0 and w.finish_reason=="timeout" and is_equal_approx(w.finished_at,120.0))
 assert(a.health>0 and b.health>0,"Timeout killed the loser")
 w._process(0);assert(w.timer_label.text=="0:00")
 w.rematch(17);w.set_physics_process(false);w.countdown=0;w.round_active=true;w.elapsed=119.99
 for brain in w.brains:brain.think_left=99
 for actor in w.fighters:actor.health=70
 w._physics_process(0.1)
 assert(w.match_winner==-1 and w.finish_reason=="timeout","Equal-health expiry should draw")
 w.rematch(19);w.set_physics_process(false);assert(w.time_remaining()==120 and w.finish_reason.is_empty())
 print("MATCH CLOCK PASS: 120s countdown, pause, exact timeout, higher HP wins, equal HP draw, rematch, final-ten-second lead awareness; shared 34/s recovery and unchanged delays/guard; click/key toggle highlights")
 quit()
