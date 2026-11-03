extends SceneTree
const Store=preload("res://scripts/ai/self_play_store.gd")
func _initialize():
 set_meta("ai_learning_path","user://logs/archive_test_%d.json"%Time.get_ticks_usec())
 call_deferred("run")
func run():
 var store=Store.new();store.path=get_meta("ai_learning_path");assert(store.load_data())
 store.data.learner={"fixture":{"move/strafe":{"q":1.0,"n":1}}}
 var early:Dictionary=store.save_snapshot("Earlier")
 assert(not early.is_empty())
 var reloaded:Dictionary=store.load_snapshot(early.path)
 assert(not reloaded.is_empty() and float(reloaded.learner.fixture["move/strafe"].q)==1.0)
 var original:=FileAccess.get_file_as_string(early.path)
 store.data.learner.fixture["move/strafe"].q=9.0
 store.data.matches=9;assert(store.save());assert(store.completed(1,0,30.0))
 assert(store.snapshots().size()==2,"No automatic ten-match snapshot")
 assert(FileAccess.get_file_as_string(early.path)==original,"Earlier model was overwritten")
 var late:Dictionary=store.save_snapshot("Later")
 var duplicate:Dictionary=store.save_snapshot("Later")
 assert(late.path!=duplicate.path and store.snapshots().size()==4,"Snapshot names collided")
 assert(float(store.load_snapshot(early.path).learner.fixture["move/strafe"].q)==1.0)
 assert(float(store.load_snapshot(late.path).learner.fixture["move/strafe"].q)==9.0)
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var world=current_scene
 world.set_physics_process(false)
 var key:=InputEventKey.new();key.keycode=KEY_M;key.pressed=true;world._unhandled_input(key)
 assert(world.model_dialog.visible and world.paused and world.model_dialog.choices.size()==2)
 world.model_dialog.hide();assert(not world.paused)
 var before:=FileAccess.get_file_as_string(store.path)
 world.show_models()
 for side in 2:
  var choice:OptionButton=world.model_dialog.choices[side]
  for i in choice.item_count:
   if choice.get_item_metadata(i)==(early.path if side==0 else late.path):choice.select(i)
 world.model_dialog.confirmed.emit()
 assert(not world.model_dialog.visible)
 assert(not world.learning_updates and not world.self_play)
 for brain in world.brains:assert(not brain.policy.learning and brain.policy.epsilon==0)
 assert(float(world.brains[0].policy.model.fixture["move/strafe"].q)==1.0)
 assert(float(world.brains[1].policy.model.fixture["move/strafe"].q)==9.0)
 var options:Array[Dictionary]=[{"action":"move/strafe","prior":1.0}]
 for brain in world.brains:
  brain.policy.begin(brain.actor,options[0],options,0.0)
 world.finish_round(0)
 assert(FileAccess.get_file_as_string(store.path)==before,"Comparison wrote into the live learner")
 assert(FileAccess.get_file_as_string(early.path)==original,"Comparison changed archived policy")
 var labels:Array=world.model_match_labels.duplicate()
 assert(not world.start_model_match("user://missing_model.json",late.path) and world.model_match_labels==labels)
 world.resume_model_learning()
 assert(world.learning_updates and world.model_match_labels.is_empty())
 for brain in world.brains:assert(brain.policy.learning)
 print("MODEL ARCHIVE PASS: immutable earlier/later versions, ten-match autosave, unique names, round-trip hashes, keyboard panel, chosen frozen opponents, comparison never writes learner, invalid-model rejection, resume learning")
 quit()
