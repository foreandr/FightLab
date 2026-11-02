extends AudioStreamPlayer3D
## A source-owned spatial loop, separate from the finite cast/impact voice pool.
var sound_service:Node
var active:=false
func setup(service:Node=null)->void:
 sound_service=service
 name="BurningAudio"
 stream=preload("res://assets/spells/fire/burning.gd").stream()
 unit_size=3.0
 max_distance=24.0
 volume_db=-17.0
 max_db=-12.0
func set_burning(value:bool)->void:
 active=value
 var audible:bool=active and (not is_instance_valid(sound_service) or not sound_service.muted)
 if audible and not playing:play()
 elif not audible and playing:stop()
func _exit_tree()->void:
 stop()
