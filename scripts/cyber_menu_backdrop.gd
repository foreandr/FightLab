extends Control
const Design=preload("res://scripts/ui_design.gd")
var elapsed:=0.0
var redraw_elapsed:=0.0
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _process(delta:float)->void:
 elapsed+=delta;redraw_elapsed+=delta
 if redraw_elapsed>0.08:redraw_elapsed=0.0;queue_redraw()
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Design.VOID)
 var horizon:=size.y*0.61
 for i in 18:
  var x:=size.x*(float(i)/17.0)
  draw_line(Vector2(size.x*0.68+(x-size.x*0.68)*0.18,horizon),Vector2(x,size.y),Color("113040"),1,true)
 for i in 12:
  var t:=float(i)/11.0
  var y:=horizon+(size.y-horizon)*t*t
  draw_line(Vector2(0,y),Vector2(size.x,y),Color("123749"),1,true)
 var center:=Vector2(size.x*0.70,size.y*0.39);var radius:=minf(size.x*0.19,size.y*0.26)
 for r in [radius,radius*0.84]:
  draw_arc(center,r,0,TAU,128,Color(0.18,0.75,0.9,0.07),14,true)
  draw_arc(center,r,0,TAU,128,Color("28677b"),2,true)
 draw_arc(center,radius,elapsed*0.09,elapsed*0.09+TAU*0.64,100,Design.CYAN,3,true)
 draw_arc(center,radius*0.84,-elapsed*0.07,-elapsed*0.07+TAU*0.31,70,Design.CYAN,2,true)
 for i in 48:
  var angle:=TAU*i/48.0
  draw_line(center+Vector2.from_angle(angle)*radius*1.07,center+Vector2.from_angle(angle)*radius*1.10,Color("24576a"),1,true)
 var inner:=radius*0.55
 var points:=PackedVector2Array([center+Vector2(0,-inner),center+Vector2(inner,0),center+Vector2(0,inner),center+Vector2(-inner,0),center+Vector2(0,-inner)])
 draw_polyline(points,Design.CYAN,2,true)
 draw_line(center+Vector2(-inner*0.5,0),center+Vector2(inner*0.5,0),Design.CYAN,2,true)
 draw_line(center+Vector2(0,-inner*0.5),center+Vector2(0,inner*0.5),Design.CYAN,2,true)
