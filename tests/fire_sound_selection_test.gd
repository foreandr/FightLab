extends SceneTree
const Sounds=preload("res://scripts/fire_sound_catalog.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 var hashes:Dictionary={}
 for entry in Sounds.ENTRIES:
  var stream:=Sounds.synthesize(entry.id)
  if not check(stream!=null and stream.get_length()>0.3 and stream.data.size()>1000,"Empty sound"):return
  if not check(stream.format==AudioStreamWAV.FORMAT_16_BITS and not stream.stereo,"Fire sound is not mono PCM16"):return
  if entry.has("file"):
   if not check(FileAccess.get_sha256(entry.file)==entry.sha256 and entry.has("source_sha256") and entry.has("license"),"Downloaded sound loses hash or credits"):return
  var signature:=hash(stream.data)
  if not check(not hashes.has(signature),"Duplicate fire sound"):return
  hashes[signature]=true
 if not check(hashes.size()==Sounds.ENTRIES.size() and Sounds.resolve({"projectile_element":"Fire"})==Sounds.DEFAULT_ID and Sounds.resolve({"projectile_element":"None","sound_id":"fire_roar"})=="dash","Default sound routing"):return
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 var b=e.spell_builder
 b.draft_path="user://logs/fire_sound_draft_test.cfg"
 b.preview_preferences_path="user://logs/fire_sound_preview_test.cfg"
 e.select_group("Spells");b.select_demo_choice("cross",false);b.open_projectile_workspace();b.stop_preview_controls(true)
 b.set_process(false);b.set_physics_process(false);e.field.set_physics_process(false)
 e.actor.practice_god_mode=true
 b.appearances.erase("Fire")
 b.preview_projectile_effect("Fire");b.stop_preview_controls(true)
 var initial:Dictionary=b.demo_preview_spec()
 if not check(initial.sound_id==Sounds.DEFAULT_ID,"Fire fails to default immediately before confirming style"):return
 b.set_fire_style(preload("res://scripts/fire_style_catalog.gd").entries()[0].id)
 b.confirm_fire_style()
 if not check(b.fire_sound_screen.is_visible_in_tree() and not b.fire_shape_screen.is_visible_in_tree() and b.fire_sound_choices.size()==mini(12,Sounds.ENTRIES.size()),"Missing next-tier sounds"):return
 for button in b.fire_sound_choices.values():
  var image:TextureRect=button.find_child("PreviewImage",true,false)
  if not check(image!=null and image.texture!=null and button.custom_minimum_size==Vector2(82,108) and button.focus_mode==Control.FOCUS_ALL,"Sound does not use the shared image card"):return
 if not check(b.fire_sound_gallery.grid.columns==4 or b.fire_sound_gallery.grid.columns==3,"Sound gallery does not adapt columns"):return
 var stamina:float=e.actor.stamina;var mana:float=e.actor.mana
 for i in Sounds.ENTRIES.size():
  var entry:Dictionary=Sounds.ENTRIES[i]
  b.fire_sound_gallery.set_page(floori(i/12.0))
  b.fire_sound_choices[entry.id].pressed.emit()
  if not check(e.field.audio.played.get(entry.id,0)>0,"Click did not audition sound"):return
 if not check(e.actor.stamina==stamina and e.actor.mana==mana,"Audio audition spends resources"):return
 b.fire_sound_gallery.set_page(0)
 b.set_fire_sound("fire_roar")
 b.save_draft()
 var cfg:=ConfigFile.new();cfg.load(b.draft_path)
 if not check(not cfg.get_value("appearance","elements",{}).Fire.has("sound_id"),"Unconfirmed sound saved"):return
 b.play_projectile_once();b.process_demo_preview(b.cast_duration()*b.release_fraction+0.001)
 if not check(e.field.shots.back().spec.sound_id=="fire_roar" and e.field.audio.played.get("fire_roar",0)>=2,"Actual cast ignores selected sound"):return
 b.confirm_fire_sound();cfg.load(b.draft_path)
 if not check(cfg.get_value("appearance","elements",{}).Fire.sound_id=="fire_roar","Confirmed sound not saved"):return
 b.stop_preview_controls(true);b.open_fire_shape_picker()
 b.confirm_fire_style()
 if not check(b.fire_sound_preview_id=="fire_roar","Back and reenter loses saved selection"):return
 # Actual downloaded audio routes through the same cast and save path.
 b.set_fire_sound("lentikula_fire_4")
 var cursor_before:int=e.field.audio.cursor
 b.play_projectile_once()
 b.process_demo_preview(b.cast_duration()*b.release_fraction-0.001)
 if not check(e.field.audio.cursor==cursor_before,"Cast sound fires before release marker"):return
 b.process_demo_preview(0.002)
 if not check(e.field.audio.cursor==cursor_before+1,"Release marker does not fire one sound"):return
 if not check(e.field.audio.streams.has("lentikula_fire_4") and e.field.shots.back().spec.sound_id=="lentikula_fire_4","Downloaded sound not played on actual release"):return
 var released_voice:AudioStreamPlayer3D=e.field.audio.voices[(e.field.audio.cursor-1)%e.field.audio.voices.size()]
 if not check(released_voice.pitch_scale==1.0 and released_voice.stream.get_length()<=preload("res://scripts/spell_audio_rules.gd").release_window(b.demo_preview_spec())+0.001,"Create sound is not a short native-pitch release accent"):return
 b.confirm_fire_sound();cfg.load(b.draft_path)
 if not check(cfg.get_value("appearance","elements",{}).Fire.sound_id=="lentikula_fire_4","Downloaded sound does not save"):return
 b.fire_sound_gallery.set_page(b.fire_sound_gallery.page_count()-1)
 if not check(b.fire_sound_choices.size()==1 and b.fire_sound_gallery.next_button.disabled,"Sound pagination last page wrong"):return
 b.fire_sound_gallery.set_page(0)
 # Same release route in a completely new mode, without Create or Story adapters.
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false)
 var actor:CharacterBody3D=world.spawn_combatant(0,Vector3.ZERO);actor.practice_god_mode=true
 world.round_active=true
 world.combat().release(actor,{"effect":"orb","projectile_element":"Fire","appearance":{"sound_id":"fire_hiss"},"mana":0,"damage":0},Vector3.UP)
 if not check(world.audio.played.get("fire_hiss",0)==1,"New mode bypasses shared fire selection"):return
 b.open_fire_sound_picker()
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/fire_sound_selection.png")
 if not check(b.fire_sound_confirm_button.get_global_rect().end.y<b.spell_playback_panel.get_global_rect().position.y,"Sound cards push Confirm below toolbar"):return
 print("FIRE SOUND PASS: ",Sounds.ENTRIES.size()," unique nonempty sounds; default Fire; next-tier preview/confirm/back/save; no audition costs; actual Create and new-mode releases")
 quit()
