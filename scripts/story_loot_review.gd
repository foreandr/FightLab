extends Control
## Post-fight loot shown as the same compact item-card inventory used by Loadout.

const ICON := preload("res://scripts/gear_inventory_icon.gd")
var profile: Dictionary = {}
var grid: GridContainer
var spell_grid: GridContainer
var new_gear_ids: Dictionary = {}
var new_spell_ids: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var config := ConfigFile.new()
	if config.load("user://story_character.cfg") != OK:
		set_process(false)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/story_opponents.tscn")
		return
	profile = config.get_value("character", "profile", {})
	if profile.is_empty():
		set_process(false)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/story_opponents.tscn")
		return
	_consume_new_discoveries(config)
	_build_ui()
	if not new_gear_ids.is_empty() or not new_spell_ids.is_empty():_play_discovery_chime()

func _build_ui() -> void:
	var book_theme := Theme.new()
	book_theme.set_color("font_color", "Label", Color("382c1c"))
	book_theme.set_color("font_color", "Button", Color("382c1c"))
	theme = book_theme
	var bg := ColorRect.new()
	bg.color = Color("302116")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var page := PanelContainer.new()
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = Color("e8ddc4")
	page_style.border_color = Color("765b38")
	page_style.set_border_width_all(2)
	page.add_theme_stylebox_override("panel", page_style)
	margin.add_child(page)
	var page_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		page_margin.add_theme_constant_override("margin_" + side, 24)
	page.add_child(page_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	page_margin.add_child(column)
	var eyebrow := Label.new()
	eyebrow.text = "BOOK 1  ·  CHAPTER 1  ·  COLOSSEUM"
	eyebrow.add_theme_color_override("font_color", Color("e9c982"))
	column.add_child(eyebrow)
	var title := Label.new()
	title.text = "LOOT FOUND"
	title.add_theme_font_size_override("font_size", 32)
	column.add_child(title)
	var intro := Label.new()
	intro.text = _loot_guidance()
	intro.add_theme_color_override("font_color", Color("655740"))
	column.add_child(intro)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("e8ddc4")
	panel_style.border_color = Color("b5a27f")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	column.add_child(panel)
	var inside := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: inside.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(inside)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	inside.add_child(stack)
	var heading := Label.new()
	heading.text = "OPPONENT'S GEAR"
	heading.add_theme_color_override("font_color", Color("e9c982"))
	stack.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	var spells_heading := Label.new()
	spells_heading.text = "NEW SPELLS"
	spells_heading.add_theme_color_override("font_color", Color("496d88"))
	stack.add_child(spells_heading)
	var spell_scroll := ScrollContainer.new()
	spell_scroll.custom_minimum_size.y = 132
	spell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(spell_scroll)
	spell_grid = GridContainer.new()
	spell_grid.columns = 5
	spell_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spell_grid.add_theme_constant_override("h_separation", 12)
	spell_grid.add_theme_constant_override("v_separation", 12)
	spell_scroll.add_child(spell_grid)
	_populate()
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	_add_button(buttons, "OPEN LOADOUT", "res://scenes/story_loadout.tscn", true)
	_add_button(buttons, "FIGHT HISTORY", "res://scenes/story_opponents.tscn")

func _populate() -> void:
	for child in grid.get_children(): child.queue_free()
	for child in spell_grid.get_children(): child.queue_free()
	var loot: Array = _review_loot()
	if loot.is_empty():
		var empty := Label.new()
		empty.text = "No loot was found this time."
		empty.add_theme_color_override("font_color", Color("655740"))
		grid.add_child(empty)
	for item in _sort_by_rarity(loot):
		if item is Dictionary: grid.add_child(_make_card(item))
	var spells:Array=_sort_by_rarity(profile.get("last_fight_spells",[]))
	if spells.is_empty():
		var empty_spells:=Label.new()
		empty_spells.text="No new spells this time."
		empty_spells.add_theme_color_override("font_color",Color("655740"))
		spell_grid.add_child(empty_spells)
	for spell in spells:
		if spell is Dictionary:spell_grid.add_child(_make_spell_card(spell))

func _review_loot() -> Array:
	var recent:Variant=profile.get("last_fight_loot",[])
	var loot:Array=(recent if recent is Array else profile.get("story_loot",[])).duplicate(true)
	for index in range(loot.size()-1,-1,-1):
		var entry:Variant=loot[index]
		if entry is Dictionary and str(entry.get("name","")).to_lower().begins_with("bare "):
			loot.remove_at(index)
	var recent_win:Dictionary={}
	for entry in profile.get("story_history",[]):
		if entry is Dictionary and bool(entry.get("won",false)):recent_win=entry
	if recent_win.is_empty():return loot
	var fight:=int(recent_win.get("fight",0))
	var right_id:="fight-%d-right-arm"%fight
	var has_right:=false
	for item in loot:
		if not item is Dictionary:continue
		var slot:=str(item.get("slot",""))
		if slot=="Arms" and not item.has("ability"):item["ability"]="punch_left"
		if str(item.get("id",""))==right_id:has_right=true
	if not has_right:
		loot.append({"id":right_id,"name":"Peasant right arm wraps","slot":"Right arm","ability":"punch_right"})
	return loot

func _make_card(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(142, 196)
	var rarity := _item_rarity(item)
	var rarity_color := _rarity_color(rarity)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172536")
	style.border_color = rarity_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	panel.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)
	var icon := ICON.new()
	icon.custom_minimum_size = Vector2(68, 68)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.configure(_icon_part(str(item.get("slot", ""))), _item_color(str(item.get("slot", ""))), rarity_color)
	col.add_child(icon)
	var name := Label.new()
	name.text = str(item.get("name", "Gear"))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_font_size_override("font_size", 15)
	name.add_theme_color_override("font_color", rarity_color)
	col.add_child(name)
	var slot := Label.new()
	var animation_capacity := _animation_slot_capacity(item)
	slot.text = "%s  ·  %d ANIM SLOT%s" % [str(item.get("slot", "Gear")).to_upper(), animation_capacity, "" if animation_capacity == 1 else "S"]
	slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.add_theme_font_size_override("font_size", 9)
	slot.add_theme_color_override("font_color", rarity_color)
	slot.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(slot)
	var animations:=Label.new()
	animations.text=_animation_summary(item) if _animation_summary(item)!="None" else "No animation"
	animations.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	animations.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	animations.add_theme_font_size_override("font_size",10)
	animations.add_theme_color_override("font_color",Color("c5a8ff"))
	col.add_child(animations)
	var spells:=Label.new()
	spells.text=_spell_summary(item) if _spell_summary(item)!="None" else "No spell"
	spells.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	spells.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	spells.add_theme_font_size_override("font_size",10)
	spells.add_theme_color_override("font_color",Color("496d88"))
	col.add_child(spells)
	panel.tooltip_text = "%s\n%s · %d animation slot%s\nAnimations: %s\nSpells: %s" % [item.get("name", "Gear"), item.get("slot", "Gear"), animation_capacity, "" if animation_capacity == 1 else "s", _animation_summary(item), _spell_summary(item)]
	if new_gear_ids.has(str(item.get("id", ""))):_add_new_badge(panel)
	return panel

func _make_spell_card(spell:Dictionary) -> Control:
	var panel:=PanelContainer.new()
	panel.custom_minimum_size=Vector2(142,112)
	var color:Color=spell.get("color",Color("ff8058"))
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172536")
	style.border_color=color
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	panel.add_theme_stylebox_override("panel",style)
	var label:=Label.new()
	label.text=str(spell.get("spell",spell.get("name","Spell")))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",color)
	panel.add_child(label)
	panel.tooltip_text=str(spell.get("name",spell.get("spell","Spell")))
	if new_spell_ids.has(str(spell.get("id",""))):_add_new_badge(panel)
	return panel

func _add_new_badge(card:Control)->void:
	var badge:=PanelContainer.new()
	badge.name="NewBadge"
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	badge.position=Vector2(7,7)
	badge.custom_minimum_size=Vector2(48,24)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("e9c982")
	style.border_color=Color("fff1c8")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	badge.add_theme_stylebox_override("panel",style)
	var label:=Label.new()
	label.text="NEW"
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",13)
	label.add_theme_color_override("font_color",Color("111923"))
	badge.add_child(label)
	card.add_child(badge)

func _consume_new_discoveries(config:ConfigFile)->void:
	var loot:Array=profile.get("last_fight_loot",[])
	for item in loot:
		if item is Dictionary and bool(item.get("is_new",false)):
			new_gear_ids[str(item.get("id",""))]=true
			item["is_new"]=false
	var spells:Array=profile.get("last_fight_spells",[])
	for spell in spells:
		if spell is Dictionary and bool(spell.get("is_new",true)):
			new_spell_ids[str(spell.get("id",""))]=true
			spell["is_new"]=false
	profile["last_fight_loot"]=loot
	profile["last_fight_spells"]=spells
	config.set_value("character","profile",profile)
	config.save("user://story_character.cfg")
	var roster:=ConfigFile.new()
	if roster.load("user://story_characters.cfg")==OK:
		var characters:Array=roster.get_value("roster","characters",[])
		for index in range(characters.size()):
			if characters[index] is Dictionary and str(characters[index].get("character_id",""))==str(profile.get("character_id","")):
				characters[index]=profile
				break
		roster.set_value("roster","characters",characters)
		roster.save("user://story_characters.cfg")

func _play_discovery_chime()->void:
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	stream.stereo=false
	var samples:=PackedByteArray()
	var sample_count:=int(22050*0.85)
	samples.resize(sample_count*2)
	for i in range(sample_count):
		var t:=float(i)/22050.0
		var envelope:=exp(-4.2*t)*(1.0-exp(-55.0*t))
		var wave:=sin(TAU*880.0*t)+0.52*sin(TAU*1320.0*t)+0.24*sin(TAU*1760.0*t)
		samples.encode_s16(i*2,int(clampi(roundi(wave*envelope*8500.0),-32768,32767)))
	stream.data=samples
	var player:=AudioStreamPlayer.new()
	player.stream=stream
	player.volume_db=-4.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	GameDiagnostics.log_event("new_loot_chime",{"gear":new_gear_ids.size(),"spells":new_spell_ids.size()})

func _item_rarity(item: Dictionary) -> int:
	return clampi(int(item.get("rarity", 1)), 1, 6)

func _animation_slot_capacity(item: Dictionary) -> int:
	return _item_rarity(item)

func _rarity_name(rarity: int) -> String:
	return ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"][clampi(rarity, 1, 6) - 1]

func _rarity_color(rarity: int) -> Color:
	return Color(["aab3be", "63d28c", "65b7ff", "c27bff", "f0cf62", "ff874c"][clampi(rarity, 1, 6) - 1])

func _sort_by_rarity(items:Array) -> Array:
	var sorted:Array=items.duplicate()
	sorted.sort_custom(func(a:Dictionary,b:Dictionary) -> bool:
		var rarity_a:=clampi(int(a.get("rarity",1)),1,6)
		var rarity_b:=clampi(int(b.get("rarity",1)),1,6)
		if rarity_a==rarity_b:return str(a.get("name",a.get("spell",""))).to_lower()<str(b.get("name",b.get("spell",""))).to_lower()
		return rarity_a>rarity_b
	)
	return sorted

func _animation_count(item: Dictionary) -> int:
	return _animation_summary(item).split(", ", false).size() if _animation_summary(item) != "None" else 0

func _spell_count(item: Dictionary) -> int:
	var count := 0
	var pairs: Array = item.get("animation_slots", [])
	if not pairs.is_empty():
		for pair in pairs:
			if not pair is Dictionary: continue
			var attached_ids: Array = pair.get("spell_ids", []).duplicate()
			var legacy_id := str(pair.get("spell_id", ""))
			if not legacy_id.is_empty() and not attached_ids.has(legacy_id): attached_ids.append(legacy_id)
			count += attached_ids.size()
			count += pair.get("spells", []).size()
		return count
	count += item.get("spell_ids", []).size()
	count += item.get("spells", []).size()
	if item.has("spell") and not str(item.spell).is_empty(): count += 1
	for spell_id in item.get("crystal_links", {}).values():
		count += spell_id.size() if spell_id is Array else (1 if not str(spell_id).is_empty() else 0)
	return count

func _animation_summary(item:Dictionary) -> String:
	var names:Array[String]=[]
	for value in item.get("native_animations",item.get("animations",[])):
		var animation_id:=str(value)
		if not names.has(_display_name(animation_id)):names.append(_display_name(animation_id))
	if item.has("ability") and not names.has(_display_name(str(item.ability))):names.append(_display_name(str(item.ability)))
	for pair in item.get("animation_slots",[]):
		if not pair is Dictionary:continue
		var animation_id:=str(pair.get("animation",""))
		if not animation_id.is_empty() and not names.has(_display_name(animation_id)):names.append(_display_name(animation_id))
	if names.is_empty():
		var slot:=str(item.get("slot",""))
		var inferred:Array={"Arms":["Punch left"],"Left arm":["Punch left"],"Right arm":["Punch right"]}.get(slot,[])
		for name in inferred:names.append(str(name))
	if names.is_empty():return "None"
	return ", ".join(names)

func _spell_summary(item:Dictionary) -> String:
	var ids:Array[String]=[]
	for pair in item.get("animation_slots",[]):
		if pair is Dictionary:
			for spell_id in pair.get("spell_ids",[]):
				if not str(spell_id).is_empty() and not ids.has(str(spell_id)):ids.append(str(spell_id))
			var spell_id:=str(pair.get("spell_id",""))
			if not spell_id.is_empty() and not ids.has(spell_id):ids.append(spell_id)
	for spell_id in item.get("spell_ids",[]):
		if not str(spell_id).is_empty() and not ids.has(str(spell_id)):ids.append(str(spell_id))
	for spell in item.get("spells",[]):
		var spell_name:=str(spell.get("spell",spell.get("name","Spell"))) if spell is Dictionary else _display_name(str(spell))
		if not spell_name.is_empty() and not ids.has(spell_name):ids.append(spell_name)
	for spell_id in item.get("crystal_links",{}).values():
		for linked_id in (spell_id if spell_id is Array else [spell_id]):
			if not str(linked_id).is_empty() and not ids.has(str(linked_id)):ids.append(str(linked_id))
	if item.has("spell") and not str(item.spell).is_empty() and not ids.has(str(item.spell)):ids.append(str(item.spell))
	if ids.is_empty():return "None"
	var names:Array[String]=[]
	for spell_id in ids:names.append(_spell_name(str(spell_id)))
	return ", ".join(names)

func _spell_name(spell_id:String) -> String:
	for spell in profile.get("spell_catalog",[]):
		if spell is Dictionary and str(spell.get("id",""))==spell_id:
			return str(spell.get("spell",spell.get("name",_display_name(spell_id))))
	return _display_name(spell_id)

func _loot_guidance() -> String:
	var history: Array = profile.get("story_history", [])
	for index in range(history.size() - 1, -1, -1):
		var entry: Variant = history[index]
		if not entry is Dictionary or not bool(entry.get("won", false)):
			continue
		match int(entry.get("fight", 0)):
			1:
				return "You earned a right-arm punch. Open Loadout, choose the right arm, and equip its punch animation."
			3:
				return "You found Block and Fireball. In Loadout, equip Block on chest gear, then attach Fireball to that animation."
			_:
				return "The rival's gear is now in your inventory. Hover over an item to inspect it."
	return "The rival's gear is now in your inventory. Hover over an item to inspect it."

func _display_name(value:String) -> String:
	return value.replace("_"," ").capitalize()

func _icon_part(slot: String) -> String:
	return {"Chest":"chest", "Bottoms":"left_leg", "Arms":"left_arm", "Left arm":"left_arm", "Right arm":"right_arm", "Hands":"left_hand", "Belt":"belt", "Footwear":"left_boot", "Legs":"left_leg", "Head":"head", "Face":"face", "Back":"back"}.get(slot, "chest")

func _item_color(slot: String) -> Color:
	return {"Chest":Color("426c91"), "Bottoms":Color("3b4148"), "Arms":Color("596579"), "Left arm":Color("596579"), "Right arm":Color("596579"), "Hands":Color("72574b"), "Belt":Color("8c6336"), "Footwear":Color("455646"), "Legs":Color("46515f"), "Head":Color("586270"), "Face":Color("647185"), "Back":Color("536c59")}.get(slot, Color("718399"))

func _add_button(parent: HBoxContainer, label: String, path: String, primary := false) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 52
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("cdaa5b")
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override("normal", style)
	button.pressed.connect(func(): get_tree().change_scene_to_file(path))
	parent.add_child(button)
