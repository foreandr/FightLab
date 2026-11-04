extends Control
const Design=preload("res://scripts/ui_design.gd")
var samples:Array=[]
func _ready():custom_minimum_size.y=60;mouse_filter=Control.MOUSE_FILTER_IGNORE;resized.connect(queue_redraw)
func set_samples(value:Array):samples=value;queue_redraw()
func _draw():
 var bounds:=Rect2(Vector2(8,8),size-Vector2(16,24))
 for i in 4:
  var y:float=bounds.position.y+bounds.size.y*i/3.0
  draw_line(Vector2(bounds.position.x,y),Vector2(bounds.end.x,y),Design.LINE,1,true)
 if samples.size()<2:return
 var values:Array[float]=[];var highest:=1.0
 for i in range(1,samples.size()):
  var seconds:float=float(samples[i].seconds)-float(samples[i-1].seconds)
  var speed:float=(float(samples[i].simulated)-float(samples[i-1].simulated))/maxf(0.001,seconds)
  values.append(speed);highest=maxf(highest,speed)
 var points:=PackedVector2Array()
 for i in values.size():points.append(Vector2(bounds.position.x+bounds.size.x*i/maxf(1.0,values.size()-1),bounds.end.y-bounds.size.y*values[i]/highest))
 if points.size()>1:draw_polyline(points,Color(Design.CYAN,0.12),7,true);draw_polyline(points,Design.CYAN,2,true)
 for point in points:draw_circle(point,2.5,Design.CYAN)
