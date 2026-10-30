extends Control
const Pool = preload("res://scripts/clothing_pool.gd")
const Character = preload("res://scripts/story_character.gd")
var preview: Node3D
var title: Label
var counts: Label
var source: Label
var yes: Button
var no: Button
var items: Array[Dictionary] = []
var pile := "pending"
var current: Dictionary = {}
var undo_stack: Array[Dictionary] = []
var body := "Masculine"
var preview_camera: Camera3D
var category_filter := "all"
var search_text := ""
var search_delay: Timer
const CATEGORIES := {"all":"Everything","head":"Head","arms":"Arms","hands":"Hands","torso":"Torso","legs":"Legs","boots":"Boots","neck":"Neck","back":"Back","waist":"Waist","misc":"Misc"}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := ColorRect.new()
	background.color = Color("252b34")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation",12)
	margin.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	_label(header,"CLOTHING PAVLOV",28).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header,"Back to Dev",func():get_tree().set_meta("return_to_dev",true);get_tree().change_scene_to_file("res://scenes/home.tscn"))
	counts = _label(page,"",16)
	var tabs := HBoxContainer.new()
	page.add_child(tabs)
	for entry in [["Queue","pending"],["Accepted","accepted"],["Unwanted","unwanted"]]:
		_button(tabs,entry[0],_select_pile.bind(entry[1]))
	_button(tabs,"Next",_next_item)
	_button(tabs,"Undo last",_undo)
	_button(tabs,"Switch body",_switch_body)
	var filters := HBoxContainer.new()
	page.add_child(filters)
	var category_choice := OptionButton.new()
	category_choice.custom_minimum_size = Vector2(220,36)
	for key in CATEGORIES: category_choice.add_item(CATEGORIES[key])
	category_choice.item_selected.connect(func(index: int): category_filter = CATEGORIES.keys()[index]; _reload())
	filters.add_child(category_choice)
	var search := LineEdit.new()
	search.placeholder_text = "Search clothing, creator or source"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_delay = Timer.new()
	search_delay.one_shot = true
	search_delay.wait_time = 0.18
	search_delay.timeout.connect(_reload)
	add_child(search_delay)
	search.text_changed.connect(func(value: String): search_text = value.to_lower(); search_delay.start())
	filters.add_child(search)
	_button(filters,"Refresh library",_reload)
	var view := SubViewportContainer.new()
	view.stretch = true
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.gui_input.connect(_rotate)
	page.add_child(view)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(900,650)
	viewport.own_world_3d = true
	view.add_child(viewport)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("343e4b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.7
	world.environment = env
	viewport.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30,-25,0)
	light.light_energy = 1.4
	viewport.add_child(light)
	var camera := Camera3D.new()
	preview_camera = camera
	camera.position = Vector3(0,1,3.2)
	camera.fov = 34
	viewport.add_child(camera)
	camera.look_at(Vector3(0,0.95,0))
	preview = Character.new()
	viewport.add_child(preview)
	title = _label(page,"",24)
	source = _label(page,"",14)
	source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(page,"Y: yes · X/N: no · ←/→: previous/next · A/D: rotate · B: body · Z: undo · 1–3: piles · Esc: Dev · F10: all actions",14)
	var actions := HBoxContainer.new()
	page.add_child(actions)
	yes = _button(actions,"YES — Keep for CPUs",_vote.bind("accepted"))
	no = _button(actions,"NO — Store unwanted",_vote.bind("unwanted"))
	for button in [yes,no]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 64
	_reload()

