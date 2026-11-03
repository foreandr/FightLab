extends ProgressBar
## Shared loading wheel. Progress values remain available to diagnostics.
func _ready()->void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 show_percentage=false
 add_theme_stylebox_override("background",StyleBoxEmpty.new())
 add_theme_stylebox_override("fill",StyleBoxEmpty.new())
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 custom_minimum_size.y=maxf(custom_minimum_size.y,36)
func _process(_delta:float)->void:
 if is_visible_in_tree():queue_redraw()
func _draw()->void:
 var center:=size*0.5
 var radius:=minf(13.0,minf(size.x,size.y)*0.36)
 var angle:=float(Time.get_ticks_msec())/1000.0*4.0
 draw_arc(center,radius,0,TAU,48,Color("c9b48c"),3,true)
 draw_arc(center,radius,angle,angle+TAU*0.7,40,Color("98703d"),3,true)
