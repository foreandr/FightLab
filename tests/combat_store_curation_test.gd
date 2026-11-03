extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/animation_store.tscn");await process_frame;await process_frame
 var store=current_scene
 var deadline:=Time.get_ticks_msec()+60000
 while not store.store_screen_ready:
  assert(Time.get_ticks_msec()<deadline,"Store did not open")
  await process_frame
 var policy=preload("res://scripts/combat_animation_filter.gd").new()
 assert(store.store_index_records.size()>100 and store.store_index_records.size()<1000)
 var new_clips:=0
 for entry in store.store_index_records:
  assert(not str(entry.get("source_name","")).to_lower().contains("mocapdata"),"Rejected provider remains")
  assert(policy.accepts(entry),"Irrelevant entry remains: "+str(entry.title))
  if entry.source_name=="Motifect Martial Arts":new_clips+=1
 assert(new_clips==38,"New combat clips missing from the shared Store")
 for entry in store.animation_store_entries:
  assert(entry.has("path") or store.store_library.taken.has(store.StoreLibrary.key(entry)) or policy.accepts(entry))
 assert(store.animation_store_list.get_child_count()<=20,"Store pagination changed")
 print("CURATED STORE PASS: ",store.store_index_records.size()," local combat/movement records, 38 new clips, owned/custom preserved, 20-row pages")
 quit()
