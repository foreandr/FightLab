extends SceneTree
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 change_scene_to_file("res://scenes/animation_store.tscn")
 while current_scene==null or not current_scene.store_screen_ready:await process_frame
 var store=current_scene
 store.animation_store_search.set_block_signals(true);store.animation_store_search.text=""
 store.store_body_filter.select(0);store.store_creator_filter.select(0);store.store_air_filter.select(0);store.store_view_filter.select(0)
 await store._populate_animation_store()
 var first:Dictionary=store.animation_store_list.get_child(0).get_child(0).entry
 var first_id:String=store.StoreLibrary.key(first)
 var before:Dictionary=store.get_meta("store_page_timing").duplicate()
 store.store_page=1;await store._populate_animation_store()
 var page:Dictionary=store.get_meta("store_page_timing").duplicate()
 if not check(page.cache_hit and page.total_ms<1500,"Page turn did a full slow catalog query: "+str(page)):return
 if not check(store.StoreLibrary.key(store.animation_store_list.get_child(0).get_child(0).entry)!=first_id,"Page turn repeated first page"):return
 # Account mutations must invalidate matching lists without changing persisted data.
 store.store_library.blocked[first_id]=true
 await store._populate_animation_store()
 if not check(not store.get_meta("store_page_timing").cache_hit,"Blocking reused stale matches"):return
 store.store_page=0;await store._populate_animation_store()
 for row in store.animation_store_list.get_children():
  if not check(store.StoreLibrary.key(row.get_child(0).entry)!=first_id,"Blocked item remained available"):return
 store.store_library.blocked.erase(first_id)
 var favorite_key:String=store.animation_favorites.key(first)
 var was_favorite:bool=store.animation_favorites.favorites.has(favorite_key)
 if was_favorite:store.animation_favorites.favorites.erase(favorite_key)
 else:store.animation_favorites.favorites[favorite_key]=true
 await store._populate_animation_store()
 if not check(not store.get_meta("store_page_timing").cache_hit,"Favorites reused stale sort order"):return
 if was_favorite:store.animation_favorites.favorites[favorite_key]=true
 else:store.animation_favorites.favorites.erase(favorite_key)
 # A renamed downloaded copy hides its original source, not just its local ID.
 var local:Dictionary=first.duplicate(true);local.store_source_id=first_id;local.store_asset_id="paging-test-copy";local.title="Paging copy"
 store.store_library.taken[local.store_asset_id]=local
 await store._populate_animation_store()
 if not check(not store.get_meta("store_page_timing").cache_hit,"Download reused stale ownership"):return
 store.store_page=0;await store._populate_animation_store()
 for row in store.animation_store_list.get_children():
  if not check(store.StoreLibrary.key(row.get_child(0).entry)!=first_id,"Downloaded source remained available"):return
 store.store_library.taken.erase(local.store_asset_id)
 print("STORE PAGING PERFORMANCE PASS: initial query ",before," cached page ",page,"; block, favorite and downloaded-source invalidation")
 quit()
