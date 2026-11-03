extends Node
## Shared pool for menu and combat hosts. Only compact loop assets are shipped.
const CATALOG="res://assets/audio/music/catalog.json"
const VOLUME_DB:=-12.0
const CROSSFADE_SECONDS:=1.5
var tracks:Array[Dictionary]=[]
var players:Array[AudioStreamPlayer]=[]
var current_index:=0
var selected_id:=""
var context_key:=""
var transition:Tween
var random:=RandomNumberGenerator.new()
func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	random.randomize()
	var data=JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if data is Dictionary:
		for track in data.get("tracks",[]):
			if track.get("status","") in ["active","pool"] and FileAccess.file_exists(str(track.get("asset",""))):tracks.append(track)
	for i in 2:
		var player:=AudioStreamPlayer.new();player.name="MusicVoice%d"%i;player.bus="Master";player.volume_db=-60.0;add_child(player);players.append(player)
func enter_context(kind:String,owner:Node)->void:
	var next_key:="%s:%d"%[kind,owner.get_instance_id()]
	if next_key==context_key:return
	context_key=next_key
	if tracks.is_empty():return
	var choices:Array[Dictionary]=tracks.filter(func(track):return str(track.id)!=selected_id)
	if choices.is_empty():
		if players[current_index].playing:return
		choices=tracks
	play_track(choices[random.randi_range(0,choices.size()-1)])
func play_track(track:Dictionary)->void:
	var source=load(str(track.asset)) as AudioStreamOggVorbis
	if source==null:return
	if is_instance_valid(transition):transition.kill()
	var outgoing:=players[current_index]
	current_index=1-current_index
	var incoming:=players[current_index]
	incoming.stop()
	var loop:=source.duplicate() as AudioStreamOggVorbis;loop.loop=true;loop.loop_offset=0.0
	incoming.stream=loop;incoming.volume_db=-60.0;incoming.play()
	selected_id=str(track.id)
	var old_gain:float=outgoing.volume_linear
	var target_gain:=db_to_linear(VOLUME_DB)
	transition=create_tween().set_ignore_time_scale(true)
	# Equal-power fades avoid a loudness dip halfway between two songs.
	transition.tween_method(func(weight:float):
		incoming.volume_linear=target_gain*sin(weight*PI*0.5)
		outgoing.volume_linear=old_gain*cos(weight*PI*0.5),0.0,1.0,CROSSFADE_SECONDS)
	transition.tween_callback(outgoing.stop)
	var diagnostics:=get_tree().root.get_node_or_null("GameDiagnostics")
	if diagnostics:diagnostics.log_event("background_music_selected",{"id":selected_id,"context":context_key,"loop_seconds":loop.get_length()})
