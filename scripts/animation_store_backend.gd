extends RefCounted
## Shared Store catalog, lazy page loading, asset resolution and acquisition.

static func _load_animation_store(host) -> void:
	if host.store_loaded or host.store_loading_in_progress:return
	host.store_loading_in_progress=true
	host.set_meta("store_query_cache",{})
	var cache_path=ProjectSettings.globalize_path(host.StoreIndex.cache_path())
	host.store_loading_pacer.begin("store_index_cold_build" if not FileAccess.file_exists(cache_path) else "store_index_build")
	host.store_loading_indicator.show()
	host.store_loading_bar.value=0
	host.store_loading_status.text="Opening the local Store index…"
	host.clear_list(host.animation_store_list)
	await RenderingServer.frame_post_draw
	var cached:Dictionary={}
	if FileAccess.file_exists(cache_path):
		var cache_thread=Thread.new()
		if cache_thread.start(func():return host.StoreIndex.load_cache(cache_path))==OK:
			var result:Variant=await host._wait_for_store_thread(cache_thread,0.15,"Reading the compact Store index…")
			if result is Dictionary:cached=result
	if cached.is_empty():
		host._set_store_loading_progress(0.12,"Building your local search index · first visit only…")
		var build_thread=Thread.new()
		if build_thread.start(func():return host.StoreIndex.build_cache(cache_path))==OK:
			var result:Variant=await host._wait_for_store_thread(build_thread,0.12,"Indexing animation titles and tags…")
			if result is Dictionary:cached=result
	var cache_loaded_usec:=Time.get_ticks_usec()
	host.store_index_records.clear()
	for record in cached.get("records",[]):
		if record is Dictionary:host.store_index_records.append(record)
	host.store_index_details_path=str(cached.get("details_path",host.StoreIndex.details_path(cache_path)))
	host.animation_store_entries=host.Library.entries()
	if host.has_method("store_owned_metadata"):host.animation_store_entries.append_array(host.store_owned_metadata())
	for group in host.Library.GROUPS:
		for category in host.category_store.names_for(group):host.animation_store_entries.append_array(host.load_custom_motion(category))
	# Include source clips beyond the curated Motion/Attack host.browser.
	var auxiliary=load("res://assets/combat/animations/UAL2_Standard.glb") as AnimationLibrary
	var used:Dictionary={}
	for entry in host.animation_store_entries:used[str(entry.get("clip",""))]=true
	if auxiliary!=null:
		for name_ in auxiliary.get_animation_list():
			if used.has("ual2/"+name_) or name_=="RESET":continue
			host.animation_store_entries.append({"group":"Motion","category":"Source clips","title":name_.replace("_"," "),"step":"Idle","clip":"store_preview/"+name_,"source_animation":name_,"store_raw":true,"duration":auxiliary.get_animation(name_).length})
	for name_ in host.actor.player.get_animation_list():
		if name_.begins_with("store_preview/"):continue
		if name_.ends_with("RESET") or used.has(name_):continue
		if name_.begins_with("store_ual2/") and used.has("ual2/"+name_.get_slice("/",1)):continue
		var entry:Dictionary={"group":"Motion","category":"Source clips","title":name_.get_slice("/",1).replace("_"," "),"step":"Idle","clip":name_,"store_raw":true}
		entry["duration"]=host.actor.player.get_animation(name_).length
		host.animation_store_entries.append(entry)
	var combat_filter=preload("res://scripts/combat_animation_filter.gd").new()
	host.animation_store_entries=host.animation_store_entries.filter(func(entry):return combat_filter.accepts(entry))
	var total_entries=host.animation_store_entries.size()
	for index in total_entries:
		var entry:Dictionary=host.animation_store_entries[index]
		if not (entry.has("store_asset_id") and entry.has("body_parts")):
			var animation:Animation
			if entry.has("source_animation") and auxiliary!=null:animation=auxiliary.get_animation(str(entry.source_animation))
			elif host.actor.player.has_animation(str(entry.clip)):animation=host.actor.player.get_animation(str(entry.clip))
			host.animation_store_entries[index]=host.StoreLibrary.enrich(entry,animation)
	GameDiagnostics.log_event("store_index_timing",{"cache_seconds":host.store_loading_pacer.elapsed_seconds(),"registry_ms":(Time.get_ticks_usec()-cache_loaded_usec)/1000.0})
	host._set_store_loading_progress(0.96,"Loading the first 20 matching records…")
	host._populate_store_creators()
	host._load_store_preferences()
	await host._populate_animation_store()
	host.store_loaded=true
	host.store_loading_bar.value=100
	host.store_loading_status.text="Store ready · 20 results per page"
	await RenderingServer.frame_post_draw
	host.store_loading_indicator.hide()
	host.store_loading_in_progress=false


