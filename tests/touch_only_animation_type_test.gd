extends SceneTree
const Type=preload("res://scripts/animation_cast_type.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
const Pose=preload("res://scripts/spell_cast_motion.gd")
const Locomotion=preload("res://scripts/creation_locomotion.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for delivery in ["Projectile","Beam","Targeted","Barrier"]:
  var baseline:Dictionary={}
  for kind in Type.TYPES:
   var base:=Rules.projectile_base("None");base.delivery_type=delivery;base.animation_type=kind
   var stats:=Rules.authored_stats(base,1.0,0.3,true)
   var spec:=Rules.author(base,1.0,0.3,true)
   assert(not Type.applies(spec) and not Type.owns_legs(spec))
   assert(Type.physical_multiplier(spec)==1.0)
   assert(Type.recovery_weight(spec,0.8,1.0)==0.0)
   assert(Type.emitter({"delivery_type":delivery,"animation_type":kind,"attack_bone":"hand_l"})=="hand_l")
   if baseline.is_empty():baseline=stats
   for key in ["physical_damage","stationary_damage","mana","stamina","burn_dps","radius","velocity"]:
    assert(is_equal_approx(float(stats[key]),float(baseline[key])),delivery+" type changes "+key)
 for kind in Type.TYPES:
  var profile={"delivery_type":"Touch","animation_type":kind}
  assert(Type.applies(profile))
  assert(Type.owns_legs(profile)==(kind in [Type.LEGS,Type.WHOLE_BODY]))
  assert(is_equal_approx(Type.physical_multiplier(profile),1.2 if kind==Type.LEGS else 1.0))
 # Metadata retains its meaning when editing a standalone animation.
 assert(Type.owns_legs({"animation_type":"Movement"}))
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 e.select_group("Spells")
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/touch_type_ui_test.cfg";b.draft_path="user://logs/touch_type_draft_test.cfg"
 b.set_process(false);b.set_physics_process(false);e.field.set_physics_process(false)
 b.stop_preview_controls(true);b.show_creation_step("demo");b.delivery_type="Projectile";b.refresh_demo_choices();b.refresh_demo_timing()
 assert(not b.spell_sections["Animation type"].visible)
 for badge in b.demo_type_labels.values():assert(not badge.visible)
 for choice in ["headbutt","cross","knee","dismantle"]:
  b.select_demo_choice(choice,false);b.stop_preview_controls(true)
  var profile:Dictionary=b.playback_animation()
  assert(profile.delivery_type=="Projectile" and not Type.applies(profile))
  assert(Locomotion.leg_takeover(profile)==0.0)
  e.actor.velocity=Vector3(7,0,0);Type.begin(e.actor,profile)
  assert(e.actor.get_meta("animation_cast_momentum").is_zero_approx())
  Pose.pose(e.actor,profile,0.5)
  var before:=Pose.capture(e.actor)
  Locomotion.cast_legs(e.actor,profile,Vector2.ZERO,0.2,false)
  var after:=Pose.capture(e.actor)
  for i in before.size():assert(before[i].is_equal_approx(after[i]),"Stationary non-Touch demo is type masked")
 # Touch remains disabled in the wizard; direct API verifies its future UI policy.
 b.delivery_type="Touch";b.refresh_demo_choices();b.refresh_demo_timing()
 assert(b.spell_sections["Animation type"].visible)
 for badge in b.demo_type_labels.values():assert(badge.visible)
 b.delivery_type="Projectile";b.refresh_demo_choices();b.refresh_demo_timing()
 assert(not b.spell_sections["Animation type"].visible and b.delivery_choices.Touch.disabled)
 print("TOUCH-ONLY TYPE PASS: non-Touch costs/damage/emitter/movement ignore type, metadata and Touch rules retained; actual Create hides type UI and stationary demos retain their complete pose")
 quit()
