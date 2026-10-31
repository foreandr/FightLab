extends "res://scripts/combat_pointer.gd"
func _draw() -> void:
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		draw_line(direction*4.0,direction*10.0,Color("242019"),4.0,true)
		draw_line(direction*4.0,direction*10.0,Color("fff4d8"),1.5,true)
	draw_circle(Vector2.ZERO,1.5,Color("fff4d8"))