static func _set_store_loading_progress(host, fraction:float,status:String) -> void:
	if not is_instance_valid(host.store_loading_bar) or not is_instance_valid(host.store_loading_status):return
	host.store_loading_status.text=status
	host.store_loading_bar.value=host.store_loading_pacer.progress_percent(fraction)


static func _wait_for_store_thread(host, thread:Thread,fraction:float,status:String) -> Variant:
	while thread.is_alive():
		host._set_store_loading_progress(fraction,status)
		await host.get_tree().process_frame
	return thread.wait_to_finish()


static func _save_store_preferences(host) -> void:
	if not is_instance_valid(host.store_view_filter):return
	var config=ConfigFile.new()
	config.set_value("store","search",host.animation_store_search.text)
	config.set_value("store","animation_type",host.store_body_filter.selected)
	config.set_value("store","air",host.store_air_filter.selected)
	config.set_value("store","view",host.store_view_filter.selected)
	config.set_value("store","sort",host.store_sort_filter.selected)
	config.set_value("store","creator",host.store_creator_filter.get_item_text(host.store_creator_filter.selected))
	config.save("user://animation_store_preferences.cfg")


static func _load_store_preferences(host) -> void:
	var config=ConfigFile.new()
	if config.load("user://animation_store_preferences.cfg")!=OK:return
	host.animation_store_search.set_block_signals(true)
	host.animation_store_search.text=str(config.get_value("store","search",""))
	host.animation_store_search.set_block_signals(false)
	for pair in [[host.store_body_filter,"animation_type"],[host.store_air_filter,"air"],[host.store_view_filter,"view"],[host.store_sort_filter,"sort"]]:
		var filter:OptionButton=pair[0]
		filter.select(clampi(int(config.get_value("store",pair[1],0)),0,filter.item_count-1))
	var creator=str(config.get_value("store","creator","All creators"))
	for index in host.store_creator_filter.item_count:
		if host.store_creator_filter.get_item_text(index)==creator:host.store_creator_filter.select(index);break


static func _store_creator(host, entry:Dictionary) -> String:
	if entry.has("store_creator"):return str(entry.store_creator)
	var provenance:Dictionary=entry.get("provenance",{})
	var nodes:Dictionary=provenance.get("nodes",{})
	for node in nodes.values():
		var author=str(node.get("author","")).strip_edges()
		if not author.is_empty():return author
	var source=str(entry.get("source_name","")).strip_edges()
	return source if not source.is_empty() else "FightLab"


static func _populate_store_creators(host) -> void:
	if not is_instance_valid(host.store_creator_filter):return
	var config=ConfigFile.new()
	config.load("user://animation_store_preferences.cfg")
	var wanted=str(config.get_value("store","creator","All creators"))
	var creators:Dictionary={}
	for entry in host.store_index_records:creators[host._store_creator(entry)]=true
	for entry in host.animation_store_entries:creators[host._store_creator(entry)]=true
	var names=creators.keys()
	names.sort_custom(func(a:String,b:String):return a.naturalnocasecmp_to(b)<0)
	host.store_creator_filter.clear()
	host.store_creator_filter.add_item("All creators")
	for name_ in names:host.store_creator_filter.add_item(str(name_))
	for index in host.store_creator_filter.item_count:
		if host.store_creator_filter.get_item_text(index)==wanted:host.store_creator_filter.select(index);break


static func _style_store_action(host, control:Button,color:Color) -> void:
	control.add_theme_stylebox_override("normal",host._book_box(color,color.darkened(0.2)))
	control.add_theme_stylebox_override("hover",host._book_box(color.lightened(0.15),color.darkened(0.2)))
	control.add_theme_stylebox_override("pressed",host._book_box(color.darkened(0.15),color.darkened(0.3)))


static func _store_top_score(host, entry:Dictionary) -> int:
	var score=0
	if host.animation_favorites.has(entry):score+=1000
	if entry.has("store_top_score"):return score+int(entry.store_top_score)
	var tags:Array=entry.get("tags",[])
	for pair in [["acrobatics",100],["spin",70],["jump",55],["weapon",50],["punch",40],["kick",40],["dodge",30],["block",20],["dance",10]]:
		if str(pair[0]) in tags:score+=int(pair[1])
	return score


