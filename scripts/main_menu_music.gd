extends AudioStreamPlayer
## Menu-owned music: persists through menu pages, stops when entering a mode.
const THEME=preload("res://assets/audio/music/the_descent_menu_loop.ogg")
const VOLUME_DB:=-12.0
func _ready()->void:
	name="MainMenuMusic"
	process_mode=Node.PROCESS_MODE_ALWAYS
	bus="Master"
	var loop:=THEME.duplicate() as AudioStreamOggVorbis
	loop.loop=true
	loop.loop_offset=0.0
	stream=loop
	volume_db=-60.0
	play()
	create_tween().tween_property(self,"volume_db",VOLUME_DB,1.2)
