extends ProgressBar
const Smoothing=preload("res://scripts/resource_bar_smoothing.gd")
var target_value:=0.0
func _ready() -> void:
	step=0.001
	target_value=value
func set_target_value(amount:float) -> void:
	target_value=clampf(amount,min_value,max_value)
func _process(delta:float) -> void:
	var fraction:=Smoothing.approach(value/maxf(0.001,max_value),target_value/maxf(0.001,max_value),delta)
	value=fraction*max_value
