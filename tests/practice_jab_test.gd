extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
const Camera=preload("res://scripts/third_person_camera.gd")
func _initialize():call_deferred("run")
func run():
 for item in [["Shield",10.0],["Absorb",20.0],["Reflect",30.0]]:
  var base=Rules.self_barrier_base();base.mana=Rules.barrier_base_mana(item[0])
  assert(is_equal_approx(Rules.mana_cost(Rules.author(base,1.0,0.3,false)),item[1]))
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var e=current_scene;var b=e.spell_builder;var actor=e.actor
 b.draft_path="user://logs/jab_draft.cfg";b.preview_preferences_path="user://logs/jab_preview.cfg"
 b.select_demo_choice("block",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 b.choose_barrier_kind("Shield");b.confirm_barrier_kind()
 b.barrier_tester.set_paused(true)
 var puncher=b.barrier_puncher
 actor.invulnerability=0.0
 var old_damage:float=actor.damage_taken;var serial:int=e.field.shot_serial
 puncher.clock=3.99
 var limit:=Time.get_ticks_msec()+2500
 while actor.damage_taken==old_damage and Time.get_ticks_msec()<limit:await process_frame
 assert(actor.damage_taken>old_damage,"CPU jab never dealt contact damage at its normal spawn")
 assert(e.field.shot_serial==serial and actor.burn_time==0.0,"CPU jab released a spell or elemental effect")
 puncher.set_paused(true);puncher.unit.position+=Vector3(7,0,0)
 b.reset_practice_scene()
 for tester in [b.barrier_tester,b.barrier_puncher]:tester.set_paused(true);tester.unit.position+=Vector3(10,0,0)
 var target=b.practice_human
 target.practice_return_enabled=false
 b.set_third_person_focus(null)
 var heading:Vector3=Camera.movement_facing(e.field,actor)
 actor.rotation.y=atan2(heading.x,heading.z)
 target.global_position=e.field.surface_placement(actor.global_position+heading*0.9)
 target.rotation.y=actor.rotation.y+PI;target.invulnerability=0.0
 for i in 3:await physics_frame
 old_damage=target.damage_taken
 var mana:float=actor.mana;var stamina:float=actor.stamina
 var key:=InputEventKey.new();key.keycode=KEY_2;key.physical_keycode=KEY_2;key.pressed=true
 b._input(key)
 assert(actor.mode=="punch" and actor.attack_kind=="left_cross" and actor.melee_spec[2]=="hand_l")
 assert(actor.mana==mana and actor.stamina<stamina,"Jab should cost stamina only")
 limit=Time.get_ticks_msec()+2000
 while target.damage_taken==old_damage and Time.get_ticks_msec()<limit:await process_frame
 assert(target.damage_taken>old_damage,"Player's 2-key jab did not hit on contact")
 assert(e.field.shot_serial==serial and target.burn_time==0.0)
 while actor.mode=="punch":await physics_frame
 var dealt:float=target.damage_taken
 target.global_position=e.field.surface_placement(actor.global_position+heading*8.0);target.invulnerability=0.0
 b.practice_left_jab()
 while actor.mode=="punch":await physics_frame
 assert(target.damage_taken==dealt,"Jab dealt damage without physical contact")
 print("PRACTICE JAB PASS: cheap Shield/Absorb/Reflect base costs; CPU jab real touch damage; 2-key right-hand strike, stamina only, no projectile/effect, misses at distance")
 quit()
