extends SceneTree
const Access=preload("res://scripts/game_settings_access.gd")
const CameraRules=preload("res://scripts/third_person_camera.gd")
class CameraState:
 extends Node
 var camera_zoom:=1.0
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 var settings=Access.service()
 var snapshot:Dictionary={"path":settings.storage_path,"min":settings.min_camera_distance,"max":settings.max_camera_distance,"master":settings.master_volume,"combat":settings.combat_volume,"muted":settings.muted,"distance":settings.distance_audio}
 settings.storage_path="user://logs/global_settings_test.cfg"
 settings.set_value("closest",4.0);settings.set_value("farthest",8.0)
 settings.set_value("master",0.4);settings.set_value("combat",0.6);settings.set_value("muted",true)
 if not check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)),0.4) and AudioServer.is_bus_mute(0),"Master volume/mute not applied globally"):return
 if not check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Combat"))),0.6),"Combat volume bus ignored"):return
 settings.min_camera_distance=1;settings.max_camera_distance=50;settings.load_settings()
 if not check(settings.min_camera_distance==4 and settings.max_camera_distance==8 and settings.master_volume==0.4 and settings.muted,"Preferences do not reload"):return
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false)
 var actor:CharacterBody3D=world.spawn_combatant(0,Vector3.ZERO)
 world.camera=Camera3D.new();world.add_child(world.camera)
 var state:=CameraState.new()
 state.camera_zoom=10.0
 CameraRules.zoom(state,false)
 if not check(state.camera_zoom*CameraRules.BASE_DISTANCE<=8.001,"RPG zoom out ignores universal limit"):return
 state.camera_zoom=0.001;CameraRules.zoom(state,true)
 if not check(state.camera_zoom*CameraRules.BASE_DISTANCE>=3.999,"RPG zoom in ignores universal limit"):return
 state.free()
 var inspection=preload("res://scripts/sandbox_camera.gd").new();inspection.distance=5
 inspection.zoom(-100)
 if not check(inspection.distance==8,"Inspection camera uses another maximum"):return
 inspection.zoom(100)
 if not check(inspection.distance==4,"Inspection camera uses another minimum"):return
 var playtest=preload("res://scripts/animation_playtest.gd").new();playtest.zoom_camera(100)
 if not check(playtest.camera_distance==8,"Take Control camera ignores settings"):return
 var burn=preload("res://scripts/burning_audio.gd").new();world.add_child(burn);burn.setup(world.audio)
 settings.set_value("distance",false)
 if not check(world.audio.voices[0].attenuation_model==AudioStreamPlayer3D.ATTENUATION_DISABLED and world.audio.voices[0].max_distance==0 and burn.max_distance==0,"Live cast/burn audio ignores distance toggle"):return
 settings.set_value("distance",true)
 if not check(world.audio.voices[0].max_distance==35 and burn.max_distance==24 and burn.bus=="Combat","Spatial ranges/bus not restored"):return
 settings.set_value("closest",10.0)
 if not check(settings.max_camera_distance>=settings.min_camera_distance,"Invalid closest/farthest interval"):return
 world.queue_free();await process_frame
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 while current_scene==null or not bool(current_scene.get("default_unit_ready")) or is_instance_valid(current_scene.get("loading_layer")):await process_frame
 var editor=current_scene
 editor._toggle_options_menu()
 var settings_button:Button=editor.options_panel.find_child("OpenUniversalSettings",true,false)
 if not check(settings_button!=null,"Create options lacks shared settings"):return
 settings_button.pressed.emit()
 if not check(settings.opened and self.paused and settings.dialog.visible and not editor.options_panel.visible,"Create settings fails to open/pause"):return
 for i in 2:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/universal_settings.png")
 settings.close()
 if not check(not settings.opened and not self.paused,"Closing settings failed to resume"):return
 change_scene_to_file("res://scenes/fight.tscn");await process_frame;await process_frame
 if not check(settings.cog.visible,"Story lacks universal settings toggle"):return
 settings.cog.pressed.emit()
 if not check(settings.dialog.visible and settings.near_input.value==settings.min_camera_distance,"Story uses another settings dialog"):return
 settings.close()
 # Restore real user preferences; test writes stay under user://logs.
 settings.min_camera_distance=snapshot.min;settings.max_camera_distance=snapshot.max
 settings.master_volume=snapshot.master;settings.combat_volume=snapshot.combat;settings.muted=snapshot.muted;settings.distance_audio=snapshot.distance
 settings._apply_audio();settings.changed.emit()
 DirAccess.remove_absolute(settings.storage_path);settings.storage_path=snapshot.path
 print("GLOBAL SETTINGS PASS: persistence, shared Create/Story dialog, pause/resume, three camera controllers, volume/mute buses, live cast/burn distance toggle, valid bounds")
 quit()
