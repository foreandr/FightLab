extends PanelContainer
## One full-width hover target per result, including the padding around its text.
var stat:Control
var hovered:=false
var resting:StyleBoxFlat
var highlighted:StyleBoxFlat

func setup(label:Control) -> void:
	stat=label
	mouse_filter=Control.MOUSE_FILTER_STOP
	focus_mode=Control.FOCUS_ALL
	resting=StyleBoxFlat.new()
	resting.bg_color=Color("eee3cb")
	resting.border_color=Color("c9b58f")
	resting.set_border_width_all(1)
	resting.set_corner_radius_all(4)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:resting.set_content_margin(side,6)
	highlighted=resting.duplicate()
	highlighted.bg_color=Color("f9edcc")
	highlighted.border_color=Color("aa7b32")
	label.reparent(self)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.set_meta("stat_hover_box",self)
	label.visibility_changed.connect(sync_visibility)
	mouse_entered.connect(func():set_hovered(true))
	mouse_exited.connect(func():set_hovered(false))
	focus_entered.connect(refresh_highlight)
	focus_exited.connect(refresh_highlight)
	sync_visibility()
	refresh_highlight()

func sync_visibility() -> void:
	visible=stat.visible
	if not visible:set_hovered(false)

func set_hovered(value:bool) -> void:
	hovered=value
	refresh_highlight()

func refresh_highlight() -> void:
	add_theme_stylebox_override("panel",highlighted if hovered or has_focus() else resting)

func _get_tooltip(_at_position:Vector2) -> String:
	return stat.tooltip_text
