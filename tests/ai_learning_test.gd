extends SceneTree
const Policy=preload("res://scripts/ai/adaptive_policy.gd")
const Store=preload("res://scripts/ai/self_play_store.gd")
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame;await process_frame
 var actor=current_scene.fighters[0]
 var policy=Policy.new();var table:Dictionary={};policy.configure(table,42,true,0)
 var options:Array[Dictionary]=[{"action":"bad","prior":0.0},{"action":"good","prior":0.0}]
 policy.begin(actor,options[0],options,0.0)
 actor.damage_taken+=30
 policy.finish(actor,1,1.0)
 assert(policy.pick(actor,options).action=="good","Losing did not change the next choice")
 policy.begin(actor,options[1],options,2.0)
 actor.damage_dealt+=40
 policy.finish(actor,0,3.0)
 assert(policy.value(policy.state(actor),"good",0)>policy.value(policy.state(actor),"bad",0))
 assert(policy.pick(actor,[options[0]]).action=="bad","Chose an unavailable action")
 var frozen:=JSON.stringify(table)
 var evaluation=Policy.new();evaluation.configure(table,9,false,1.0)
 evaluation.begin(actor,options[0],options,4.0);evaluation.finish(actor,1,5.0)
 assert(JSON.stringify(table)==frozen and evaluation.updates==0 and evaluation.epsilon==0)
 var store=Store.new();store.path="user://logs/ai_unit_%d.json"%Time.get_ticks_usec()
 assert(store.load_data());store.data.learner=table
 assert(store.completed(policy.updates,0,3.0));assert(store.completed(0,1,4.0))
 var loaded=Store.new();loaded.path=store.path
 assert(loaded.load_data() and int(loaded.data.matches)==2)
 for context in table:
  for action in table[context]:
   assert(is_equal_approx(float(loaded.data.learner[context][action].q),float(table[context][action].q)))
   assert(int(loaded.data.learner[context][action].n)==int(table[context][action].n))
 var stale=Store.new();stale.path=store.path;assert(stale.load_data())
 var generation:int=loaded.data.generation
 assert(loaded.evaluate(table,2.0,2,2,2) and int(loaded.data.generation)==generation,"Promoted without enough evaluation games")
 assert(loaded.evaluate(table,18.0,20,9,10) and int(loaded.data.generation)==generation+1)
 assert(loaded.data.champion==table)
 assert(not stale.save() and not stale.last_save_error.is_empty(),"Stale writer overwrote a newer checkpoint")
 var candidate=table.duplicate(true);candidate["new"]={"bad":{"q":-1.0,"n":1}}
 assert(loaded.evaluate(candidate,4.0,20,1,10) and loaded.data.champion==table,"Weaker candidate replaced champion")
 var broken:=FileAccess.open(store.path,FileAccess.WRITE);broken.store_string("{");broken.close()
 var recovery=Store.new();recovery.path=store.path
 assert(recovery.load_data() and int(recovery.data.matches)==2,"Backup recovery failed")
 var future=Store.new();future.path=store.path+".future"
 var file:=FileAccess.open(future.path,FileAccess.WRITE);file.store_string("{\"format\":999}");file.close()
 assert(not future.load_data() and not future.save() and FileAccess.get_file_as_string(future.path)=="{\"format\":999}")
 print("AI LEARNING PASS: loss/win changes choices, legal masks, frozen evaluation, save/reload, backup recovery, incompatible-file preservation, evidence-gated champion promotion")
 quit()
