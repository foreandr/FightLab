extends SceneTree
## Resumable offline validation/cache worker; does not open or alter the editor.
class TargetRig extends Node3D:
	var skeleton:Skeleton3D
	var player:AnimationPlayer
	var bones:Dictionary={}
var done:=0
var failed:Array=[]
func _initialize():call_deferred("run")
func run():
	var target:=TargetRig.new()
	root.add_child(target)
	var model:Node3D=(load("res://assets/characters/base/Superhero_Male_FullBody.gltf") as PackedScene).instantiate()
	target.add_child(model)
	target.skeleton=model.find_child("Skeleton3D")
	for index in target.skeleton.get_bone_count():target.bones[target.skeleton.get_bone_name(index)]=index
	target.player=AnimationPlayer.new()
	model.add_child(target.player)
	target.player.root_node=NodePath("..")
	var entries:=preload("res://scripts/community_animation_catalog.gd").entries()
	entries.sort_custom(func(a:Dictionary,b:Dictionary):return priority(a)>priority(b))
	for entry in entries:
		if preload("res://scripts/community_animation_catalog.gd").ensure(entry,target) and valid_animation(str(entry.animation_resource)):done+=1
		else:failed.append({"id":entry.sha256,"title":entry.title,"source":entry.bvh_source})
		if (done+failed.size())%20==0 or done+failed.size()==entries.size():
			var file:=FileAccess.open("res://assets/animations/community/validation.json",FileAccess.WRITE)
			file.store_string(JSON.stringify({"verified_cached":done,"failed":failed,"total":entries.size(),"complete":done+failed.size()==entries.size(),"updated_utc":Time.get_datetime_string_from_system(true)}))
			file.close()
			print("Validated/cached ",done," / ",entries.size(),"; failed ",failed.size())
			await process_frame
	print("COMMUNITY VALIDATION COMPLETE: ",done," ready; ",failed.size()," failed")
	quit()

func valid_animation(path:String) -> bool:
	var animation:=load(path) as Animation
	if animation==null or animation.length<=0 or animation.get_track_count()<13:return false
	for track in animation.get_track_count():
		for key in animation.track_get_key_count(track):
			var value=animation.track_get_key_value(track,key)
			if value is Quaternion and (not value.is_finite() or absf(value.length()-1.0)>0.001):return false
			if value is Vector3 and not value.is_finite():return false
	return true
func priority(entry:Dictionary) -> int:
	var score:=0
	for tag in entry.get("tags",[]):
		if tag in ["acrobatics","spin","jump"]:score+=100
		elif tag in ["punch","kick","weapon","spell"]:score+=50
		elif tag in ["dance","dodge","block"]:score+=20
	return score
