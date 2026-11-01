extends VBoxContainer
## The same animation authoring control is used in the editor and demo workspace.
signal value_changed(value:float)
var slider:HSlider
var caption:Label
func _init() -> void:
 name="AnimationLegTakeover"
 add_theme_constant_override("separation",4)
 caption=Label.new()
 caption.add_theme_font_size_override("font_size",15)
 add_child(caption)
 slider=HSlider.new()
 slider.name="LegTakeover"
 slider.min_value=0;slider.max_value=100;slider.step=1
 slider.custom_minimum_size.y=24
 slider.focus_mode=Control.FOCUS_ALL
 slider.tooltip_text="0%: keep running legs. 100%: this animation controls the legs and pelvis. Values between blend both. Does not change travel speed."
 add_child(slider)
 slider.value_changed.connect(func(value:float):
  refresh(value/100.0)
  value_changed.emit(value/100.0))
 set_value(0.0)
func set_value(value:float) -> void:
 slider.set_value_no_signal(clampf(value,0.0,1.0)*100.0)
 refresh(slider.value/100.0)
func refresh(value:float) -> void:
 caption.text="Leg takeover: %.0f%%"%(value*100.0)
