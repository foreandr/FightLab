extends RefCounted
## Save a playable composite and its editable source timeline into a library folder.
const Credits=preload("res://scripts/asset_provenance.gd")

static func save(editor:Node,name_:String,group:String,category:String) -> Dictionary:
	if editor.timeline_clips.is_empty():return {"ok":false,"error":"Add an animation to the timeline first."}
	if group not in ["Motion","Attack"] or category not in editor.category_store.names_for(group):
		return {"ok":false,"error":"Choose a destination folder."}
	var resource:=_bake(editor)
	if not resource.ok:return resource
	var snapshot:Dictionary={"name":name_,"duration":editor.timeline_duration,"clips":editor.timeline_clips.duplicate(true),"rows":editor.timeline_rows.duplicate(true),"group":group,"category":category}
	var parents:Array=[]
	var attack:Dictionary={}
	for clip in editor.timeline_clips:
		parents.append(Credits.source(clip))
		if clip.get("group","")=="Attack":attack=clip
	var entry:Dictionary={"title":name_,"clip":resource.clip,"animation_resource":resource.path,"duration":editor.timeline_duration,"source_duration":editor.timeline_duration,"source_timing":"native_v1","store_raw":true,"group":group,"category":category,"step":str(attack.get("step","Idle")) if group=="Attack" else "Idle","composed_timeline":snapshot}
	if group=="Attack":
		entry.attack_bone=attack.get("attack_bone","hand_r")
		for key in ["physical_damage","stamina_cost","mana_cost"]:entry[key]=attack.get(key,0.0)
	entry.provenance=Credits.derive(parents,"animation",name_,Credits.creator_name(),"saved composite timeline to "+group+" / "+category+"; source layers retained")
	var previous:Dictionary=editor.store_library.taken.duplicate(true)
	var found:=""
	for id in editor.store_library.taken:
		if str(editor.store_library.taken[id].title)==name_:found=str(id);break
	if not found.is_empty():
		var old:Dictionary=editor.store_library.taken[found]
		entry.store_asset_id=found
		entry.store_source_id=old.get("store_source_id",found)
		editor.store_library.taken[found]=entry
		if not editor.store_library.save():
			editor.store_library.taken=previous
			return {"ok":false,"error":"Could not save to that folder. Your timeline is still open."}
	else:
		if not editor.store_library.take(entry,group,category):return {"ok":false,"error":"Could not save to that folder. Your timeline is still open."}
		entry=editor.store_library.last_taken_entry.duplicate(true)
	return {"ok":true,"entry":entry,"snapshot":snapshot}

static func _bake(editor:Node) -> Dictionary:
	var directory:="user://authored_animations"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))!=OK:return {"ok":false,"error":"Could not create the animation folder."}
	var rig:Skeleton3D=editor.actor.skeleton
	var animation:=Animation.new()
	animation.length=editor.timeline_duration
	var animation_root:Node=editor.actor.player.get_node(editor.actor.player.root_node)
	var rig_path:=str(animation_root.get_path_to(rig))
	var tracks:Array=[]
	for bone in rig.get_bone_count():
		var rotation:=animation.add_track(Animation.TYPE_ROTATION_3D)
		var position:=animation.add_track(Animation.TYPE_POSITION_3D)
		var bone_path:=NodePath(rig_path+":"+rig.get_bone_name(bone))
		animation.track_set_path(rotation,bone_path)
		animation.track_set_path(position,bone_path)
		tracks.append([rotation,position])
	var old_playhead:float=editor.timeline_playhead
	editor.stop_timeline()
	var old_unit:Node=editor.focused_unit
	var temporary:Node
	if not is_instance_valid(old_unit):temporary=editor.spawn_editor_unit(Vector3(0,0.02,0))
	for clip in editor.timeline_clips:editor._ensure_animation_source(clip)
	for frame in range(ceili(animation.length*60)+1):
		var time:=minf(animation.length,float(frame)/60.0)
		editor._apply_timeline_at(minf(time,maxf(0.0,animation.length-0.00001)),true)
		rig.force_update_all_bone_transforms()
		var parent:=rig.get_bone_parent(editor.actor.bones.pelvis)
		var parent_basis:Basis=rig.global_basis
		if parent>=0:parent_basis=parent_basis*rig.get_bone_global_pose(parent).basis
		var height:float=editor.focused_unit.global_position.y-editor.timeline_unit_origin.y
		for bone in rig.get_bone_count():
			var position:=rig.get_bone_pose_position(bone)
			if bone==editor.actor.bones.pelvis:position+=parent_basis.inverse()*Vector3.UP*height
			animation.rotation_track_insert_key(tracks[bone][0],time,rig.get_bone_pose_rotation(bone))
			animation.position_track_insert_key(tracks[bone][1],time,position)
	editor._on_timeline_scrubbed(old_playhead)
	if is_instance_valid(temporary):
		editor.clear_jump_tails(temporary,true)
		editor.added_units.erase(temporary)
		editor.focused_unit=old_unit
		temporary.queue_free()
	var id:=Crypto.new().generate_random_bytes(12).hex_encode()
	var path:=directory+"/timeline_"+id+".tres"
	if ResourceSaver.save(animation,path)!=OK:return {"ok":false,"error":"Could not write the animation. Your timeline is still open."}
	return {"ok":true,"path":path,"clip":"authored_timeline/"+id}
