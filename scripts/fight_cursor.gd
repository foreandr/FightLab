extends "res://scripts/combat_pointer.gd"

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(24, 32)
	set_process(false)

func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(1, 1), Vector2(1, 25), Vector2(7, 19),
		Vector2(12, 30), Vector2(16, 28), Vector2(11, 17), Vector2(21, 16)
	])
	draw_colored_polygon(points, Color("dff7ff"))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color("193044"), 2.0, true)
	draw_circle(Vector2(2, 2), 2.2, Color("7fe4ff"))
