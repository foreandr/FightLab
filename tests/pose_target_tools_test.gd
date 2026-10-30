extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var scene=load("res://scenes/combat_sandbox.tscn").instantiate()
 root.add_child(scene)
 current_scene=scene
 await process_frame
 scene.open_custom_for({"group":"Motion","category":"Jump","step":"Jump","clip":"duel/air","title":"Jump"})
 scene.pause_custom_preview()
 var tool=scene.pose_targets
 var down=InputEventMouseButton.new()
 down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.ctrl_pressed=true
 down.position=Vector2(900,0)
 assert(tool.handle_input(down))
 var move=InputEventMouseMotion.new();move.position=Vector2(3000,2000)
 assert(tool.handle_input(move))
 var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false
 assert(tool.handle_input(up))
 assert(not tool.boxing)
 tool.select_all()
 assert(tool.selected.size()==16)
 tool.begin_target()
 var original=scene.custom_frames.duplicate(true)
 var count=original.size()
 tool.rotate_selected(2,45)
 assert(tool.required_intervals()>0)
 var target=scene.capture_custom_local_pose()
 var steps=tool.required_intervals()
 tool.build_transition()
 assert(scene.custom_frames.size()==count+steps)
 scene.select_custom_frame(steps)
 var reached=scene.capture_custom_local_pose()
 for bone in scene.DragSolver.JOINTS:
  assert((target.rotations[bone] as Quaternion).angle_to(reached.rotations[bone])<0.002,"Endpoint "+bone)
 var dt:float=scene.custom_duration/scene.custom_frames.size()
 var prev={}
 var prev_velocity={}
 for i in range(steps+1):
  scene.select_custom_frame(i)
  var sampled=scene.capture_custom_local_pose()
  if i>0:
   for bone in scene.DragSolver.JOINTS:
    var velocity=rad_to_deg((prev[bone] as Quaternion).angle_to(sampled.rotations[bone]))/dt
    assert(velocity<=tool.speed.value+0.1,"Speed limit "+bone)
    if prev_velocity.has(bone):assert(absf(velocity-prev_velocity[bone])/dt<=tool.acceleration.value+0.1,"Acceleration "+bone)
    prev_velocity[bone]=velocity
  prev=sampled.rotations
 tool.undo_transition()
 assert(scene.custom_frames==original)
 tool.begin_target()
 tool.rotate_selected(1,15)
 tool.cancel_target()
 assert(scene.custom_frames==original)
 print("PASS selection, group rotation, transition endpoint, undo and cancel")
 quit()
