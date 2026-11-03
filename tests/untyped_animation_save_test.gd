extends SceneTree
func _initialize():call_deferred("run")
func run():
	# Exercise actual project-copy saves without changing the account manifests.
	var script:=GDScript.new()
	script.source_code='extends "res://scripts/animation_store_library.gd"\nfunc save()->bool:return true\nfunc _save_project_manifest()->bool:return true\n'
	assert(script.reload()==OK)
	var library=script.new()
	var animation:=Animation.new();animation.length=1.0
	var track:=animation.add_track(Animation.TYPE_VALUE);animation.track_set_path(track,NodePath("Model:visible"));animation.track_insert_key(track,0.0,true);animation.track_insert_key(track,1.0,true)
	for declared in [false,true]:
		var entry:Dictionary={"title":"Untyped Save Probe "+str(Time.get_ticks_usec()),"clip":"test/clip","category":"Punch","store_asset_id":"untyped-test-"+str(Time.get_ticks_usec())}
		if declared:entry.animation_type="Arm"
		assert(library.take(entry,"Attack","Downloaded",[],animation),"Animation save required a type")
		var saved:Dictionary=library.last_taken_entry
		assert(not saved.has("animation_type"),"Animation persisted casting type")
		assert(saved.get("store_animation_type")=="Arm","Store browsing hint was lost")
		assert(FileAccess.file_exists(saved.animation_resource),"No self-contained animation copy")
		assert(str(saved.animation_resource).begins_with("res://assets/animations/attached/untyped_save_probe_"))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(saved.animation_resource))
	print("UNTYPED SAVE PASS: undeclared/legacy-declared animations save project copies without a casting type; browsing hints retained; account manifests unchanged")
	quit()
