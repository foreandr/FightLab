extends RefCounted
## Read-only filtered clips shared across actors. Players retain their own state.
const CACHE_LIMIT:=128
static var _cache:Dictionary={}
static var _versions:Dictionary={}
static var cache_hits:=0
static var cache_misses:=0

## Authoring tool: copy selected body parts without editing either source clip.
static func replace_channels(base:Animation,donor:Animation,donor_name:String,channels:Array[String]) -> Animation:
	var result:=base.duplicate(true) as Animation
	for channel in channels:
		var part:=filtered(donor,donor_name,channel)
		if part==null:continue
		for index in part.get_track_count():
			var path:=part.track_get_path(index)
			var type:=part.track_get_type(index)
			for old in range(result.get_track_count()-1,-1,-1):
				if result.track_get_path(old)==path and result.track_get_type(old)==type:result.remove_track(old)
			part.copy_track(index,result)
			var added:=result.get_track_count()-1
			# Work backward when extending time to keep key indexes stable.
			var keys:=range(result.track_get_key_count(added))
			if result.length>=part.length:keys.reverse()
			for key in keys:result.track_set_key_time(added,key,part.track_get_key_time(index,key)*result.length/maxf(0.001,part.length))
	return result

static func revision(source:Animation) -> int:
	var id:=source.get_instance_id()
	if not _versions.has(id) or _versions[id].source.get_ref()!=source:
		_source_changed(id)
		_versions[id]={"source":weakref(source),"revision":0}
	var callback:=_source_changed.bind(id)
	if not source.changed.is_connected(callback):source.changed.connect(callback)
	if _versions.size()>256:
		for old_id in _versions.keys():
			if _versions[old_id].source.get_ref()==null:_versions.erase(old_id)
	return int(_versions[id].revision)

static func _source_changed(id:int) -> void:
	if _versions.has(id):_versions[id].revision=int(_versions[id].revision)+1
	for key in _cache.keys():
		if str(key).begins_with(str(id)+"|"):_cache.erase(key)

static func filtered(source:Animation,source_name:String,channel:String) -> Animation:
	var looping:=source_name.contains("shield_hold") or source_name in ["duel/strafe_left","duel/strafe_right","fight/walk_guard"]
	var key:="%d|%d|%s|%s"%[source.get_instance_id(),revision(source),channel,looping]
	if _cache.has(key):
		cache_hits+=1
		return _cache[key]
	cache_misses+=1
	var filtered:=source.duplicate(true) as Animation
	filtered.resource_name="Story limb %s %s"%[channel,source_name]
	filtered.loop_mode=Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	for track_index in range(filtered.get_track_count() - 1, -1, -1):
		var bone_name := str(filtered.track_get_path(track_index)).get_slice(":", 1)
		var keep_track:=false
		match channel:
			"arm_l", "arm_r":
				var side:=channel.right(1)
				keep_track=bone_name.ends_with("_%s"%side) and (bone_name.begins_with("upperarm_") or bone_name.begins_with("lowerarm_") or bone_name.begins_with("hand_") or bone_name.begins_with("thumb_") or bone_name.begins_with("index_") or bone_name.begins_with("middle_") or bone_name.begins_with("pinky_") or bone_name.begins_with("ring_")) or bone_name=="clavicle_%s"%side
			"leg_l", "leg_r":
				var side:=channel.right(1)
				keep_track=bone_name.ends_with("_%s"%side) and (bone_name.begins_with("thigh_") or bone_name.begins_with("calf_") or bone_name.begins_with("foot_") or bone_name.begins_with("ball_"))
			"face":
				keep_track=bone_name in ["Head","neck_01","jaw","eye_l","eye_r"]
			"torso":
				keep_track=bone_name in ["spine_01","spine_02","spine_03","neck_01","clavicle_l","clavicle_r"]
		if not keep_track:filtered.remove_track(track_index)
	if filtered.get_track_count()==0:return null
	if _cache.size()>=CACHE_LIMIT:_cache.erase(_cache.keys()[0])
	_cache[key]=filtered
	return filtered
