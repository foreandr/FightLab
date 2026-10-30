extends SceneTree
func _initialize():call_deferred("run")
func run():
 var path:="user://animation_workspace_layout.cfg"
 var existed:=FileAccess.file_exists(path)
 var backup:=FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
 change_scene_to_file("res://scenes/combat_sandbox.tscn")
 var editor:Node
 for frame in range(600):
  await process_frame
  editor=current_scene
  if editor!=null and is_instance_valid(editor.get("slow_button")):break
 editor.spawn_editor_unit(Vector3(0,0.02,0))
 var jump:Dictionary={"id":1,"group":"Motion","category":"Jump","title":"Jump launch","step":"Jump","clip":"duel/air","track":"BODY","start":0.0,"duration":1.4,"effort":80,"priority":1}
 var flip:Dictionary={"id":2,"group":"Motion","category":"Acrobatics","title":"Backflip Copy","step":"Flip","clip":"duel/backflip","track":"BODY","start":0.24,"duration":0.68,"priority":2}
 editor.timeline_clips.assign([jump,flip])
 editor._rebuild_timeline_tracks()
 for frame in range(5):await process_frame
 var lane:Control=editor._timeline_lane_for("BODY")
 assert(lane.get_meta("clip_layer_count")==2)
 var buttons:Array=[]
 for child in lane.get_children():
  if child is Button:buttons.append(child)
 assert(buttons.size()==2 and not buttons[0].get_global_rect().intersects(buttons[1].get_global_rect()),"Overlapping clips still hide each other's labels")
 var original_pixels:float=editor.TIMELINE_PIXELS_PER_SECOND
 var original_zoom:float=editor.panel_zoom_levels.get("Timeline",1.0)
 var wheel:=InputEventMouseButton.new()
 wheel.position=lane.global_position+Vector2(100,10)
 wheel.button_index=MOUSE_BUTTON_WHEEL_UP
 wheel.pressed=true;wheel.ctrl_pressed=true
 editor._input(wheel)
 assert(editor.TIMELINE_PIXELS_PER_SECOND==original_pixels,"Ctrl wheel changed seconds instead of controls")
 assert(editor.panel_zoom_levels.Timeline>original_zoom,"Ctrl wheel did not resize panel")
 for frame in range(5):await process_frame
 lane=editor._timeline_lane_for("BODY")
 wheel.position=lane.global_position+Vector2(100,10)
 wheel.shift_pressed=true
 var panel_zoom:float=editor.panel_zoom_levels.Timeline
 editor._input(wheel)
 assert(editor.TIMELINE_PIXELS_PER_SECOND>original_pixels,"Ctrl+Shift wheel did not zoom time")
 assert(editor.panel_zoom_levels.Timeline==panel_zoom,"Time zoom resized panel controls")
 assert(editor.timeline_clips[0].duration==1.4 and editor.timeline_clips[1].start==0.24,"Zoom altered clip timing")
 if existed:
  var file:=FileAccess.open(path,FileAccess.WRITE)
  file.store_buffer(backup);file.close()
 else:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 print("STACKED CLIP LABELS AND INDEPENDENT ZOOM SHORTCUTS CHECK PASSED")
 quit()
