extends SceneTree
func _initialize():
 set_meta("ai_learning_path","user://logs/ai_ui_%d.json"%Time.get_ticks_usec())
 call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var demo=current_scene
 assert(demo.learning_enabled and demo.brains[0].policy!=null)
 var frozen:Dictionary={"fixture":{"move/strafe":{"q":1.0,"n":1}}}
 demo.policy_overrides=[demo.learning_store.data.learner,frozen]
 demo.policy_training_flags=[true,false];demo.rematch(317)
 assert(demo.brains[0].policy.learning and not demo.brains[1].policy.learning)
 assert(demo.hud.find_children("*","Label",true,false).is_empty(),"Removed top commentary panel still exists")
 assert(demo.hud.find_children("*","ProgressBar",true,false).is_empty())
 var action:Dictionary={"action":"move/strafe","prior":0.5}
 var options:Array[Dictionary]=[action]
 demo.brains[0].policy.begin(demo.fighters[0],action,options,0)
 demo.self_play_button.pressed.emit()
 assert(demo.self_play)
 demo.finish_round(0)
 assert(int(demo.learning_store.data.matches)==1 and int(demo.learning_store.data.updates)>0)
 assert(frozen=={"fixture":{"move/strafe":{"q":1.0,"n":1}}},"Historical opponent was trained in place")
 var saved_path:String=demo.learning_store.path
 demo._physics_process(2.1)
 assert(demo.match_winner==-2 and int(demo.learning_store.data.matches)==1 and demo.self_play)
 var store=preload("res://scripts/ai/self_play_store.gd").new();store.path=saved_path
 assert(store.load_data() and int(store.data.matches)==1 and not store.data.learner.is_empty())
 demo.toggle_self_play();assert(not demo.self_play)
 print("AI SELF PLAY UI PASS: no top commentary or bars, learning enabled, completed match saved, automatic rematch, policy retained/reloaded, stop toggle")
 quit()
