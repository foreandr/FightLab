extends SceneTree
const Burning=preload("res://assets/spells/fire/burning.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 var stream:=Burning.stream()
 if not check(stream==Burning.stream() and stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_end*2==stream.data.size() and stream.get_length()>2.0,"Burn loop/cache invalid"):return
 var first:int=stream.data.decode_s16(0);var last:int=stream.data.decode_s16(stream.data.size()-2)
 if not check(absi(first-last)<6000,"Loop seam discontinuity"):return
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world)
 world.set_physics_process(false);world.round_active=true
 var actor:CharacterBody3D=world.spawn_combatant(0,Vector3.ZERO)
 actor.set_physics_process(false);actor.brain_enabled=false
 actor.status_visual.set_process(false)
 actor.practice_god_mode=true
 actor.receive_status(actor,{"projectile_element":"Fire","potency":1.0})
 actor.status_visual._process(0.0)
 var visual=actor.burn_visual
 visual.set_process(false);visual._process(0.0)
 var voice=visual.burn_audio
 if not check(voice.playing and voice.stream==stream and voice.global_position.distance_to(actor.bone_point("spine_03"))<0.01,"Character burn sound absent or wrong position"):return
 actor.position+=Vector3(3,0,2);visual._process(0.1)
 if not check(voice.global_position.distance_to(actor.bone_point("spine_03"))<0.01,"Burn sound does not follow actor"):return
 world.audio.muted=true;visual._process(0.1)
 if not check(not voice.playing,"Burn ignores mute"):return
 world.audio.muted=false;visual._process(0.1)
 if not check(voice.playing,"Burn fails to resume after mute"):return
 actor.cleanse_burn();visual._process(0.0)
 if not check(not voice.playing,"Cleansed actor still sounds burning"):return
 for normal in [Vector3.UP,Vector3.RIGHT]:
  var fire=world.spell_environment.surface_fire(Vector3(2,1,2),normal,0.5,{})
  if not check(fire.burn_audio.playing and fire.burn_audio.stream==stream and fire.burn_audio.max_distance==24 and fire.burn_audio.unit_size==3,"Surface does not share spatial loop"):return
  fire.fade(0.0)
  if not check(not fire.burn_audio.playing,"Expired surface loop continues"):return
  fire.queue_free()
 var patch=world.spell_environment.ground_fire(Vector3(6,0,0),0.5,{})
 var weak:WeakRef=weakref(patch.burn_audio)
 world.spell_environment.patches.append({"node":patch})
 world.spell_environment.reset_environment()
 await process_frame;await process_frame
 if not check(weak.get_ref()==null,"Scene reset leaves an orphan burning sound"):return
 print("BURNING AUDIO PASS: one cached seamless loop; follows burning actor; cleanse/mute; wall and floor spatial sources; expiry/reset cleanup")
 quit()
