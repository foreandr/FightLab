extends Control
## Actor-owned presentation/input; timing and costs live in the shared state.
var actor_ref:WeakRef
var font:Font=preload("res://assets/fonts/Cinzel.ttf")
func setup(actor:Node)->void:
 actor_ref=weakref(actor);mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 size=Vector2(200,100)
func actor():return actor_ref.get_ref() if actor_ref!=null else null
func _process(_delta:float)->void:
 var owner_=actor()
 visible=is_instance_valid(owner_) and owner_.health>0 and is_instance_valid(owner_.ragdoll) and owner_.recovery_timing.offered() and owner_.recovery_timing.waiting()
 if not visible:return
 var camera:=get_viewport().get_camera_3d()
 if not is_instance_valid(camera):hide();return
 var anchor:Vector3=owner_.overhead_tag_position()
 if camera.is_position_behind(anchor):hide();return
 position=camera.unproject_position(anchor)-Vector2(100,155)
 if not get_viewport_rect().intersects(get_global_rect()):hide();return
 queue_redraw()
func _input(event:InputEvent)->void:
 if not visible or not event is InputEventKey or not event.pressed or event.echo:return
 var key:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
 if key!=KEY_SPACE or preload("res://scripts/combat_pointer.gd").dialog_open(get_viewport()):return
 var owner_=actor()
 if not is_instance_valid(owner_) or not owner_.recovery_timing.waiting():return
 if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:return
 if preload("res://scripts/ragdoll_recovery_timing.gd").handle_input(owner_,event):get_viewport().set_input_as_handled()
func _draw()->void:
 var owner_=actor()
 if not is_instance_valid(owner_):return
 var timing=owner_.recovery_timing
 var text_:String=("SPACE · " if owner_.player_controlled else "RECOVERY · ")+"%.0f stamina"%timing.stamina_cost()
 var width:=font.get_string_size(text_,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
 var box:=Rect2(Vector2(100-width/2-10,35),Vector2(width+20,34))
 draw_style_box(get_theme_stylebox("panel","PanelContainer"),box)
 var at:=Vector2(100-width/2,58)
 draw_string_outline(font,at,text_,HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color("302619"))
 draw_string(font,at,text_,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("fff0a3"))
