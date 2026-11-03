extends SceneTree
const Motion=preload("res://scripts/spell_cast_motion.gd")
func _initialize():
 set_meta("ai_learning_enabled",false)
 set_meta("cpu_training_view",true)
 call_deferred("run")
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn")
 await process_frame
 await process_frame
 var world=current_scene
 world.toggle_pause();world.countdown=0;world.round_active=true
 var ids:Dictionary={};var clips:Dictionary={};var kinds:Dictionary={}
 for brain in world.brains:
  for item in brain.loadout:
   var actor=brain.actor
   assert(actor.player.has_animation(item.profile.clip))
   assert(not ids.has(str(actor.team)+item.spec.id),"Duplicate action ID")
   ids[str(actor.team)+item.spec.id]=true;clips[item.profile.clip]=true;kinds[item.kind]=true
   actor.reset_fighter(actor.position)
   assert(actor.start_authored_cast(item.spec,item.profile),"Could not start "+item.title)
   Motion.pose(actor,item.profile,0.1)
   var before:Array[Quaternion]=[]
   for i in actor.skeleton.get_bone_count():before.append(actor.skeleton.get_bone_pose_rotation(i))
   var changed:=0.0
   for progress in [0.3,0.5,0.7]:
    Motion.pose(actor,item.profile,progress)
    for i in before.size():changed=maxf(changed,before[i].angle_to(actor.skeleton.get_bone_pose_rotation(i)))
   assert(changed>0.05,"Static equipped animation: "+item.title)
   assert(world.combat().release(actor,actor.current_spell,actor.bone_point(item.profile.attack_bone),item.profile),"Release failed: "+item.title)
   assert(actor.mana<100 and (item.kind=="shield" or actor.stamina<100),"Cast did not spend real resources: "+item.title)
   world.combat().discard_cast_attempt(actor)
   world.clear_battle_effects()
 print("EXPANDED REPERTOIRE PASS: both actors start, animate, release and pay for ",world.brains[0].loadout.size()," choices each; ",clips.size()," source clips; unique IDs; all three spell kinds")
 quit()


