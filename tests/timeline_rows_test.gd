extends SceneTree
func _initialize():call_deferred("run")
func run():
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	for frame in range(600):
		await process_frame
		editor=current_scene
		if editor!=null and is_instance_valid(editor.get("slow_button")):break
	editor.timeline_name.text=""
	editor.timeline_clips.assign([
		{"id":1,"title":"Jump","track":"BODY","start":0.0,"duration":1.5,"priority":1,"group":"Motion","step":"Jump","clip":"duel/air"},
		{"id":2,"title":"Flip","track":"BODY","start":0.3,"duration":0.88,"priority":2,"group":"Motion","step":"Flip","clip":"duel/backflip"}])
	editor.timeline_rows.clear()
	editor._rebuild_timeline_tracks()
	var jump_row:int=editor.timeline_clips[0].timeline_row_id
	var flip_row:int=editor.timeline_clips[1].timeline_row_id
	assert(jump_row!=flip_row,"Overlapping Everything clips need separate rows")
	assert(not editor.timeline_priority.visible,"Old corner priority must be hidden")
	var head_row:int=-1
	for row in editor.timeline_rows:
		if row.track=="HEAD":head_row=int(row.id)
	var count:int=editor.timeline_rows.size()
	editor.add_timeline_row(head_row)
	assert(editor.timeline_rows.size()==count+1)
	var extra:int=-1
	for row in editor.timeline_rows:
		if row.track=="HEAD" and int(row.id)!=head_row:extra=int(row.id)
	editor._set_timeline_row_priority(flip_row,8)
	assert(editor.timeline_clips[0].priority==1 and editor.timeline_clips[1].priority==8,"Row priority changed wrong clip")
	editor.remove_timeline_row(extra)
	assert(editor.timeline_rows.size()==count)
	editor.undo_timeline_edit()
	assert(editor.timeline_rows.size()==count+1,"Undo did not restore removed row")
	editor.redo_timeline_edit()
	assert(editor.timeline_rows.size()==count,"Redo did not remove row")
	editor.move_timeline_clip(2,"HEAD",0.3,head_row)
	assert(editor.timeline_clips[1].timeline_row_id==head_row)
	assert(editor.timeline_clips[1].priority==3,"Move must adopt destination row priority")
	editor.undo_timeline_edit()
	assert(editor.timeline_clips[1].timeline_row_id==flip_row and editor.timeline_clips[1].priority==8)
	print("TIMELINE ROWS PASSED: separate Everything rows, per-row priority, add/remove, undo/redo, move between rows")
	quit()
