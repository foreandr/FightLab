extends SceneTree
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
	if ok:return true
	push_error(message);quit(1);return false
func run():
	change_scene_to_file("res://scenes/home.tscn")
	await process_frame;await process_frame
	var home=current_scene
	var music=root.get_node("SharedMusic")
	if not check(not music.tracks.is_empty(),"Shared music pool is empty"):return
	var menu_id:String=music.selected_id
	var player:AudioStreamPlayer=music.players[music.current_index]
	if not check(player.playing and player.stream is AudioStreamOggVorbis and player.stream.loop,"Home loop not playing"):return
	if not check(player.bus=="Master","Music bypasses master settings"):return
	var position:float=player.get_playback_position()
	home.show_page("Create");await process_frame
	if not check(music.selected_id==menu_id and player.get_playback_position()>=position,"Submenu restarted music"):return
	# Exercise the same host hook used by Story and any future CombatWorld mode.
	var world=load("res://scripts/combat_world.gd").new();home.add_child(world)
	await process_frame;await process_frame
	if not check(music.context_key.begins_with("combat:"),"Combat host did not use shared pool"):return
	if not check(music.tracks.any(func(track):return track.id==music.selected_id),"Combat used another track library"):return
	# Deterministic extra IDs use the existing audio just to test selection policy.
	var original:Array=music.tracks.duplicate()
	var sample:Dictionary=original[0].duplicate(true);sample.id="selection_test_a";music.tracks.append(sample)
	sample=sample.duplicate(true);sample.id="selection_test_b";music.tracks.append(sample)
	for i in 6:
		var previous:String=music.selected_id
		music.enter_context("test_%d"%i,home)
		if not check(music.selected_id!=previous,"Music immediately repeated despite alternatives"):return
		var active:AudioStreamPlayer=music.players[music.current_index]
		if not check(active.playing and active.stream.loop,"New track is not a looping stream"):return
	music.tracks.assign(original)
	world.queue_free();await process_frame
	var empty:=PackedScene.new();var placeholder:=Control.new();empty.pack(placeholder);placeholder.free()
	change_scene_to_packed(empty);await process_frame;await process_frame
	if not check(is_instance_valid(music) and music.players[music.current_index].playing,"Scene transition cut music"):return
	print("SHARED MUSIC PASS: menu/combat same pool, looping, master volume, submenu continuity, no-repeat choice, transitions persist")
	quit()
