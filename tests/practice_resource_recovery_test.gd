extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/spell_creation.tscn")
 while current_scene==null or not current_scene.workspace_ready:await process_frame
 var screen=current_scene
 var b=screen.spell_builder
 b.draft_path="user://logs/practice_resource_draft.cfg";b.preview_preferences_path="user://logs/practice_resource_preview.cfg"
 b.select_demo_choice("block",false);b.stop_preview_controls(true);b.confirm_demo_choice()
 b.choose_delivery_type("Barrier");b.stop_preview_controls(true);b.confirm_delivery_type()
 var field=screen.field
 field.set_physics_process(false);b.set_process(false);b.set_physics_process(false);b.barrier_tester.set_physics_process(false)
 var units:Array=[screen.target,b.practice_human,b.barrier_tester.unit]
 for unit in units:
  unit.practice_god_mode=false;unit.editor_pose_locked=false;unit.practice_return_enabled=true;unit.brain_enabled=false
  unit.mode="review";unit.mana=20;unit.stamina=40;unit.mana_delay=0.0;unit.stamina_delay=0.0
 for i in 10:field.tick_combat(0.1)
 for unit in units:
  assert(is_equal_approx(unit.mana,37.0) and is_equal_approx(unit.stamina,57.0),"Return-home resources did not recover exactly once at 17/s: "+str(unit.name))
  unit.mana_delay=0.5;unit.stamina_delay=0.5
 field.tick_combat(0.1)
 for unit in units:assert(is_equal_approx(unit.mana,37.0) and is_equal_approx(unit.stamina,57.0),"Recovery ignored spend delay")
 for unit in units:unit.mana=99;unit.stamina=99;unit.mana_delay=0;unit.stamina_delay=0
 field.tick_combat(0.1)
 for unit in units:assert(unit.mana==unit.MAX_MANA and unit.stamina==unit.MAX_STAMINA,"Recovery overshot cap")
 print("PRACTICE RESOURCES PASS: real combat dummy, human target and barrier caster recover mana/stamina once at shared 17/s, respect delay, cap at max")
 quit()