static func _download_store_animation(host, entry:Dictionary) -> void:
	var group="Attack" if str(entry.get("group",""))=="Attack" else "Motion"
	host.take_store_animation(entry,group,"Downloaded")


static func _log_store_action(host, action:String,entry:Dictionary,details:Dictionary={}) -> void:
	var record:Dictionary={"title":entry.get("title",""),"asset_id":host.StoreLibrary.key(entry),"clip":entry.get("clip",""),"source":entry.get("bvh_source",""),"resource":entry.get("animation_resource",""),"entry_keys":entry.keys(),"focused_unit":str(host.focused_unit.name) if is_instance_valid(host.focused_unit) else ""}
	record.merge(details,true)
	GameDiagnostics.log_event("animation_store_"+action,record)


static func _resolve_store_record(host, entry:Dictionary) -> Dictionary:
	if not entry.has("_detail_offset"):return entry
	var full:Dictionary=host.StoreIndex.load_entry(host.store_index_details_path,int(entry.get("_detail_offset",-1)),int(entry.get("_detail_size",0)))
	if full.is_empty() or host.StoreLibrary.key(full)!=host.StoreLibrary.key(entry):
		host._log_store_action("detail_failed",entry,{"details_file":host.store_index_details_path,"offset":entry.get("_detail_offset",-1),"size":entry.get("_detail_size",0)})
		host._show_library_notice("Could not read this Store item · details saved in the logs")
		return {}
	return host.StoreLibrary.enrich(full)


static func _toggle_store_block(host, entry:Dictionary,currently_blocked:bool) -> void:
	if host.store_library.set_blocked(entry,not currently_blocked):host._populate_animation_store()


