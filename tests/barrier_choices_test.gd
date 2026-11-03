extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var screen=current_scene
 var b=screen.spell_builder
 b.draft_path="user://logs/barrier_choices_draft.cfg";b.preview_preferences_path="user://logs/barrier_choices_preview.cfg"
 b.select_demo_choice("block",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 assert(b.creation_step=="barrier" and b.barrier_screen.visible and b.demo_timing_panel.visible)
 assert(b.barrier_choices.keys()==["Shield","Absorb","Reflect","Effect"])
 for kind in b.barrier_choices:
  var option:Button=b.barrier_choices[kind]
  assert(option.disabled==(kind!="Shield") and option.icon!=null)
 var shots:int=screen.field.shot_serial
 b.barrier_choices.Shield.pressed.emit()
 assert(b.barrier_kind=="Shield" and b.barrier_choices.Shield.button_pressed)
 for kind in ["Absorb","Reflect","Effect"]:b.choose_barrier_kind(kind)
 assert(b.barrier_kind=="Shield" and screen.field.shot_serial==shots,"Disabled choice or unintended projectile")
 b.show_creation_step("delivery");b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 assert(b.barrier_choices.Shield.button_pressed,"Back navigation lost selection")
 assert(not b.barrier_confirm_button.disabled)
 b.barrier_confirm_button.pressed.emit()
 assert(b.creation_step=="shield" and b.barrier_title.text=="Shield" and not b.barrier_confirm_button.visible)
 var tester=b.barrier_tester
 assert(is_instance_valid(tester) and screen.field.fighters.size()==4 and tester.unit.visible)
 tester.set_physics_process(false)
 b.set_physics_process(false)
 for i in 4:await physics_frame
 tester.clock=0.0
 var started:int=tester.casts_started
 tester._physics_process(3.99)
 assert(tester.casts_started==started,"Attacker started before four seconds")
 var serial:int=screen.field.shot_serial
 tester._physics_process(0.02)
 assert(tester.casts_started==started+1 and tester.unit.mode=="cast","Attacker did not start shared cast")
 assert(tester.unit.practice_spell_animation.title=="Left jab" and tester.unit.current_spell.hand=="hand_l")
 tester.set_physics_process(true)
 var limit:=Time.get_ticks_msec()+2500
 while screen.field.shot_serial==serial and Time.get_ticks_msec()<limit:await process_frame
 assert(screen.field.shot_serial>serial,"Animated test caster never released a projectile")
 var fire_found:=false
 for shot in screen.field.shots:
  if shot.caster==tester.unit:
   fire_found=shot.spec.projectile_element=="Fire" and shot.spec.hand=="hand_l"
 assert(fire_found,"Caster did not release its left-hand fireball")
 limit=Time.get_ticks_msec()+3000
 while screen.actor.damage_taken<=0.0 and Time.get_ticks_msec()<limit:await process_frame
 if screen.actor.damage_taken<=0.0:
  print("AIM DEBUG ",tester.unit.global_position," target ",screen.actor.global_position," aim ",tester.unit.current_spell.get("aim_direction")," health ",screen.actor.health," hits ",screen.field.hits," events ",screen.field.events.slice(-6)," targets ",screen.actor.targets.map(func(t):return t[0].collision_layer))
 assert(screen.actor.damage_taken>0.0,"Test fireball did not hit the player")
 b.reset_practice_scene()
 assert(tester.clock==0.0 and tester.unit.visible and screen.actor.health==screen.actor.MAX_HEALTH)
 assert(screen.field.fighters.size()==4 and tester.unit.global_position.distance_to(screen.target.practice_home)>2.5)
 b.return_to_start();tester._physics_process(0.0)
 assert(b.barrier_kind.is_empty() and not b.barrier_choices.Shield.button_pressed and not tester.unit.visible)
 print("BARRIER TESTER PASS: Confirm reaches Shield; one extra NPC, four-second cadence, real left-jab fireball hits player via shared combat, reset heals/repositions, leaving Barrier stops caster")
 quit()
