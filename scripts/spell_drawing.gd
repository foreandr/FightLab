extends Control
signal changed
var points:=PackedVector2Array()
var outline:=true
var drawing:=false
var keyboard_cursor:=Vector2(0.5,0.5)
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL
 tooltip_text="Arrows: move pen · Space: add point · Enter: finish · Backspace: undo point · Delete: clear"
 custom_minimum_size=Vector2(520,300)
 mouse_default_cursor_shape=Control.CURSOR_CROSS
func _gui_input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed:
  var step:=0.01 if event.shift_pressed else 0.05
  match event.keycode:
   KEY_LEFT:keyboard_cursor.x-=step
   KEY_RIGHT:keyboard_cursor.x+=step
   KEY_UP:keyboard_cursor.y-=step
   KEY_DOWN:keyboard_cursor.y+=step
   KEY_SPACE:add_point(keyboard_cursor*size)
   KEY_ENTER,KEY_KP_ENTER:drawing=false;changed.emit()
   KEY_BACKSPACE:
    if not points.is_empty():points.remove_at(points.size()-1);changed.emit()
   KEY_DELETE:clear()
   _:return
  keyboard_cursor=keyboard_cursor.clamp(Vector2.ZERO,Vector2.ONE)
  queue_redraw()
  accept_event()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  drawing=event.pressed
  if drawing:
   points.clear()
   add_point(event.position)
  else:changed.emit()
  accept_event()
 elif event is InputEventMouseMotion and drawing:
  add_point(event.position)
  accept_event()
func add_point(position_:Vector2) -> void:
 var point:Vector2=(position_/size).clamp(Vector2.ZERO,Vector2.ONE)
 if points.size()<128 and (points.is_empty() or points[-1].distance_to(point)>0.012):points.append(point)
 queue_redraw()
func valid() -> bool:
 return points.size()>=3 and (not outline or not Geometry2D.triangulate_polygon(points).is_empty())
func clear() -> void:
 points.clear()
 changed.emit()
 queue_redraw()
func _draw() -> void:
 draw_style_box(panel(),Rect2(Vector2.ZERO,size))
 if has_focus():draw_circle(keyboard_cursor*size,5,Color("ffdc80"))
 for i in range(1,10):
  draw_line(Vector2(size.x*i/10,0),Vector2(size.x*i/10,size.y),Color(1,1,1,0.06))
  draw_line(Vector2(0,size.y*i/10),Vector2(size.x,size.y*i/10),Color(1,1,1,0.06))
 var pixels:=PackedVector2Array()
 for point in points:pixels.append(point*size)
 if outline and valid():draw_colored_polygon(pixels,Color(0.2,0.7,1,0.2))
 if pixels.size()>1:draw_polyline(pixels,Color("8cddff"),3,true)
 if outline and pixels.size()>2:draw_line(pixels[-1],pixels[0],Color(0.5,0.8,1,0.5),2,true)
func panel() -> StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=Color("091420")
 return style
