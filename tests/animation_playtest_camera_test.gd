extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var editor:Node
 for frame in range(600):
  await process_frame
  editor=current_scene
  if editor!=null and is_instance_valid(editor.get("slow_button")):break
 editor.spawn_editor_unit(Vector3(0,0.02,0))
 var camera:Camera3D=editor.field.camera
 camera.h_offset=-1.5
 camera.v_offset=-1.0
 var initial:Transform3D=camera.global_transform
 editor.playtest.toggle()
 assert(camera.h_offset==0 and camera.v_offset==0)
 var distance:float=editor.playtest.camera_distance
 var key:=InputEventKey.new()
 key.keycode=KEY_MINUS;key.pressed=true
 assert(editor.playtest.handle_input(key))
 assert(editor.playtest.camera_distance>distance,"Keyboard zoom out failed")
 var pad:=InputEventJoypadButton.new()
 pad.button_index=JOY_BUTTON_RIGHT_STICK;pad.pressed=true
 distance=editor.playtest.camera_distance
 assert(editor.playtest.handle_input(pad))
 assert(editor.playtest.camera_distance>distance,"R3 zoom out failed")
 editor.playtest.orbiting=true
 var yaw:float=editor.playtest.camera_yaw
 var motion:=InputEventMouseMotion.new()
 motion.relative=Vector2(60,20)
 assert(editor.playtest.handle_input(motion))
 assert(editor.playtest.camera_yaw!=yaw,"Middle/right drag orbit failed")
 editor.playtest.orbiting=false
 key.keycode=KEY_LEFT
 editor.playtest.handle_input(key)
 yaw=editor.playtest.camera_yaw
 editor.playtest.physics(0.2)
 assert(editor.playtest.camera_yaw!=yaw,"Arrow orbit failed")
 key.keycode=KEY_HOME
 editor.playtest.handle_input(key)
 assert(editor.playtest.camera_distance==8)
 editor.playtest.release()
 assert(camera.global_transform.is_equal_approx(initial))
 assert(camera.h_offset==-1.5 and camera.v_offset==-1.0,"Editor camera framing not restored")
 print("TAKE CONTROL CAMERA CHECK PASSED: orbit, zoom, R3, keyboard controls, reset and editor framing restoration")
 quit()
