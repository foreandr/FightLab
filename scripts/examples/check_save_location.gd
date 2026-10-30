extends "res://scripts/examples/open_saved_aerial_combo.gd"
const SaveLocation=preload("res://scripts/timeline_library_save.gd")
func build_demo() -> void:
	await super.build_demo()
	var real_store=workspace.store_library
	var fixture=preload("res://scripts/animation_store_library.gd").new()
	fixture.path="C:/Users/forea/Documents/Codex/2026-10-30/if-w/work/save-location-fixture.cfg"
	workspace.store_library=fixture
	var old_clips:Array=workspace.timeline_clips.duplicate(true)
	var old_rows:Array=workspace.timeline_rows.duplicate(true)
	var result:=SaveLocation.save(workspace,"Location check","Motion","Jump")
	assert(result.ok,str(result))
	assert(fixture.entries_for("Motion","Jump").size()==1)
	var animation:Animation=load(str(result.entry.animation_resource))
	assert(animation!=null and is_equal_approx(animation.length,workspace.timeline_duration))
	assert(result.entry.composed_timeline.clips==old_clips and result.entry.composed_timeline.rows==old_rows)
	assert(workspace.timeline_clips==old_clips and workspace.timeline_rows==old_rows)
	result=SaveLocation.save(workspace,"Location check","Attack","AIR COMBAT")
	assert(result.ok,str(result))
	assert(fixture.taken.size()==1 and fixture.entries_for("Attack","AIR COMBAT").size()==1)
	assert(fixture.entries_for("Motion","Jump").is_empty())
	fixture.taken.clear()
	fixture.load_state()
	assert(fixture.entries_for("Attack","AIR COMBAT").size()==1)
	assert(not SaveLocation.save(workspace,"Location check","Attack","Missing folder").ok)
	workspace.store_library=real_store
	workspace.open_timeline_save_dialog()
	assert(workspace.timeline_save_group.get_item_text(workspace.timeline_save_group.selected)=="Attack")
	assert(workspace.timeline_save_category.get_item_text(workspace.timeline_save_category.selected)=="AIR COMBAT")
	workspace.timeline_save_group.select(0)
	workspace._populate_timeline_save_folders("Jump")
	assert(workspace.timeline_save_category.get_item_text(workspace.timeline_save_category.selected)=="Jump")
	workspace.timeline_save_name.text=""
	workspace._confirm_timeline_save()
	assert(is_instance_valid(workspace.timeline_save_overlay) and not workspace.timeline_save_error.text.is_empty())
	workspace._close_timeline_save_dialog()
	assert(workspace.timeline_clips==old_clips)
	workspace.open_timeline_save_dialog()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/forea/Documents/Codex/2026-10-30/if-w/work/save-location-dialog.png")
	print("SAVE LOCATION CHECK PASSED: Motion and custom Attack folder; reload; update without duplicates; original timing and layers; validation and cancel")
	quit()
