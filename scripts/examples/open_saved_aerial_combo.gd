extends "res://scripts/examples/inverted_hook_slash_demo.gd"
## Reopen the saved aerial edit without generating or importing another copy.
func build_demo() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	for frame in range(600):
		await process_frame
		workspace=current_scene
		if workspace!=null and is_instance_valid(workspace.get("slow_button")):break
	var index:=-1
	for i in workspace.timeline_library.size():
		if str(workspace.timeline_library[i].get("name","")).begins_with("Corkscrew Open Hand Melee Hook"):index=i
	assert(index>=0,"Saved aerial combo missing")
	workspace.spawn_editor_unit(Vector3(0,0.02,0))
	workspace.spawn_editor_unit(Vector3(0,0.02,1.1))
	workspace.focus_editor_unit(0)
	workspace._rebuild_timeline_library_menu()
	workspace._select_saved_timeline(workspace.timeline_visible_library_indices.find(index))
	workspace.select_group("Attack")
	for category in workspace.category_store.names_for("Attack"):
		if str(category).nocasecmp_to("Air Combat")==0:workspace.select_category(category,true)
	workspace._on_timeline_scrubbed(0.96)
	frame_camera()
	root.show();root.grab_focus();root.request_attention()
	print("SAVED AERIAL COMBO OPEN: per-row priority and layer controls ready")
