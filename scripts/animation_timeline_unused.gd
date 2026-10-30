extends Control

var editor

func _ready() -> void:
	resized.connect(queue_redraw)
	tooltip_text="Shaded time is outside the animation length and will not play."

func _draw() -> void:
	if editor==null:return
	var end_x:=clampf(float(editor.timeline_duration)*editor.TIMELINE_PIXELS_PER_SECOND,0.0,size.x)
	if end_x>=size.x:return
	draw_rect(Rect2(end_x,0,size.x-end_x,size.y),Color(0.28,0.26,0.22,0.25))
	draw_line(Vector2(end_x,0),Vector2(end_x,size.y),Color("9b7844"),1.0)
