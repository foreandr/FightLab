extends SceneTree
const Haste=preload("res://scripts/parry_cast_haste.gd")
func _initialize():call_deferred("run")
func run():
 var h=Haste.new()
 h.grant();assert(is_equal_approx(h.multiplier(),1.1))
 h.step(0.75);h.grant()
 assert(h.stacks==2 and h.time_left==1.0 and is_equal_approx(h.multiplier(),1.2))
 h.step(0.99);assert(h.stacks==2)
 h.step(0.02);assert(h.stacks==0 and h.multiplier()==1.0)
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var e=current_scene;var b=e.spell_builder;var actor=e.actor
 b.draft_path="user://logs/parry_haste_draft.cfg";b.preview_preferences_path="user://logs/parry_haste_preview.cfg"
 b.select_demo_choice("block",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 b.choose_barrier_kind("Shield");b.confirm_barrier_kind();b.barrier_authoring.choose("Self");b.barrier_authoring.confirm_choice()
 for tester in [b.barrier_tester,b.barrier_puncher]:tester.set_paused(true)
 e.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 var attacker=b.barrier_puncher.unit
 actor.invulnerability=0;actor.mana=100.0
 var baseline:Dictionary=b.demo_preview_spec()
 var strong:Dictionary=baseline.duplicate();strong.shield_strength=30.0
 e.field.combat().dispatch(actor,strong,actor.global_position)
 var point:Vector3=actor.bone_point("spine_03");var area:Area3D=actor.nearest_hurtbox(point)
 var attack={"effect":"orb","damage":10.0,"projectile_element":"None","potency":0.0}
 for i in 2:assert(e.field.combat().apply_impact(attacker,actor,attack,point,Vector3.FORWARD,area))
 assert(actor.parry_cast_haste.stacks==2 and actor.parry_cast_haste.time_left==1.0)
 assert(is_equal_approx(actor.cast_speed_multiplier(),1.2))
 assert(b.demo_preview_spec()==baseline,"Haste changed authored costs/damage")
 var mana:float=actor.mana
 b.play_projectile_once();b.process_demo_preview(0.2)
 assert(is_equal_approx(b.elapsed,0.24) and not b.released)
 b.process_demo_preview(0.06)
 assert(b.released and is_equal_approx(actor.mana,mana-float(baseline.mana)))
 b.stop_preview_controls(true)
 # Non-editor runtime casts use the same speed multiplier, without advancing status twice.
 actor.practice_spell_animation={};actor.mode="cast";actor.current_spell={"effect":"orb","release":0.5,"hand":"hand_r"};actor.cast_time=0.0;actor.cast_rate=1.0;actor.charge_goal=0.0;actor.did_release=false;actor.mode_length=1.0
 actor.tick_cast(0.2)
 assert(is_equal_approx(actor.cast_time,0.24) and actor.parry_cast_haste.time_left==1.0)
 actor.update_status(1.01)
 actor.tick_cast(0.2)
 assert(is_equal_approx(actor.cast_time,0.44) and actor.cast_speed_multiplier()==1.0)
 actor.parry_cast_haste.grant();b.reset_practice_scene()
 assert(actor.parry_cast_haste.stacks==0 and actor.cast_speed_multiplier()==1.0)
 print("PARRY CAST HASTE PASS: +10% per stack, each parry refreshes 1s, expires fully; actual parries grant it; Create and runtime cast clocks accelerate; authored costs unchanged; reset clears")
 quit()
