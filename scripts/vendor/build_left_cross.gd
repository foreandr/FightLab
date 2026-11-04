extends SceneTree
## Bake the existing right cross through the same calibrated mirror as the editor.
func _initialize():call_deferred("run")
func run():
 var world=load("res://scripts/spell_creation_world.gd").new();root.add_child(world)
 var actor=world.spawn_combatant(0,Vector3.ZERO,load("res://scripts/creation_bot_outfit.gd").profile(0))
 var source:Animation=actor.player.get_animation("ual1/Punch_Cross")
 var animation:=Animation.new();animation.length=source.length
 animation.set_meta("source_animation","ual1/Punch_Cross")
 animation.set_meta("derived_operation","Calibrated sagittal reflection using animation_mirror.gd")
 var prefix:=str(source.track_get_path(0)).get_slice(":",0)
 for bone in actor.skeleton.get_bone_count():
  for type in [Animation.TYPE_ROTATION_3D,Animation.TYPE_POSITION_3D]:
   var track:=animation.add_track(type)
   animation.track_set_path(track,NodePath(prefix+":"+actor.skeleton.get_bone_name(bone)))
 var count:=ceili(source.length*30.0)+1
 for sample in count:
  var time:=source.length*sample/float(count-1)
  load("res://scripts/editor_rig_pose.gd").sample(actor,"ual1/Punch_Cross",time)
  load("res://scripts/animation_mirror.gd").apply(actor)
  for bone in actor.skeleton.get_bone_count():
   animation.rotation_track_insert_key(bone*2,time,actor.skeleton.get_bone_pose_rotation(bone))
   animation.position_track_insert_key(bone*2+1,time,actor.skeleton.get_bone_pose_position(bone))
 assert(ResourceSaver.save(animation,"res://assets/animations/demos/left_cross.res",ResourceSaver.FLAG_COMPRESS)==OK)
 print("LEFT CROSS baked from original right cross with calibrated rig mirror")
 quit()
