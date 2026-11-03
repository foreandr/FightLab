extends "res://scripts/combat_world.gd"
## Scene state only. Combat and camera calculations stay in their shared owners.
var camera_zoom:=1.0
var story_camera_base_yaw:=0.0
var camera_orbit_yaw:=0.0
var camera_orbit_pitch:=0.362
var ending:=false
var intermission:=0.0
var warmup:=0.0
var round_time:=0.0
func adjust_camera_zoom(zoom_in:bool)->void:preload("res://scripts/third_person_camera.gd").zoom(self,zoom_in)
func rotate_camera_orbit(relative:Vector2)->void:preload("res://scripts/third_person_camera.gd").orbit(self,relative)
