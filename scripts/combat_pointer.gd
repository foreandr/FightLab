extends Control
## Mouse-following pointer base for Story and Create; drawing is mode-specific.
static func dialog_open(viewport:Viewport) -> bool:
	for window in viewport.get_embedded_subwindows():
		if window.visible:return true
	return false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func place(screen_position:Vector2,show_pointer:bool=true) -> void:
	global_position=screen_position
	visible=show_pointer
