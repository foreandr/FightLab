extends SceneTree
func _initialize():call_deferred("run")
func run():
	change_scene_to_file("res://scenes/home.tscn");await process_frame;await process_frame
	var settings=root.get_node("GameSettings")
	var original_path:String=settings.storage_path
	var original_muted:bool=settings.muted
	var original_volume:float=settings.master_volume
	settings.storage_path="user://logs/sound_mute_test.cfg"
	settings.set_value("master",1.0);settings.set_value("muted",false)
	current_scene.show_page("Options")
	assert(current_scene.navigation_buttons.has("Sound"),"No Sound entry in Options")
	current_scene.navigation_buttons.Sound.pressed.emit()
	assert(settings.opened and settings.sections.get_tab_title(settings.sections.current_tab)=="Sound","Sound settings did not open directly")
	assert(settings.mute_toggle.text=="Mute game","Mute label unclear")
	var music=root.get_node("SharedMusic")
	assert(music.players[music.current_index].bus=="Master","Music bypasses global mute")
	settings.mute_toggle.set_pressed(true)
	assert(settings.muted and AudioServer.is_bus_mute(0),"Mute switch did not silence Master")
	settings.muted=false;settings.load_settings()
	assert(settings.muted and settings.mute_toggle.button_pressed,"Mute preference did not persist/reload")
	settings.mute_toggle.set_pressed(false)
	assert(not settings.muted and not AudioServer.is_bus_mute(0),"Unmute did not restore audio")
	settings.close()
	settings.muted=original_muted;settings.master_volume=original_volume;settings.storage_path=original_path;settings._apply_audio();settings.changed.emit()
	DirAccess.remove_absolute("user://logs/sound_mute_test.cfg")
	print("SOUND MUTE PASS: Options > Sound, clear whole-game mute, global music/effects routing, persistence and unmute; user preferences restored")
	quit()
