extends "res://scripts/examples/open_saved_aerial_combo.gd"
func build_demo() -> void:
	await super.build_demo()
	for clip in workspace.timeline_clips:print("CLIP ",JSON.stringify(clip))
	for t in [0.3,0.4,0.5,0.6,0.7,0.8]:
		workspace._apply_timeline_at(t,true)
		var points:Dictionary={}
		for bone in ["pelvis","spine_01","spine_02","spine_03","neck_01","upperarm_r","lowerarm_r","hand_r","upperarm_l"]:
			if workspace.actor.bones.has(bone):points[bone]=str(preload("res://scripts/pose_drag_solver.gd").point(workspace.actor,bone))
		print("POINTS ",t," ",JSON.stringify(points))
	quit()
