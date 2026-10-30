extends "res://scripts/examples/inverted_hook_slash_demo.gd"
func build_demo() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	for frame in range(1200):
		await process_frame
		workspace=current_scene
		if workspace!=null and is_instance_valid(workspace.get("actor")) and not workspace.timeline_library.is_empty() and is_instance_valid(workspace.get("slow_button")):break
	assert(workspace!=null and not workspace.timeline_library.is_empty())
	var config:=ConfigFile.new()
	assert(config.load(workspace.TIMELINE_PATH)==OK)
	var index:=clampi(int(config.get_value("timeline","active",0)),0,workspace.timeline_library.size()-1)
	workspace.spawn_editor_unit(Vector3(0,0.02,0))
	workspace.focus_editor_unit(0)
	workspace._rebuild_timeline_library_menu()
	workspace._select_saved_timeline(workspace.timeline_visible_library_indices.find(index))
	var snapshot:Dictionary=workspace.timeline_library[index]
	var group:=str(snapshot.get("group","Attack"))
	var category:=str(snapshot.get("category","AIR COMBAT"))
	if category not in workspace.category_store.names_for(group):category=workspace.category_store.names_for(group)[0]
	workspace.select_group(group)
	workspace.select_category(category,true)
	workspace._on_timeline_scrubbed(0.0)
	frame_camera()
	root.show();root.grab_focus();root.request_attention()
	workspace.open_timeline_save_dialog()
	print("SAVE AS READY: ",workspace.timeline_name.text,"; folder choices available; timeline starts at 0.00 s")
