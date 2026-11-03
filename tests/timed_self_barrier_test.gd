extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
const Overlay=preload("res://scripts/body_barrier_overlay.gd")
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var e=current_scene;var b=e.spell_builder;var actor=e.actor
 b.draft_path="user://logs/timed_barrier_draft.cfg";b.preview_preferences_path="user://logs/timed_barrier_preview.cfg"
 b.select_demo_choice("block",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 b.choose_barrier_kind("Shield");b.confirm_barrier_kind()
 for tester in [b.barrier_tester,b.barrier_puncher]:tester.set_paused(true)
 e.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 b.barrier_authoring.choose("Self")
 assert(not actor.self_barrier.active() and not b.barrier_authoring.preview.visible,"Selection activated a permanent barrier")
 b.barrier_authoring.confirm_choice()
 assert(b.previews_barrier())
 b.barrier_authoring.strength_slider.value=40.0;b.barrier_authoring.lifetime_slider.value=2.0
 b.demo_duration=1.0;b.casting_animation.duration=1.0;b.release_fraction=0.3
 b.refresh_demo_timing()
 var spec:Dictionary=b.demo_preview_spec()
 assert(spec.effect=="self_barrier" and spec.shield_duration==2.0 and spec.shield_strength>40.0)
 assert(b.demo_mana_cost_label.text=="Mana cost: %.1f"%Rules.mana_cost(spec))
 var mana:float=actor.mana;var serial:int=e.field.shot_serial
 b.play_projectile_once();b.process_demo_preview(0.29)
 assert(not actor.self_barrier.active() and is_equal_approx(actor.mana,mana))
 b.process_demo_preview(0.02)
 assert(actor.self_barrier.active() and is_equal_approx(actor.self_barrier.time_left,2.0))
 assert(is_equal_approx(actor.mana,mana-Rules.mana_cost(spec)))
 assert(e.field.shot_serial==serial,"Barrier spawned a projectile")
 var overlays:Array=Overlay.apply(actor.skeleton)
 assert(not overlays.is_empty() and overlays==Overlay.apply(actor.skeleton))
 Overlay.set_strength(overlays,0.0)
 for overlay in overlays:assert(float(overlay.get_shader_parameter("barrier_strength"))==1.0)
 b.process_demo_preview(0.7)
 assert(not b.playing and actor.self_barrier.active(),"Animation ending cleared the active shield")
 actor.tick(1.9);assert(actor.self_barrier.active())
 actor.tick(0.11);assert(not actor.self_barrier.active(),"Barrier did not expire")
 for overlay in overlays:assert(float(overlay.get_shader_parameter("barrier_strength"))==0.0)
 # Shared impact handling absorbs both melee and projectiles, consuming capacity.
 var attacker=b.barrier_puncher.unit
 actor.invulnerability=0.0
 e.field.combat().dispatch(actor,{"effect":"self_barrier","shield_strength":20.0,"shield_duration":5.0},actor.global_position)
 var hp:float=actor.health
 var point:Vector3=actor.bone_point("spine_03");var area:Area3D=actor.nearest_hurtbox(point)
 var attack={"effect":"melee","damage":10.0,"augment":false}
 assert(e.field.combat().apply_impact(attacker,actor,attack,point,Vector3.FORWARD,area))
 assert(actor.health==hp and is_equal_approx(actor.self_barrier.remaining,10.0))
 var fire={"effect":"orb","damage":15.0,"projectile_element":"Fire","potency":1.0}
 assert(e.field.combat().apply_impact(attacker,actor,fire,point,Vector3.FORWARD,area))
 assert(not actor.self_barrier.active() and is_equal_approx(actor.health,hp-5.0))
 actor.cleanse_burn();actor.invulnerability=0.0
 e.field.combat().dispatch(actor,{"effect":"self_barrier","shield_strength":20.0,"shield_duration":5.0},actor.global_position)
 assert(e.field.combat().apply_impact(attacker,actor,fire,point,Vector3.FORWARD,area))
 assert(actor.burn_time==0.0,"Fully shielded fire applied burn")
 b.reset_practice_scene()
 assert(not actor.self_barrier.active())
 print("TIMED SELF BARRIER PASS: no passive coating; animation/release activation, shared mana payment, no projectile, independent expiry, shield capacity absorbs melee/fire, full shield stops burn, reset clears")
 quit()
