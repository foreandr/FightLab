extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var sandbox=current_scene;var browser=sandbox.animation_browser;var builder=sandbox.spell_builder
 assert(builder.draft_path=="user://sandbox_spell_draft.cfg" and builder.preview_preferences_path=="user://sandbox_spell_preview.cfg")
 var deadline:=Time.get_ticks_msec()+60000
 while not browser.ready_catalog and Time.get_ticks_msec()<deadline:await process_frame
 assert(browser.ready_catalog,"Catalog did not finish loading")
 assert(browser.records.size()>1000,"Sandbox exposes only a short demo list")
 assert(browser.grid.get_child_count()<=12 and browser.detail_loads==0,"Catalog loaded all animation resources")
 assert(sandbox.field.fighters.size()==2 and not sandbox.target.practice_wooden_dummy and sandbox.target.model.visible)
 assert(sandbox.target.get_node("OverheadHealthTag").name_label.text=="Human target")
 for kind in ["Arm","Leg","Head","Movement"]:
  browser.set_type(kind)
  assert(not browser.matches_.is_empty())
  for record in browser.matches_:assert(record.store_animation_type==kind)
 browser.set_type("All");browser.turn_page(1);assert(browser.page==1 and browser.grid.get_child_count()<=12 and browser.detail_loads==0)
 var chosen:Dictionary={}
 for record in browser.records:
  if record._origin=="Built-in" and record.clip=="fight/backfist":chosen=record;break
 assert(not chosen.is_empty())
 builder.demo_duration=2.3
 assert(browser.select_animation(chosen))
 assert(builder.creation_step=="demo" and builder.casting_animation.clip=="fight/backfist" and is_equal_approx(builder.demo_duration,2.3))
 assert(builder.demo_choice_selected and builder.demo_offensive() and not browser.confirm.disabled)
 browser.confirm_selection();assert(builder.creation_step=="delivery","Arbitrary animation cannot confirm")
 builder.show_creation_step("demo")
 browser.source_filter.select(3);browser.search.text="walk";browser.apply_filters()
 assert(not browser.matches_.is_empty())
 for record in browser.matches_:assert(record._origin=="Community")
 assert(browser.detail_loads==0)
 assert(browser.select_animation(browser.matches_[0]),"Community source did not play")
 assert(browser.detail_loads==1 and sandbox.actor.player.has_animation(builder.casting_animation.clip))
 var before:Vector3=sandbox.actor.bone_point("foot_l")
 builder.process_demo_preview(0.25)
 var after:Vector3=sandbox.actor.bone_point("foot_l")
 assert(before.distance_to(after)>0.001,"Imported preview has no visible limb motion")
 assert(builder.creation_step=="demo")
 browser.confirm_selection();assert(builder.creation_step=="delivery")
 builder.reset_training_dummy();assert(not sandbox.target.practice_wooden_dummy and sandbox.target.model.visible)
 browser.source_filter.select(0);browser.search.text="punch -jump";browser.apply_filters()
 for record in browser.matches_:assert(str(record._search).contains("punch") and not str(record._search).contains("jump"))
 print("SANDBOX LIBRARY PASS: ",browser.records.size()," animations; own/builtin/community; all four types, search, paged 12; metadata-only browse; non-demo Backfist + real community preview/confirm; duration retained; human-only targets/reset")
 quit()
