extends SceneTree
func _initialize():call_deferred("run")
func run():
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/music/catalog.json"))
	var fresh:=0
	var source_hashes:Dictionary={}
	var total_bytes:=0
	for track in catalog.tracks:
		if track.get("status","")!="pool":continue
		assert(FileAccess.file_exists(track.asset),"Missing loop "+str(track.id))
		var audio=load(str(track.asset)) as AudioStreamOggVorbis
		assert(audio!=null and audio.get_length()>18.0,"Invalid loop "+str(track.id))
		assert(absf(audio.get_length()-float(track.loop_seconds))<0.1,"Wrong loop duration "+str(track.id))
		if track.get("license","")=="CC0-1.0":
			fresh+=1
			assert(not source_hashes.has(track.source_sha256),"Duplicate music source")
			source_hashes[track.source_sha256]=true
			assert(float(track.seam_jump)<0.03,"Abrupt audio seam")
			assert(not str(track.creator).is_empty() and str(track.source_page).begins_with("https://opengameart.org/content/"),"Missing attribution/source")
			assert(int(track.size_bytes)<2000000,"Loop file is too large")
			total_bytes+=int(track.size_bytes)
	assert(fresh==30,"Expected 30 new unique CC0 music loops, got "+str(fresh))
	var music=root.get_node("SharedMusic")
	assert(music.tracks.size()==31,"Shared runtime pool omitted available tracks")
	print("MUSIC POOL PASS: 30 unique CC0 loops + The Descent; source/license metadata, valid Ogg streams, duration/seam/size checks; new bytes=",total_bytes)
	quit()
