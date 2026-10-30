extends SceneTree
## Content audit ignores source filenames, headers and quaternion sign.
const ROOT:="res://assets/animations/community"
func _initialize():call_deferred("run")
func run():
	var buckets:Dictionary={}
	var checked:=0
	var pending:=0
	for entry in preload("res://scripts/community_animation_catalog.gd").entries():
		if not FileAccess.file_exists(str(entry.animation_resource)):pending+=1;continue
		var animation:=load(str(entry.animation_resource)) as Animation
		if animation==null:pending+=1;continue
		var signature:=fingerprint(animation)
		if not buckets.has(signature):buckets[signature]=[]
		buckets[signature].append({"id":entry.sha256,"title":entry.title,"source":entry.source_name,"path":entry.bvh_source})
		checked+=1
		if checked%100==0:await process_frame
	var duplicates:Array=[]
	var redundant:=0
	for bucket in buckets.values():
		if bucket.size()>1:duplicates.append(bucket);redundant+=bucket.size()-1
	var report={"checked":checked,"pending_conversion":pending,"duplicate_groups":duplicates,"redundant_candidates":redundant,"method":"30 Hz retargeted motion, quantized to 0.0001; duration preserved; quaternion sign normalized","updated_utc":Time.get_datetime_string_from_system(true)}
	var file:=FileAccess.open(ROOT+"/duplicate_audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("MOTION DUPLICATE AUDIT: ",checked," checked; ",redundant," redundant candidates; ",pending," awaiting conversion")
	quit()

func fingerprint(animation:Animation) -> String:
	var tracks:Array[int]=[]
	for index in animation.get_track_count():tracks.append(index)
	tracks.sort_custom(func(a:int,b:int):return str(animation.track_get_path(a))<str(animation.track_get_path(b)))
	var hash_:=HashingContext.new()
	hash_.start(HashingContext.HASH_SHA256)
	hash_.update(str(roundi(animation.length*30)).to_utf8_buffer())
	for track in tracks:
		hash_.update(str(animation.track_get_path(track)).get_slice(":",1).to_utf8_buffer())
		var values:=PackedInt32Array()
		for frame in ceili(animation.length*30)+1:
			var time:=minf(animation.length,float(frame)/30)
			if animation.track_get_type(track)==Animation.TYPE_ROTATION_3D:
				var q:=animation.rotation_track_interpolate(track,time)
				if q.w<0:q=-q
				for value in [q.x,q.y,q.z,q.w]:values.append(roundi(value*10000))
			elif animation.track_get_type(track)==Animation.TYPE_POSITION_3D:
				var p:=animation.position_track_interpolate(track,time)
				for value in [p.x,p.y,p.z]:values.append(roundi(value*10000))
		hash_.update(values.to_byte_array())
	return hash_.finish().hex_encode()
