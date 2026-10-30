extends Control

var editor
var track_id := "BODY"
var drop_highlight:=false

func _process(_delta:float) -> void:
	var active:=false
	if editor!=null and editor.can_add_unit_animation():
		var data:Variant=get_viewport().gui_get_drag_data()
		active=(data is Dictionary and str(data.get("type","")) in ["fightlab_animation_clip","fightlab_timeline_clip"]) or editor.timeline_drag_clip_id>=0
	var highlighted:=active and get_global_rect().has_point(get_global_mouse_position())
	if highlighted==drop_highlight:return
	drop_highlight=highlighted
	var label:=get_parent().get_child(0) as Label
	if label!=null:label.add_theme_color_override("font_color",Color("98703d") if highlighted else Color("382c1c"))
	queue_redraw()

func _can_drop_data(_at_position:Vector2,data:Variant) -> bool:
	if editor==null or not editor.can_add_unit_animation():return false
	return data is Dictionary and (str(data.get("type",""))=="fightlab_animation_clip" or str(data.get("type",""))=="fightlab_timeline_clip")

func _drop_data(at_position:Vector2,data:Variant) -> void:
	if editor==null:return
	if str(data.type)=="fightlab_animation_clip":editor.add_timeline_clip(data.entry,track_id,at_position.x/editor.TIMELINE_PIXELS_PER_SECOND)

func _draw() -> void:
	if drop_highlight:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.91,0.72,0.30,0.32))
		draw_rect(Rect2(Vector2(0,1),Vector2(size.x,maxf(0,size.y-2))),Color("b08a4b"),false,2.0)
	var pixels:float=editor.TIMELINE_PIXELS_PER_SECOND if editor!=null else 100.0
	var tick_spacing:=pixels*0.25
	var last_tick:=floori(size.x/tick_spacing)
	var layers:=int(get_meta("clip_layer_count",1))
	for layer in layers:
		var center_y:=size.y/float(layers)*(float(layer)+0.5)
		draw_line(Vector2(0,center_y),Vector2(size.x,center_y),Color("382c1c"),2.0)
		for quarter in range(last_tick+1):
			var x:float=minf(float(quarter)*tick_spacing,size.x)
			var half_height:=5.0 if quarter%4==0 else 2.0
			draw_line(Vector2(x,center_y-half_height),Vector2(x,center_y+half_height),Color("7e6b4d",0.72),1.0)
	if editor!=null:
		var x:float=float(editor.timeline_playhead)*pixels
		draw_line(Vector2(x,1),Vector2(x,size.y-1),Color("b64234"),2.0)
