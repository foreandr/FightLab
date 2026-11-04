extends SceneTree
class TargetRig extends Node3D:
 var skeleton:Skeleton3D
 var player:AnimationPlayer
 var bones:Dictionary={}
func _initialize():call_deferred("run")
func run():
 var rig:=TargetRig.new();root.add_child(rig)
 var model=load("res://assets/characters/base/Superhero_Male_FullBody.gltf").instantiate();rig.add_child(model)
 rig.skeleton=model.find_child("Skeleton3D")
 rig.player=AnimationPlayer.new();model.add_child(rig.player);rig.player.root_node=NodePath("..")
 for i in rig.skeleton.get_bone_count():rig.bones[rig.skeleton.get_bone_name(i)]=i
 var path:="res://data/static_animation_filter.json"
 var filter:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 var failures:Array=[];var checked:=0;var accepted:=0
 var catalog=load("res://scripts/community_animation_catalog.gd")
 var entries:Array=catalog.entries()
 for entry in entries:
  if catalog.ensure(entry,rig):accepted+=1
  else:failures.append({"store_asset_id":entry.store_asset_id,"title":entry.title,"bvh_source":entry.bvh_source,"reason":"Failed source-time smoothing/rotation continuity/rig penetration gate"})
  checked+=1
  if checked%20==0 or checked==entries.size():
   var report:=FileAccess.open("res://work/imported_motion_audit.json",FileAccess.WRITE)
   report.store_string(JSON.stringify({"checked":checked,"total":entries.size(),"accepted":accepted,"failed":failures,"complete":checked==entries.size()}," "));report.close()
   print("MOTION AUDIT ",checked," / ",entries.size()," · ",accepted," accepted · ",failures.size()," rejected")
   await process_frame
 var seen:Dictionary={}
 for item in filter.get("invalid",[]):seen[str(item.get("store_asset_id",""))]=true
 for item in failures:
  if not seen.has(str(item.store_asset_id)):filter.invalid.append(item)
 filter["motion_conditioning_version"]=preload("res://scripts/animation_motion_conditioning.gd").VERSION
 var output:=FileAccess.open(path,FileAccess.WRITE);output.store_string(JSON.stringify(filter));output.close()
 print("MOTION AUDIT COMPLETE")
 quit()
