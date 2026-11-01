extends PanelContainer
## One full-width hover target per result, including the padding around its text.
var stat:Control
var hovered:=false
var resting:StyleBoxFlat
var highlighted:StyleBoxFlat
var calculation_dialog:Window
var dialog_theme:Theme

func setup(label:Control,book_theme:Theme=null,workspace:Control=null) -> void:
	stat=label
	dialog_theme=book_theme
	if is_instance_valid(workspace):
		workspace.visibility_changed.connect(func():
			if not workspace.is_visible_in_tree() and is_instance_valid(calculation_dialog):calculation_dialog.hide())
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
	return "Click to view calculation"

func _gui_input(event:InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed) or event.is_action_pressed("ui_accept"):
		accept_event()
		open_calculation()

func open_calculation() -> void:
	if not is_instance_valid(calculation_dialog):
		calculation_dialog=preload("res://scripts/spell_stat_dialog.gd").new()
		calculation_dialog.visible=false
		calculation_dialog.theme=dialog_theme
		add_child(calculation_dialog)
	if calculation_dialog.visible:
		calculation_dialog.grab_focus()
		return
	var title:String=stat.get_parsed_text() if stat is RichTextLabel else stat.text
	calculation_dialog.show_calculation(title,stat.tooltip_text)

func _process(_delta:float) -> void:
	if not is_instance_valid(calculation_dialog) or not calculation_dialog.visible:return
	var title_text:String=stat.get_parsed_text() if stat is RichTextLabel else stat.text
	calculation_dialog.update_calculation(title_text,stat.tooltip_text)
