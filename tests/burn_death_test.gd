extends SceneTree
const Burn=preload("res://scripts/burn_rules.gd")
const Death=preload("res://scripts/burn_death.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 while current_scene==null or not bool(current_scene.get("default_unit_ready")) or is_instance_valid(current_scene.get("loading_layer")):await process_frame
 var editor=current_scene
 editor.select_group("Spells")
 var b=editor.spell_builder
 b.draft_path="user://logs/burn_death_test.cfg";b.preview_preferences_path="user://logs/burn_death_preview.cfg"
 b.select_demo_choice("cross",false);b.open_projectile_workspace();b.preview_projectile_effect("Fire");b.stop_preview_controls(true)
 var world=editor.field
 world.set_physics_process(false);world.round_active=true
 b.set_process(false);b.set_physics_process(false)
 var target=b.practice_human
 target.set_physics_process(false);target.brain_enabled=false;target.editor_pose_locked=true
 target.practice_god_mode=false;target.practice_damageable_dummy=true;target.practice_immortal=true
 target.health=Burn.TICK_DAMAGE*0.5
 target.receive_status(editor.actor,{"projectile_element":"Fire","potency":1.0})
 target.update_status(Burn.TICK_INTERVAL)
 if not check(target.health==0.0 and is_instance_valid(target.burn_death),"Actual fatal burn tick does not begin death sequence on damageable human"):return
 if not check(target.ragdoll_count==1,"Burn death creates more than one ragdoll"):return
 var effect=target.burn_death
 effect.set_physics_process(false)
 target.status_visual._process(0.0)
 target.burn_visual._process(0.0)
 if not check(target.burn_visual.burn_audio.playing,"Fatal burn immediately loses flames and burning sound"):return
 if not check(not effect.materials.is_empty() and effect.materials[0].get_shader_parameter("progress")==0.0,"Missing isolated ash materials"):return
 var original:Dictionary=effect.originals[0]
 var shared_material:Material=original.surfaces[0]
 var original_next:Material=shared_material.next_pass if shared_material!=null else null
 # Own corpse updates even with editor pose ownership and round over.
 world.round_active=false
 for i in 35:
  effect._physics_process(1.0/60.0)
  await physics_frame
 if not check(effect.age>0.5 and not is_instance_valid(effect.ash) and target.ragdoll.setup_phase==2,"Writhing phase cannot advance after round end / pose lock"):return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/burn_death_writhe.png")
 effect._physics_process(Death.WRITHE_SECONDS-effect.age+Death.ASH_SECONDS*0.4)
 if not check(is_instance_valid(effect.ash) and effect.materials[0].get_shader_parameter("progress")>0.35,"Ash transition missing"):return
 await create_timer(0.4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/burn_death_dissolve.png")
 effect._physics_process(Death.ASH_SECONDS)
 target.burn_visual._process(0.0)
 if not check(target.targets[0][0].collision_layer==0,"Ash retains character hitboxes"):return
 if not check(effect.finished and target.ragdoll==null and not original.node.visible and not target.burn_visual.burn_audio.playing,"Ash state leaves body/physics/audio active"):return
 if not check(shared_material==null or shared_material.next_pass==original_next,"Dissolve mutated original shared material"):return
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/burn_death_ash.png")
 var ash_ref:WeakRef=weakref(effect.ash)
 target.reset_fighter(target.practice_home)
 if not check(target.burn_death==null and original.node.visible and original.node.get_surface_override_material(0)==shared_material,"Reset does not restore visible body/materials"):return
 await process_frame;await process_frame
 if not check(ash_ref.get_ref()==null,"Reset leaves ash remains"):return
 target.practice_immortal=false;target.health=0.0
 target.enter_death(editor.actor,Vector3.ZERO,target.bone_point("pelvis"))
 if not check(not is_instance_valid(target.burn_death),"Physical death accidentally turns to ash"):return
 target.reset_fighter(target.practice_home)
 target.practice_god_mode=true;target.health=100
 target.receive_status(editor.actor,{"projectile_element":"Fire","potency":1000.0})
 target.update_status(0.5)
 if not check(target.health==100 and not is_instance_valid(target.burn_death),"God mode can burn to death"):return
 print("BURN DEATH PASS: fatal burn tick, brief corpse writhe, charred dissolve/ash, audio, round-end/pose-lock independence, original material isolation, reset; physical death and God mode unchanged")
 quit()