func _label(parent: Node, text_value: String, size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size",size)
	parent.add_child(label)
	return label

func _button(parent: Node, text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(120,42)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _select_pile(value: String) -> void:
	pile = value
	_reload()

func _reload() -> void:
	items.clear()
	var totals := {"pending":0,"accepted":0,"unwanted":0}
	var config := Pool.decisions()
	for item in Pool.catalog():
		var state := str(config.get_value("decisions",item.id,"pending"))
		if not totals.has(state): state = "pending"
		totals[state] += 1
		if state != pile: continue
		if category_filter != "all" and Pool.body_part(item) != category_filter: continue
		if not search_text.is_empty() and not search_text in (str(item.name)+" "+str(item.source)).to_lower(): continue
		items.append(item)
	counts.text = "Imported models: %d   ·   Queue: %d   ·   Accepted: %d   ·   Unwanted: %d   ·   Showing: %d" % [Pool.imported().size(),totals.pending,totals.accepted,totals.unwanted,items.size()]
	current = items[0] if not items.is_empty() else {}
	yes.disabled = current.is_empty()
	no.disabled = current.is_empty()
	_show_item()

func _show_item() -> void:
	var profile := {"body":body,"hair":"Short","skin_color":Color("be926e"),"wardrobe_shirt":"Underclothes","wardrobe_pants":"Underclothes","wardrobe_arms":"None","wardrobe_boots":"None","wardrobe_hands":"None","wardrobe_belt":"None","wardrobe_hat":"None","wardrobe_mask":"None","wardrobe_back":"None"}
	if not current.is_empty():
		profile[current.slot] = current.value
		profile["rotation"] = PI if current.slot == "wardrobe_back" else 0.0
		var close_view: bool = current.slot in ["wardrobe_hat","wardrobe_mask"]
		preview_camera.position = Vector3(0,1.65,1.9) if close_view else Vector3(0,1,3.2)
		preview_camera.look_at(Vector3(0,1.50,0) if close_view else Vector3(0,0.95,0))
		title.text = current.name + " · " + pile.capitalize()
		source.text = str(current.source) + " · Body hint: " + Pool.body_part(current).capitalize()
	else:
		title.text = "Queue complete" if pile == "pending" else "This pile is empty"
		source.text = "Accepted clothes enter the CPU pool. Unwanted assets stay stored for later."
	preview.set_profile(profile)
	yes.disabled = current.is_empty()
	no.disabled = current.is_empty()
	if not current.is_empty() and str(current.id) in preview.get_meta("wardrobe_fit_failures",[]):
		yes.disabled = true
		source.text += " · Could not fit this model. Next skips it; No stores it in Unwanted."

func _vote(value: String) -> void:
	if current.is_empty(): return
	var previous := Pool.status(current.id)
	if Pool.decide(current.id,value) != OK:
		source.text = "Could not save this decision. Try again."
		return
	undo_stack.append({"id":current.id,"previous":previous})
	# Browsing an already sorted pile also advances to its next item.
	if previous == value and items.size() > 1:
		items.append(items.pop_front())
		current = items[0]
		_show_item()
	else: _reload()

func _undo() -> void:
	if undo_stack.is_empty(): return
	var last: Dictionary = undo_stack.back()
	if Pool.decide(last.id,last.previous) == OK:
		undo_stack.pop_back()
		pile = last.previous
		_reload()

func _switch_body() -> void:
	body = "Feminine" if body == "Masculine" else "Masculine"
	_show_item()

func _rotate(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		preview.rotation.y += event.relative.x * 0.012

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Y:_vote("accepted")
			KEY_N,KEY_X:_vote("unwanted")
			KEY_RIGHT:_next_item()
			KEY_LEFT:
				if items.size()>1:
					items.push_front(items.pop_back())
					current=items[0]
					_show_item()
			KEY_A:preview.rotation.y-=PI/8
			KEY_D:preview.rotation.y+=PI/8
			KEY_B:_switch_body()
			KEY_Z:_undo()
			KEY_1:_select_pile("pending")
			KEY_2:_select_pile("accepted")
			KEY_3:_select_pile("unwanted")
			KEY_ESCAPE:
				get_tree().set_meta("return_to_dev",true)
				get_tree().change_scene_to_file("res://scenes/home.tscn")
			_:return
		get_viewport().set_input_as_handled()

func _next_item() -> void:
	if items.size() < 2: return
	items.append(items.pop_front())
	current = items[0]
	_show_item()

func bot_show_item(id: String) -> Dictionary:
	for item in Pool.catalog():
		if item.id != id: continue
		category_filter = "all"
		search_text = ""
		pile = Pool.status(id)
		_reload()
		for index in items.size():
			if items[0].id == id: break
			items.append(items.pop_front())
		current = item
		_show_item()
		return {"ok":true,"id":id,"value":item.value,"status":pile}
	return {"ok":false,"error":"Unknown clothing item: "+id}