static func _populate_animation_store(host) -> void:
	if not is_instance_valid(host.animation_store_list):return
	var started_usec:=Time.get_ticks_usec()
	host.store_page_generation+=1
	var generation=host.store_page_generation
	host.clear_list(host.animation_store_list)
	var query=host.animation_store_search.text.strip_edges().to_lower()
	var query_key="%s|%d|%d|%d|%d|%d"%[query,host.store_body_filter.selected,host.store_air_filter.selected,host.store_view_filter.selected,host.store_sort_filter.selected,host.store_creator_filter.selected]
	if query_key!=host.store_last_query:host.store_page=0;host.store_last_query=query_key
	# A page turn reuses ordered matches. Ownership lookup is built once, not
	# once per catalog record; source IDs also recognize renamed local copies.
	var owned_sources:Dictionary={}
	var ownership_signature:Array=[]
	for owned in host.store_library.taken.values():
		var owned_id:String=host.StoreLibrary.key(owned)
		owned_sources[owned_id]=true
		owned_sources[str(owned.get("store_source_id",owned_id))]=true
		ownership_signature.append([owned_id,owned.get("title"),owned.get("category"),owned.get("animation_type")])
	var cache_key:String=query_key+"|"+str([host.store_index_records.size(),host.animation_store_entries.size(),ownership_signature,host.store_library.blocked.keys(),host.animation_favorites.favorites].hash())
	var query_cache:Dictionary=host.get_meta("store_query_cache",{})
	var cache_hit:bool=query_cache.has(cache_key)
	var matches_:Array[Dictionary]=[]
	if cache_hit:matches_.assign(query_cache[cache_key])
	else:
		var all_records:Array[Dictionary]=[]
		all_records.append_array(host.store_index_records)
		all_records.append_array(host.animation_store_entries)
		for entry in all_records:
			var id=host.StoreLibrary.key(entry)
			var taken:bool=owned_sources.has(id) or entry.has("path")
			var blocked:bool=host.store_library.blocked.has(id)
			if host.store_view_filter.selected==0 and (taken or blocked):continue
			if host.store_view_filter.selected==1 and not taken:continue
			if host.store_view_filter.selected==2 and not blocked:continue
			if host.store_library.taken.has(id):entry=host.store_library.taken[id].duplicate(true)
			if not entry.has("store_animation_type"):entry["store_animation_type"]=preload("res://scripts/animation_store_types.gd").kind(entry)
			if host.store_body_filter.selected>0 and host.store_body_filter.get_item_text(host.store_body_filter.selected)!=str(entry.store_animation_type):continue
			if host.store_air_filter.selected>0 and str(entry.get("air_state",""))!=host.store_air_filter.get_item_text(host.store_air_filter.selected):continue
			if host.store_creator_filter.selected>0 and host._store_creator(entry)!=host.store_creator_filter.get_item_text(host.store_creator_filter.selected):continue
			if not query.is_empty() and not host.StoreLibrary.matches(entry,query):continue
			entry["_store_query_score"]=host._store_top_score(entry)
			matches_.append(entry)
	var scan_usec:=Time.get_ticks_usec()
	if not cache_hit:
		if host.store_sort_filter.selected==0:
			matches_.sort_custom(func(a:Dictionary,b:Dictionary):
				var score_a:int=a._store_query_score;var score_b:int=b._store_query_score
				if score_a!=score_b:return score_a>score_b
				return str(a.title).naturalnocasecmp_to(str(b.title))<0)
		elif host.store_sort_filter.selected==2:
			matches_.sort_custom(func(a:Dictionary,b:Dictionary):
				var creator_order=host._store_creator(a).naturalnocasecmp_to(host._store_creator(b))
				return creator_order<0 if creator_order!=0 else str(a.title).naturalnocasecmp_to(str(b.title))<0)
		else:
			matches_.sort_custom(func(a:Dictionary,b:Dictionary):return str(a.title).naturalnocasecmp_to(str(b.title))<0)
		if query_cache.size()>=8:query_cache.clear()
		query_cache[cache_key]=matches_
		host.set_meta("store_query_cache",query_cache)
	var count:int=matches_.size()
	var sorted_usec:=Time.get_ticks_usec()
	host.store_page=clampi(host.store_page,0,maxi(0,ceili(float(count)/host.STORE_PAGE_SIZE)-1))
	host.store_page_label.text="Page %d / %d · %d matches"%[host.store_page+1,maxi(1,ceili(float(count)/host.STORE_PAGE_SIZE)),count]
	host.store_page_previous.disabled=host.store_page==0
	host.store_page_next.disabled=(host.store_page+1)*host.STORE_PAGE_SIZE>=count
	var visible:Array[Dictionary]=matches_.slice(host.store_page*host.STORE_PAGE_SIZE,(host.store_page+1)*host.STORE_PAGE_SIZE)
	var detail_thread=Thread.new()
	var page_details:Dictionary={}
	var page_source=host.store_index_details_path
	var page_records=visible.duplicate(true)
	var thread_error=detail_thread.start(func():
		var loaded:Dictionary={}
		for record in page_records:
			if not record.has("_detail_offset"):continue
			var id=host.StoreLibrary.key(record)
			if loaded.has(id):continue
			loaded[id]=host.StoreIndex.load_entry(page_source,int(record.get("_detail_offset",0)),int(record.get("_detail_size",0)))
		return loaded)
	if thread_error==OK:
		var detail_result:Variant=await host._wait_for_store_thread(detail_thread,0.98,"Loading this page’s 20 animation records…")
		if detail_result is Dictionary:page_details=detail_result
	if generation!=host.store_page_generation:return
	var details_usec:=Time.get_ticks_usec()
	for compact_entry in visible:
		var entry:Dictionary=compact_entry
		var id=host.StoreLibrary.key(entry)
		if page_details.has(id) and page_details[id] is Dictionary and not page_details[id].is_empty() and host.StoreLibrary.key(page_details[id])==id:
			entry=host.StoreLibrary.enrich(page_details[id])
			entry["store_animation_type"]=str(compact_entry.get("store_animation_type",preload("res://scripts/animation_store_types.gd").kind(entry)))
			entry["store_creator"]=str(compact_entry.get("store_creator","FightLab"))
			entry["store_top_score"]=int(compact_entry.get("store_top_score",0))
			if not entry.has("store_asset_id"):entry["store_asset_id"]=id
			if host.store_library.taken.has(id):entry=host.store_library.taken[id].duplicate(true)
		elif compact_entry.has("_detail_offset"):
			host._log_store_action("page_detail_failed",compact_entry,{"details_file":page_source})
		if str(entry.get("title","")).strip_edges().is_empty():entry["title"]=str(compact_entry.get("title","Animation"))
		if not entry.has("body_parts"):entry=host.StoreLibrary.enrich(entry)
		id=host.StoreLibrary.key(entry)
		var blocked:bool=host.store_library.blocked.has(id)
		var row_entry:Dictionary=entry.duplicate(true)
		row_entry.erase("_store_query_score")
		var row=HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		host.animation_store_list.add_child(row)
		var title=host.button(row,str(row_entry.get("title","Animation")),Callable(host,"_play_store_animation").bind(row_entry))
		title.set_script(preload("res://scripts/animation_clip_source.gd"))
		title.set("entry",row_entry.duplicate(true))
		title.set("editor",host)
		title.set("store_origin",true)
		title.icon=host.RowIcons.get_icon({"Head":"head","Arm":"arm","Leg":"leg","Movement":"movement"}.get(preload("res://scripts/animation_store_types.gd").kind(entry),"movement"))
		title.add_theme_constant_override("icon_max_width",24)
		title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		title.clip_text=true
		title.tooltip_text=host.animation_info_text(entry)+"\nType\t"+preload("res://scripts/animation_store_types.gd").kind(entry)+"\nTags\t"+", ".join(entry.get("tags",[]))+"\nBody\t"+", ".join(entry.get("body_parts",[]))+"\nState\t"+str(entry.get("air_state","Grounded"))
		if entry.has("source_name"):title.tooltip_text+="\nSource\t"+str(entry.source_name)+"\nLicense\t"+str(entry.get("license","Unspecified"))
		var play=host.animation_icon_button(row,"play","Play once on selected bot",Callable(host,"_play_store_animation").bind(row_entry))
		play.name="StorePlay"
		host._style_store_action(play,Color("388753"))
		var downloaded=host.store_library.is_taken(row_entry)
		var download=host.animation_icon_button(row,"downloaded" if downloaded else "download","Already in Downloaded" if downloaded else "Download to your Downloaded folder and save a project copy",Callable(host,"_download_store_animation").bind(row_entry))
		download.name="StoreDownload"
		if downloaded:
			download.disabled=true
			host._style_store_action(download,Color("6b9876"))
		else:host._style_store_action(download,Color("a87935"))
		var reject=host.animation_icon_button(row,"undo" if blocked else "block","Unblock this animation" if blocked else "Block this animation from the Store",Callable(host,"_toggle_store_block").bind(row_entry,blocked))
		reject.name="StoreBlock"
		host._style_store_action(reject,Color("b8443e") if not blocked else Color("9c743d"))
	host.animation_store_count.text="Animations · %d / %d"%[count,host.store_index_records.size()+host.animation_store_entries.size()]
	var timing:Dictionary={"cache_hit":cache_hit,"scan_ms":(scan_usec-started_usec)/1000.0,"sort_ms":(sorted_usec-scan_usec)/1000.0,"details_ms":(details_usec-sorted_usec)/1000.0,"rows_ms":(Time.get_ticks_usec()-details_usec)/1000.0,"total_ms":(Time.get_ticks_usec()-started_usec)/1000.0}
	host.set_meta("store_page_timing",timing)
	GameDiagnostics.log_event("animation_store_page_timing",timing)
	GameDiagnostics.log_event("animation_store_page_ready",{"page":host.store_page,"matches":count,"visible":visible.size(),"details_expected":visible.filter(func(value):return value.has("_detail_offset")).size(),"details_loaded":page_details.values().filter(func(value):return value is Dictionary and not value.is_empty()).size(),"details_file":page_source})
	host.call_deferred("_apply_panel_zoom","Store")


