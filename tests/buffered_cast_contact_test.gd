extends SceneTree
const Contact=preload("res://scripts/melee_contact.gd")
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func key(b:Node,code:int,down:bool)->void:
 var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=down;b._input(event)
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var b=s.spell_builder;var browser=s.animation_browser
 while not browser.ready_catalog:await process_frame
 b.saved_spells.directory="user://logs/buffer_contact_"+Crypto.new().generate_random_bytes(4).hex_encode()
 b.draft_path="user://logs/buffer_contact_draft.cfg";b.preview_preferences_path="user://logs/buffer_contact_preview.cfg"
 var saved:Dictionary=b.saved_spells.save("Physical Touch",load("res://scripts/spell_definition.gd").make("None","Touch",{"size":0.5,"speed":0.5},{}))
 browser.spell_catalog.reload_catalog();assert(browser.spell_catalog.select_spell(saved.record.id))
 s.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
 root.grab_focus();await process_frame
 key(b,KEY_3,true)
 var knee:Dictionary=b.playback_animation().duplicate(true)
 key(b,KEY_2,true)
 assert(b.cast_input_buffer.pending and b.held_cast.active)
 b.process_demo_preview(0.05)
 assert(is_zero_approx(b.cast_input_buffer.seconds),"Charged two unreleased windups simultaneously")
 key(b,KEY_3,false)
 assert(b.cast_input_buffer.pending and b.playback_animation().attack_bone=="calf_r","Early hold replaced the knee pose")
 var waited:=0.0
 while b.held_practice_shortcut.active_action!="cross" and waited<2.0:
  b.process_demo_preview(0.01);waited+=0.01
 assert(b.held_cast.active and b.playback_animation().attack_bone=="hand_l")
 assert(is_equal_approx(b.held_cast.seconds,waited/b.held_cast.charge_duration),"Buffered hold time lost at combo transition")
 assert(b.held_cast.charge_duration>0.7 and b.held_cast.charge_duration<1.7)
 var goal:float=b.held_cast.charge_duration*1.1
 while waited<goal-0.00001:
  var dt:=minf(0.01,goal-waited);b.process_demo_preview(dt);waited+=dt
 var quote:Dictionary=b.demo_preview_spec()
 assert(quote.cast_charge_tier==3 and is_equal_approx(quote.damage,20.0),"Overlapping hold missed its animation-relative perfect")
 var before:float=s.actor.stamina
 key(b,KEY_2,false)
 for i in 100:
  b.process_demo_preview(0.01)
  if b.released:break
 assert(b.released and is_equal_approx(s.actor.stamina,before-quote.stamina_cost),"Next attack payment missing or doubled")
 print("BUFFER PERFECT PASS: knee continues, early 2 hold carries into animation-relative perfect, one next payment")
 b.held_practice_shortcut.cancel(b);b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
 key(b,KEY_4,true);key(b,KEY_4,false);key(b,KEY_2,true);key(b,KEY_2,false)
 assert(b.cast_input_buffer.pending and b.cast_input_buffer.key_released)
 for i in 200:
  b.process_demo_preview(0.01)
  if b.held_practice_shortcut.active_action=="cross" and b.released:break
 assert(b.released and b.playback_animation().attack_bone=="hand_l" and not b.held_cast.active)
 assert(is_equal_approx(b.committed_spec.damage,10.0),"Queued tap kept charging after release")
 b.held_practice_shortcut.cancel(b);b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
 key(b,KEY_3,true);key(b,KEY_3,false);key(b,KEY_2,true)
 b.stop_preview_controls(true)
 assert(not b.cast_input_buffer.pending)
 for i in 100:b.process_demo_preview(0.01)
 assert(not b.held_cast.active,"Reset left a buffered cast armed")
 var hold=load("res://scripts/held_cast_preview.gd")
 assert(not is_equal_approx(hold.charge_window(knee),hold.charge_window({"source_duration":0.4})),"All charge windows still fixed at one second")
 var animation:Dictionary={"duration":1.0,"source_duration":1.0,"group":"Attack","animation_type":"Arm","attack_bone":"hand_l"}
 var compiled:Dictionary=load("res://scripts/spell_definition.gd").compile(saved.record,animation,{"hold_seconds":hold.charge_window(animation)*1.1})
 assert(compiled.cast_charge_tier==3 and is_equal_approx(compiled.damage,20.0),"Saved spell binding uses a different charge clock")
 print("BUFFER INPUT PASS: released queue executes once at stored charge, reset cancels, per-animation timing")
 # A grazing hit beyond the old 14 cm sphere now hits with knees/feet, not hands.
 var victim=s.target;victim.health=100;victim.invulnerability=0.0
 var sensor:=Area3D.new();sensor.collision_layer=s.field.enemy_hurt_mask(s.actor.team);sensor.collision_mask=0
 sensor.set_meta("fighter",victim);sensor.set_meta("zone","chest")
 var shape:=CollisionShape3D.new();var sphere:=SphereShape3D.new();sphere.radius=0.05;shape.shape=sphere;sensor.add_child(shape);s.field.add_child(sensor)
 var point:=Vector3(0,30,0);sensor.global_position=point+Vector3.RIGHT*0.28
 await physics_frame;await physics_frame
 var strike:Dictionary={"id":"contact_test","clock":0.5,"begin":0.0,"end":1.0,"previous":point,"limb":point,"forward":Vector3.BACK,"min_speed":0.0,"dynamic_damage":false,"pre_scaled":true,"radius":0.14,"damage":10.0,"bone":"hand_r"}
 assert(not Contact.resolve(s.actor,strike,0.016),"Hand radius unintentionally enlarged")
 strike.bone="calf_r"
 assert(Contact.resolve(s.actor,strike,0.016),"Knee grazing hit still missed")
 assert(victim.health<100.0)
 assert(is_equal_approx(Contact.radius_for("calf_l"),0.26) and is_equal_approx(Contact.radius_for("foot_l"),0.28) and is_equal_approx(Contact.radius_for("ball_r"),0.28))
 s.actor.touch_contact_visual.set_preview({"touch_contacts":["calf_r","foot_l"]})
 s.field.set_combat_hitboxes(true)
 var overlay=s.field.character_hitbox_overlays;overlay.refresh()
 for bone in ["calf_r","foot_l"]:
  var outline:MeshInstance3D=overlay.contact_outlines[str(s.actor.get_instance_id())+":"+bone]
  assert(outline.visible and is_equal_approx(float(outline.get_meta("collision_radius")),Contact.radius_for(bone)))
  assert(outline.global_position.distance_to(s.actor.bone_point(bone))<0.001)
  assert(absf(outline.mesh.get_aabb().size.x-Contact.radius_for(bone)*2.0)<0.001)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/larger_contact_wireframes.png")
 s.field.set_combat_hitboxes(false)
 for outline in overlay.contact_outlines.values():assert(not outline.visible)
 print("CONTACT VOLUME PASS: larger knee/foot grazing contacts, unchanged hands, cyan wireframes match actual radius and follow bones")
 sensor.queue_free()
 while browser.thumbnails.busy or not browser.thumbnails.jobs.is_empty():await process_frame
 for record in b.saved_spells.entries():DirAccess.remove_absolute(b.saved_spells.directory.path_join(record.id+".cfg"))
 DirAccess.remove_absolute(b.saved_spells.directory)
 print("BUFFERED CAST AND CONTACT PASS")
 quit()
