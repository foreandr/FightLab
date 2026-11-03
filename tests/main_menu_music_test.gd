extends SceneTree
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
	if ok:return true
	push_error(message);quit(1);return false
func run():
	change_scene_to_file("res://scenes/home.tscn")
	await process_frame;await process_frame
	var home=current_scene
	var music=home.get_node("MainMenuMusic")
	if not check(music is AudioStreamPlayer and music.playing,"Home music not playing"):return
	if not check(music.stream is AudioStreamOggVorbis and music.stream.loop and absf(music.stream.get_length()-175.0)<0.1,"Wrong loop duration or repeat configuration"):return
	if not check(music.bus=="Master","Menu music bypasses master settings"):return
	await create_timer(0.2).timeout
	var position:float=music.get_playback_position()
	home.show_page("Create")
	await process_frame
	if not check(home.get_node("MainMenuMusic")==music and music.get_playback_position()>=position,"Changing menu pages restarted music"):return
	var empty:=PackedScene.new();var placeholder:=Control.new();empty.pack(placeholder);placeholder.free()
	change_scene_to_packed(empty)
	await process_frame;await process_frame
	if not check(not is_instance_valid(music),"Menu music leaked into gameplay"):return
	print("MAIN MENU MUSIC PASS: active 175 s loop, playback, master bus, continuous submenu playback, stops leaving menu")
	quit()