static func _play_store_animation(host, entry:Dictionary) -> void:
	entry=host._resolve_store_record(entry)
	if entry.is_empty():return
	host._log_store_action("play_clicked",entry)
	if not host.can_add_unit_animation():
		host.show_unit_selection_warning()
		return
	var preview_entry=entry.duplicate(true)
	# Store rows represent real clips, not pose-recipe names. Imported records
	# often have generic steps like "Imported Motion"; sending those through
	# SourcePose silently samples a fallback pose instead of the selected clip.
	if preview_entry.has("animation_resource") or preview_entry.has("bvh_source") or preview_entry.has("source_animation"):
		preview_entry["store_raw"]=true
	if host.selected_group=="Spells":
		host.select_group("Motion")
		host.workspace_nav_panels.Store.show()
	host.play_animation_row(preview_entry)


static func _ensure_animation_source(host, entry:Dictionary) -> bool:
	if entry.has("bvh_source") and not preload("res://scripts/community_animation_catalog.gd").ensure(entry,host.actor):
		host._show_library_notice("Could not import this source animation · original file preserved")
		host._log_store_action("import_failed",entry)
		return false
	if entry.has("animation_resource"):
		var clip_name=str(entry.get("clip",""))
		if host.actor.player.has_animation(clip_name):return true
		var animation=load(str(entry.animation_resource)) as Animation
		if animation==null:
			host._log_store_action("resource_load_failed",entry,{"file_exists":FileAccess.file_exists(str(entry.animation_resource))})
			host._show_library_notice("Could not load the animation clip · try the preview again")
			return false
		var namespace_="store_preview"
		var animation_name=clip_name
		if clip_name.contains("/"):
			namespace_=clip_name.get_slice("/",0)
			animation_name=clip_name.get_slice("/",1)
		if not host.actor.player.has_animation_library(namespace_):host.actor.player.add_animation_library(namespace_,AnimationLibrary.new())
		host.actor.player.get_animation_library(namespace_).add_animation(animation_name,animation)
		return true
	if entry.has("source_animation") and not host.actor.player.has_animation(str(entry.clip)):
		host.actor.player.stop()
		var source=load("res://assets/combat/animations/UAL2_Standard.glb") as AnimationLibrary
		if source==null or source.get_animation(str(entry.source_animation))==null:
			host._show_library_notice("Could not find this source animation")
			return false
		if not host.actor.player.has_animation_library("store_preview"):host.actor.player.add_animation_library("store_preview",AnimationLibrary.new())
		var library:AnimationLibrary=host.actor.player.get_animation_library("store_preview")
		library.add_animation(str(entry.source_animation),source.get_animation(str(entry.source_animation)).duplicate(true))
	var ready:bool=host.actor.player.has_animation(str(entry.get("clip","")))
	if not ready:
		host._log_store_action("clip_missing",entry,{"available_animation_count":host.actor.player.get_animation_list().size()})
		host._show_library_notice("This animation has no playable clip · details saved in the logs")
	return ready


