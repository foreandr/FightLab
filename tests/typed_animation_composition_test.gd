extends SceneTree
const Type=preload("res://scripts/animation_cast_type.gd")
const Pose=preload("res://scripts/spell_cast_motion.gd")
class MemoryLibrary extends RefCounted:
 var taken:Dictionary={}
 var last_taken_entry:Dictionary={}
 func take(entry:Dictionary,_group:String,_category:String) -> bool:
  assert(Type.declared(entry))
  last_taken_entry=entry.duplicate(true)
  taken.test=last_taken_entry
  return true
 func save() -> bool:return true
func _initialize() -> void:call_deferred("run")
func run() -> void:
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 e.select_group("Attack");e.set_process(false);e.set_physics_process(false)
 e.stop_timeline()
 var actor=e.actor
 var library:=AnimationLibrary.new()
 var animation_root:Node=actor.player.get_node(actor.player.root_node)
 var rig_path:=str(animation_root.get_path_to(actor.skeleton))
 for name_ in ["arm","head"]:
  var clip:=Animation.new();clip.length=1.0
  for bone in ["pelvis","thigh_l","upperarm_r","Head","spine_02"]:
   var track:=clip.add_track(Animation.TYPE_ROTATION_3D)
   clip.track_set_path(track,NodePath(rig_path+":"+bone))
   var angle:=0.3 if name_=="head" else 0.7
   clip.rotation_track_insert_key(track,0.0,Quaternion(Vector3.RIGHT,angle))
   clip.rotation_track_insert_key(track,1.0,Quaternion(Vector3.RIGHT,angle))
  library.add_animation(name_,clip)
 actor.player.add_animation_library("typed_test",library)
 var move={"id":1,"group":"Motion","category":"Acrobatics","title":"Backflip","step":"Flip","clip":"duel/backflip","animation_type":Type.WHOLE_BODY,"track":"BODY","start":0.0,"duration":0.68,"priority":1}
 var arm={"id":2,"group":"Attack","category":"Punch","title":"Arm strike","step":"Hook","clip":"typed_test/arm","animation_type":Type.ARMS,"track":"BODY","start":0.0,"duration":0.68,"priority":3}
 var head={"id":3,"group":"Attack","category":"Punch","title":"Head strike","step":"Hook","clip":"typed_test/head","animation_type":Type.HEAD,"track":"BODY","start":0.0,"duration":0.68,"priority":4}
 e.timeline_duration=0.68
 e._sample_timeline_track("BODY",arm,0.3)
 var arm_pose:=Pose.capture(actor)
 e._sample_timeline_track("BODY",head,0.3)
 var head_pose:=Pose.capture(actor)
 e.timeline_clips.assign([move]);e._apply_timeline_at(0.3,true)
 var movement_pose:=Pose.capture(actor)
 e.timeline_clips.assign([move,arm,head]);e._apply_timeline_at(0.3,true)
 var combined:=Pose.capture(actor)
 for bone in combined.size():
  var expected:Transform3D=movement_pose[bone]
  if Type.controls_bone(actor.skeleton,bone,Type.ARMS):expected=arm_pose[bone]
  if Type.controls_bone(actor.skeleton,bone,Type.HEAD):expected=head_pose[bone]
  assert(combined[bone].is_equal_approx(expected),"Composition broke "+actor.skeleton.get_bone_name(bone))
 # A higher-priority Movement animation can still override all regional layers.
 move.priority=5;e._apply_timeline_at(0.3,true)
 for bone in combined.size():assert(actor.skeleton.get_bone_pose(bone).is_equal_approx(movement_pose[bone]))
 move.priority=1
 var before_head:=Pose.capture(actor)
 preload("res://scripts/character_aim_pose.gd").apply(actor,actor.bone_point("Head")+actor.global_basis.x*3.0+Vector3.UP,"Head",1.0)
 for bone in before_head.size():
  if not Type.controls_bone(actor.skeleton,bone,Type.HEAD):assert(actor.skeleton.get_bone_pose(bone).is_equal_approx(before_head[bone]),"Head aiming moved another region")
 assert(Type.emitter({"animation_type":Type.HEAD,"attack_bone":"hand_l"})=="Head")
 assert(Type.emitter({"animation_type":Type.ARMS,"attack_bone":"calf_l"})=="hand_r")
 assert(Type.emitter({"animation_type":Type.LEGS,"attack_bone":"hand_l"})=="calf_r")
 assert(Type.kind({"animation_type":"Whole body"})==Type.WHOLE_BODY)
 assert(Type.kind({"animation_type":"Arms"})==Type.ARMS)
 assert(Type.composite_type([move,arm,head])==Type.WHOLE_BODY)
 var region=move.duplicate();region.track="RIGHT ARM"
 assert(Type.composite_type([region])==Type.ARMS)
 var real_library=e.store_library
 var memory:=MemoryLibrary.new();e.store_library=memory
 var result:Dictionary=preload("res://scripts/timeline_library_save.gd").save(e,"Typed composition test","Attack","Downloaded")
 assert(result.ok,str(result))
 assert(result.entry.animation_type==Type.WHOLE_BODY)
 assert(result.entry.animation_components.size()==3 and result.entry.composed_timeline.clips.size()==3)
 assert(Type.component_types(result.entry)==[Type.WHOLE_BODY,Type.ARMS,Type.HEAD])
 e.store_library=real_library
 var baked_path:String=result.entry.animation_resource
 assert(baked_path.begins_with("user://authored_animations/timeline_"))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(baked_path))
 print("TYPED COMPOSITION PASS: Movement + Arm + Head on EVERYTHING, region masks and priorities, contact restrictions, old names migrated, extracted arm contribution, saved playable composite retains all typed layers")
 quit()
