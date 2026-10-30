extends Control
## Small item silhouette used by the loadout inventory. Item appearance is shown
## on the 3D character preview; these icons make the inventory scannable.

var part_id := "chest"
var tint := Color("526b82")
var is_crystal := false
var is_animation := false
var element := ""
var animation_id := ""
var rarity_color := Color("aab3be")

func configure(item_part: String, item_color: Color, item_rarity_color: Color, crystal_element := "", item_animation := "") -> void:
	part_id = item_part
	tint = item_color
	rarity_color = item_rarity_color
	is_crystal = not crystal_element.is_empty()
	is_animation = not item_animation.is_empty()
	element = crystal_element
	animation_id = item_animation
	queue_redraw()

func _draw() -> void:
	var size := get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var center := size * 0.5
	var scale_factor := minf(size.x, size.y) / 64.0
	var outline := Color("101722")
	var accent := tint.lightened(0.24)
	var dark := tint.darkened(0.3)
	if is_crystal:
		var gem := PackedVector2Array([
			center + Vector2(0, -23) * scale_factor,
			center + Vector2(18, -8) * scale_factor,
			center + Vector2(13, 18) * scale_factor,
			center + Vector2(0, 25) * scale_factor,
			center + Vector2(-13, 18) * scale_factor,
			center + Vector2(-18, -8) * scale_factor,
		])
		draw_colored_polygon(gem, tint)
		draw_polyline(gem + PackedVector2Array([gem[0]]), Color.WHITE.lightened(0.2), 2.0 * scale_factor, true)
		draw_line(center + Vector2(-12, -5) * scale_factor, center + Vector2(0, -18) * scale_factor, accent, 2.0 * scale_factor, true)
		draw_line(center + Vector2(-7, 13) * scale_factor, center + Vector2(1, 21) * scale_factor, dark, 2.0 * scale_factor, true)
		return
	if is_animation:
		if animation_id == "block":
			_draw_piece(center, scale_factor, [Vector2(0,-26),Vector2(21,-16),Vector2(17,10),Vector2(0,24),Vector2(-17,10),Vector2(-21,-16)], tint, outline)
			draw_line(center + Vector2(-11,-5) * scale_factor, center + Vector2(11,7) * scale_factor, accent, 4.0 * scale_factor, true)
			draw_line(center + Vector2(11,-5) * scale_factor, center + Vector2(-11,7) * scale_factor, accent, 4.0 * scale_factor, true)
		else:
			_draw_piece(center, scale_factor, [Vector2(-15,-21),Vector2(8,-24),Vector2(19,-9),Vector2(13,6),Vector2(22,15),Vector2(12,23),Vector2(0,14),Vector2(-12,21),Vector2(-21,11),Vector2(-14,0)], tint, outline)
			draw_line(center + Vector2(-6,0) * scale_factor, center + Vector2(8,0) * scale_factor, accent, 4.0 * scale_factor, true)
		return
	match part_id:
		"chest":
			_draw_piece(center, scale_factor, [Vector2(-15,-21),Vector2(-8,-26),Vector2(8,-26),Vector2(15,-21),Vector2(24,-16),Vector2(19,23),Vector2(-19,23),Vector2(-24,-16)], tint, outline)
			_draw_piece(center, scale_factor, [Vector2(-8,-25),Vector2(0,-16),Vector2(8,-25),Vector2(4,-10),Vector2(-4,-10)], accent, outline)
			draw_line(center + Vector2(0,-7) * scale_factor, center + Vector2(0,19) * scale_factor, dark, 2.0 * scale_factor, true)
		"left_arm", "right_arm":
			_draw_piece(center, scale_factor, [Vector2(-11,-25),Vector2(7,-22),Vector2(16,-11),Vector2(12,8),Vector2(18,20),Vector2(7,25),Vector2(-2,11),Vector2(-5,-1),Vector2(-16,-13)], tint, outline)
			draw_line(center + Vector2(-1,-10) * scale_factor, center + Vector2(11,13) * scale_factor, accent, 4.0 * scale_factor, true)
		"left_leg", "right_leg":
			_draw_piece(center, scale_factor, [Vector2(-19,-25),Vector2(1,-25),Vector2(0,-3),Vector2(13,7),Vector2(16,24),Vector2(1,25),Vector2(-7,9),Vector2(-20,4)], tint, outline)
			draw_line(center + Vector2(-13,-5) * scale_factor, center + Vector2(8,2) * scale_factor, accent, 3.0 * scale_factor, true)
		"left_boot", "right_boot":
			_draw_piece(center, scale_factor, [Vector2(-10,-25),Vector2(10,-25),Vector2(9,9),Vector2(20,15),Vector2(19,23),Vector2(-18,23),Vector2(-19,17),Vector2(-9,8)], tint, outline)
			draw_line(center + Vector2(-9,-13) * scale_factor, center + Vector2(9,-13) * scale_factor, accent, 3.0 * scale_factor, true)
		"head":
			_draw_piece(center, scale_factor, [Vector2(0,-26),Vector2(15,-18),Vector2(20,-4),Vector2(16,16),Vector2(0,25),Vector2(-16,16),Vector2(-20,-4),Vector2(-15,-18)], tint, outline)
			draw_arc(center + Vector2(0,-2) * scale_factor, 18 * scale_factor, PI, TAU, 16, accent, 3.0 * scale_factor, true)
		"face":
			_draw_piece(center, scale_factor, [Vector2(-22,-14),Vector2(22,-14),Vector2(17,15),Vector2(0,24),Vector2(-17,15)], tint, outline)
			draw_line(center + Vector2(-13,-2) * scale_factor, center + Vector2(13,-2) * scale_factor, accent, 3.0 * scale_factor, true)
		"belt":
			_draw_piece(center, scale_factor, [Vector2(-25,-11),Vector2(25,-11),Vector2(25,11),Vector2(-25,11)], tint, outline)
			draw_rect(Rect2(center + Vector2(-6,-8) * scale_factor, Vector2(12,16) * scale_factor), accent, false, 3.0 * scale_factor)
		"back":
			_draw_piece(center, scale_factor, [Vector2(-17,-23),Vector2(17,-23),Vector2(22,-14),Vector2(19,23),Vector2(-19,23),Vector2(-22,-14)], tint, outline)
			draw_line(center + Vector2(0,-18) * scale_factor, center + Vector2(0,18) * scale_factor, accent, 3.0 * scale_factor, true)
		_:
			_draw_piece(center, scale_factor, [Vector2(-16,-22),Vector2(16,-22),Vector2(20,18),Vector2(0,25),Vector2(-20,18)], tint, outline)

func _draw_piece(center: Vector2, scale_factor: float, points: Array, color: Color, outline: Color) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(center + point * scale_factor)
	draw_colored_polygon(polygon, color)
	draw_polyline(polygon + PackedVector2Array([polygon[0]]), outline, 2.0 * scale_factor, true)