static func _portable_store_animation(host, entry:Dictionary) -> Animation:
	if entry.has("bvh_source") and not preload("res://scripts/community_animation_catalog.gd").ensure(entry,host.actor):
		return null
	return preload("res://scripts/animation_project_assets.gd").resolve(entry,host.actor.player)


static func take_store_animation(host, entry:Dictionary,group:String,category:String) -> void:
	entry=host._resolve_store_record(entry)
	if entry.is_empty():return
	host._log_store_action("download_clicked",entry,{"destination_group":group,"destination_folder":category})
	if entry.has("bvh_source") and not preload("res://scripts/community_animation_catalog.gd").ensure(entry,host.actor):
		host._show_library_notice("Not added · this source could not be imported onto the character rig")
		return
	var project_animation=host._portable_store_animation(entry)
	if project_animation==null:
		host._log_store_action("project_resolve_failed",entry,{"file_exists":FileAccess.file_exists(str(entry.get("animation_resource","")))})
		host._show_library_notice("Not added · could not create a project copy of this animation")
		return
	var quality:Dictionary=preload("res://scripts/animation_quality_gate.gd").inspect(project_animation,host.actor.skeleton)
	if not bool(quality.get("ok",false)):
		host._log_store_action("quality_rejected",entry,quality)
		host._show_library_notice("Not added · quality check: "+str(quality.get("reason","animation failed validation")))
		return
	if entry.has("store_asset_id") and host.store_library.taken.has(host.StoreLibrary.key(entry)):
		var owned_id=host.StoreLibrary.key(entry)
		if not host.store_library.ensure_project_copy(owned_id,project_animation):
			host._show_library_notice("Could not make a project copy of this animation")
			return
		if host.store_library.move(owned_id,group,category):
			if not host.home_store_mode:
				if host.selected_group!=group:host.select_group(group)
				host.select_category(category,true)
			host._populate_animation_store()
			host._show_library_notice("Moved %s → %s"%[entry.title,category])
		return
	var names:Array=[]
	for animation in host.Library.entries()+host.load_custom_motion(category):names.append(str(animation.title))
	if not host.store_library.take(entry,group,category,names,project_animation):
		host._log_store_action("project_save_failed",entry)
		host.selection_status.text="Could not save animation as a project asset"
		return
	host._populate_animation_store()
	if not host.home_store_mode:
		if host.selected_group!=group:host.select_group(group)
		host.select_category(category,true)
	host.selection_status.text="Added %s to %s / %s"%[entry.title,group,category]
	host._log_store_action("download_complete",entry,{"project_asset":host.store_library.last_taken_entry.get("animation_resource",""),"tracks":project_animation.get_track_count(),"duration":project_animation.length})
	host._show_library_notice("Added %s → %s · project asset ready for Git"%[host.store_library.last_taken_entry.get("title",entry.title),category])
