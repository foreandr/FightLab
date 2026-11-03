extends Label
## Reusable match-start presentation; the host owns the countdown clock.
func _init()->void:
 name="RoundCountdown"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 offset_left=-240;offset_right=240;offset_top=-100;offset_bottom=100
 add_theme_font_size_override("font_size",76)
 add_theme_color_override("font_color",Color("ffdd8b"))
 add_theme_color_override("font_outline_color",Color("352a1e"))
 add_theme_constant_override("outline_size",8)
func display(remaining:float,begin_left:float)->void:
 text=str(maxi(1,int(ceil(remaining-0.00001)))) if remaining>0.0 else ("BEGIN" if begin_left>0.0 else "")
 visible=not text.is_empty()
