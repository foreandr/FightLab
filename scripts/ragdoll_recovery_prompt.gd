extends Control
## Actor-owned presentation/input; timing and costs live in the shared state.
var actor_ref:WeakRef
var font:Font=preload("res://assets/fonts/Cinzel.ttf")
func setup(actor:Node)->void:
 actor_ref=weakref(actor);mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 offset_left=-130;offset_right=130;offset_top=90;offset_bottom=320
func actor():return actor_ref.get_ref() if actor_ref!=null else null
func _process(_delta:float)->void:
 var owner_=actor()
 visible=is_instance_valid(owner_) and owner_.player_controlled and owner_.health>0 and is_instance_valid(owner_.ragdoll) and owner_.recovery_timing.running
 if visible:queue_redraw()
func _input(event:InputEvent)->void:
 if not visible or not event is InputEventKey or not event.pressed or event.echo or event.keycode!=KEY_SPACE:return
 var owner_=actor()
 if not is_instance_valid(owner_) or not owner_.recovery_timing.waiting():return
 if get_viewport().gui_get_focus_owner() is LineEdit:return
 owner_.try_quick_recovery();get_viewport().set_input_as_handled()
func _draw()->void:
 var owner_=actor()
 if not is_instance_valid(owner_):return
 var timing=owner_.recovery_timing;var center:=Vector2(130,100)
 draw_circle(center,86,Color(0.13,0.10,0.07,0.85))
 draw_circle(center,28,Color("ad8333"));draw_circle(center,12,Color("fff0a3"))
 draw_arc(center,28,0,TAU,64,Color("e7bf62"),2,true)
 var radius:float=82.0*(1.0-timing.progress())
 if timing.waiting():
  draw_arc(center,maxf(1,radius),0,TAU,80,Color("302619"),7,true)
  draw_arc(center,maxf(1,radius),0,TAU,80,Color("fff5d6"),3,true)
 var text_:String="RECOVER · SPACE" if timing.waiting() else str({"Perfect":"PERFECT","Good":"RECOVER · −10 STAMINA","Miss":"MISSED"}.get(timing.result,""))
 var color:=Color("fff0a3") if timing.result=="Perfect" else (Color("e7bf62") if timing.result=="Good" else Color("f1e5cb"))
 draw_string_outline(font,Vector2(130-font.get_string_size(text_,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x/2,210),text_,HORIZONTAL_ALIGNMENT_LEFT,-1,18,5,Color("302619"))
 draw_string(font,Vector2(130-font.get_string_size(text_,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x/2,210),text_,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
