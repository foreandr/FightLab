extends Control
var page := "Home"
var content: VBoxContainer
var navigation_buttons := {}

func _ready() -> void:
	get_tree().paused=false
	Engine.time_scale=1
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var background:=TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var gradient:=Gradient.new()
	gradient.colors=PackedColorArray([Color("182d40"),Color("0a101a")])
	var texture:=GradientTexture2D.new()
	texture.gradient=gradient
	texture.fill_from=Vector2(0,0)
	texture.fill_to=Vector2(1,1)
	background.texture=texture
	add_child(background)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	content=VBoxContainer.new()
	content.custom_minimum_size=Vector2(440,0)
	content.add_theme_constant_override("separation",14)
	center.add_child(content)
	show_page("Home")

func label(text_: String,size: int,color:=Color.WHITE) -> void:
	var node:=Label.new()
	node.text=text_
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	content.add_child(node)

func nav(text_: String,callback: Callable) -> void:
	var node:=Button.new()
	node.text=text_
	node.custom_minimum_size=Vector2(440,62)
	node.add_theme_font_size_override("font_size",24)
	var normal:=StyleBoxFlat.new()
	normal.bg_color=Color("20354a")
	normal.set_corner_radius_all(8)
	normal.border_color=Color("45677d")
	normal.set_border_width_all(1)
	var hover:=normal.duplicate()
	hover.bg_color=Color("304e66")
	var pressed:=normal.duplicate()
	pressed.bg_color=Color("142333")
	node.add_theme_stylebox_override("normal",normal)
	node.add_theme_stylebox_override("hover",hover)
	node.add_theme_stylebox_override("pressed",pressed)
	node.pressed.connect(callback)
	content.add_child(node)
	navigation_buttons[text_]=node

func show_page(next: String) -> void:
	page=next
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	navigation_buttons.clear()
	label("FIGHTLAB",48,Color("f0d49a"))
	match page:
		"Home":
			label("Choose a mode",18,Color("a9bfce"))
			nav("Story",func():show_page("Story"))
			nav("Fight",func():open_scene("res://scenes/main.tscn"))
			nav("Create",func():show_page("Create"))
			label("",8)
			nav("Quit",func():get_tree().quit())
		"Create":
			label("CREATE",24,Color("a9bfce"))
			nav("Animations",func():open_scene("res://scenes/combat_sandbox.tscn"))
			label("Movement, flips, jumps and animation chains",16,Color("a9bfce"))
			nav("Spells",func():open_scene("res://scenes/spell_editor.tscn"))
			label("Casting, charge, defense and impact tests",16,Color("a9bfce"))
			nav("Back",func():show_page("Home"))
		"Story":
			label("STORY",24,Color("a9bfce"))
			label("Story mode is not available yet.",20)
			nav("Back",func():show_page("Home"))
	var first: Button=navigation_buttons.values()[0]
	first.grab_focus()

func open_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and page!="Home":
		show_page("Home")
		get_viewport().set_input_as_handled()
