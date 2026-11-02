extends SceneTree
func _initialize():call_deferred("run")
func check(ok:bool,message:String) -> bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var e:Node
 while true:
  await process_frame;e=current_scene
  if e!=null and bool(e.get("default_unit_ready")) and not is_instance_valid(e.get("loading_layer")):break
 var b=e.spell_builder
 b.preview_preferences_path="user://logs/spell_sections_test.cfg";b.draft_path="user://logs/spell_sections_draft_test.cfg"
 e.select_group("Spells");b.set_process(false);b.set_physics_process(false)
 b.collapsed_spell_sections.clear()
 for section in b.spell_sections.values():section.set_collapsed(false,false)
 if not check(b.spell_sections.keys()==["Mana","Casting","Animation type","Power balance","Results"],"RHS section stack incomplete"):return
 var mana=b.spell_sections.Mana
 if not check(mana.content.is_ancestor_of(b.limiter_toggle) and mana.content.is_ancestor_of(b.demo_mana_cost_label) and mana.content.is_ancestor_of(b.test_inputs.mana),"Limiter/mana override separated from Mana cost"):return
 await process_frame
 var expanded:float=b.spell_sections.Results.get_parent().get_combined_minimum_size().y
 for title in b.spell_sections:
  var section=b.spell_sections[title]
  if not check(section.header.focus_mode==Control.FOCUS_ALL and section.header.icon!=null and section.header.icon_alignment==HORIZONTAL_ALIGNMENT_RIGHT,"Header lacks right arrow/keyboard focus"):return
  section.header.set_pressed(true)
  if not check(section.collapsed and not section.content.is_visible_in_tree(),"Header did not collapse "+title):return
 await process_frame
 var compact:float=b.spell_sections.Results.get_parent().get_combined_minimum_size().y
 if not check(compact<expanded-200,"Collapsed stack still reserves content height"):return
 b.set_demo_duration(2.5)
 if not check(b.demo_duration==2.5 and b.spell_sections.Casting.collapsed,"Live stats force folded Casting open or lose values"):return
 for section in b.spell_sections.values():section.set_collapsed(false,false)
 b.load_demo_preferences()
 for title in b.spell_sections:
  if not check(b.spell_sections[title].collapsed,"Fold preference not restored: "+title):return
 # Native focused header responds to the keyboard, not just scripted signals.
 var casting=b.spell_sections.Casting
 casting.header.grab_focus()
 var key:=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=true
 root.push_input(key,true)
 var release_key:=InputEventKey.new();release_key.keycode=KEY_SPACE;release_key.pressed=false
 root.push_input(release_key,true)
 await process_frame
 if not check(not casting.collapsed,"Space did not expand focused section"):return
 mana.set_collapsed(false)
 b.set_limiter_enabled(false);b.limiter_warning.hide()
 if not check(b.test_inputs.mana.is_visible_in_tree() and mana.content.is_ancestor_of(b.limiter_notice),"Testing controls escaped Mana section"):return
 b.set_test_value("mana",123.0)
 if not check(b.test_inputs.mana.value==123.0,"Reparented override no longer edits mana"):return
 b.set_limiter_enabled(true)
 b.spell_sections["Power balance"].set_collapsed(false)
 b.spell_sections.Results.set_collapsed(false)
 b.spell_sections["Animation type"].set_collapsed(true)
 var box=b.demo_mana_cost_label.get_parent()
 box.open_calculation()
 if not check(is_instance_valid(box.calculation_dialog) and box.calculation_dialog.visible,"Mana calculation lost its clickable box"):return
 box.calculation_dialog.hide()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/spell_rhs_sections.png")
 print("SPELL RHS SECTIONS PASS: all five collapse with right arrows, actual height shrinks, Space keyboard toggle, saved fold states, values retained during updates, Limiter and test override share Mana card, calculation modal retained")
 quit()
