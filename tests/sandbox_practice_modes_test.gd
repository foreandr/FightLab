extends SceneTree
var screen
var builder
var controller
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func key(code:int):
 var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true
 builder._input(event)
func step():
 await physics_frame
 controller.step(1.0/60.0);screen.field.tick_combat(1.0/60.0)
 builder.move_caster(1.0/60.0,Vector2.ZERO,false);builder.process_demo_preview(1.0/60.0)
func reset_at(distance:float):
 controller.set_behavior("Passive");builder.stop_preview_controls(true)
 screen.field.clear_battle_effects()
 for unit in screen.field.fighters:
  screen.field.combat().discard_cast_attempt(unit)
  unit.practice_god_mode=false;unit.reset_fighter(Vector3.ZERO)
 screen.actor.editor_pose_locked=true;screen.actor.mode="review"
 screen.target.position=Vector3(0,0,distance);screen.target.rival=screen.actor
 screen.actor.rival=screen.target
 screen.target.rotation.y=PI;screen.actor.rotation.y=0
 screen.target.practice_return_enabled=false;screen.target.brain_enabled=false
 for i in 10:await step()
func run():
 Engine.physics_ticks_per_second=240;Engine.time_scale=4.0
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 screen=current_scene;builder=screen.spell_builder;controller=screen.target_behavior
 while not screen.animation_browser.ready_catalog:await process_frame
 await process_frame
 var point:Vector2=screen.field.camera.unproject_position(screen.target.bone_point("spine_03"))
 assert(screen.arena_area.get_global_rect().has_point(point),"Target is outside preview")
 var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=point
 screen._input(click)
 assert(controller.menu.visible and screen.focused_unit==screen.target,"Left-click did not open selected target behavior picker")
 controller.menu.hide();await process_frame
 screen.field.set_physics_process(false);controller.set_physics_process(false);builder.set_process(false);builder.set_physics_process(false)
 var boxes:bool=builder.preview_hitboxes;var numbers:bool=screen.field.combat_numbers_visible
 key(KEY_F1);assert(builder.preview_hitboxes!=boxes)
 key(KEY_F2);assert(screen.field.combat_numbers_visible!=numbers)
 assert(builder.projectile_hitbox_button.text.contains("F1") and builder.combat_numbers_button.text.contains("F2"))
 key(KEY_F1);key(KEY_F2)
 await reset_at(0.75)
 builder.set_third_person_focus(screen.target)
 var hitboxes:bool=builder.preview_hitboxes
 var mana:float=screen.actor.mana
 key(KEY_2)
 assert(screen.actor.mode=="punch" and screen.actor.melee_spec[2]=="hand_r" and screen.actor.melee_spec[0]=="right_jab")
 assert(builder.preview_hitboxes==hitboxes and screen.actor.mana==mana)
 var damage:float=screen.target.damage_taken
 for i in 70:await step()
 assert(screen.target.damage_taken>damage,"Right jab did not physically connect")
 await reset_at(0.78);screen.actor.practice_god_mode=true
 var started:int=controller.attacks_started;damage=screen.actor.damage_taken
 controller.set_behavior("Repeat left punch")
 for i in 200:await step()
 assert(controller.attacks_started>=started+2 and screen.actor.damage_taken>damage,"Repeat punches did not land")
 await reset_at(5.0);screen.actor.practice_god_mode=true
 var shots:int=screen.field.shot_serial;damage=screen.actor.damage_taken
 controller.set_behavior("Repeat left-punch fireball")
 for i in 300:await step()
 assert(screen.field.shot_serial>=shots+2 and screen.actor.damage_taken>damage,"Repeat fireballs did not launch/hit")
 controller.set_behavior("Passive")
 var attempts:int=controller.attacks_started
 for i in 150:await step()
 assert(controller.attacks_started==attempts,"Passive target kept starting attacks")
 await reset_at(0.8);screen.actor.health=10
 controller.set_behavior("Fight me")
 assert(controller.brain!=null and controller.brain.loadout.size()>20)
 for i in 1800:
  await step()
  if screen.actor.health<=0 or screen.target.health<=0:break
 assert(screen.actor.health<=0 or screen.target.health<=0,"Fight did not reach a death")
 assert(not controller.brain.counts.is_empty(),"Fight did not use the shared CPU brain")
 controller.set_behavior("Passive")
 await reset_at(0.8)
 builder.select_demo_choice("cross",false);builder.stop_preview_controls(true);builder.confirm_demo_choice()
 builder.choose_delivery_type("Barrier");builder.stop_preview_controls(true);builder.confirm_delivery_type()
 builder.choose_barrier_kind("Shield");builder.confirm_barrier_kind()
 assert(screen.field.fighters.size()==2 and not is_instance_valid(builder.barrier_tester) and not is_instance_valid(builder.barrier_puncher),"Sandbox spawned duplicate legacy practice units")
 while screen.animation_browser.thumbnails.busy or not screen.animation_browser.thumbnails.jobs.is_empty():await process_frame
 print("SANDBOX PRACTICE PASS: F1/F2, real mirrored right-jab [2] contact, repeated left punches and fireballs land, passive stops attacks, shared CPU fight reaches death")
 quit()
