extends Control
## Click character parts to manage their one enchantment slot and input.

const CHARACTER_PATH := "user://story_character.cfg"
const PreviewCharacter := preload("res://scripts/story_character.gd")
const GearIcon := preload("res://scripts/gear_inventory_icon.gd")
const IconMetadata := preload("res://scripts/item_icon_metadata.gd")
const DraggableItem := preload("res://scripts/loadout_draggable_item.gd")
const DropSocket := preload("res://scripts/loadout_drop_socket.gd")
const BodyBarrierOverlay := preload("res://scripts/body_barrier_overlay.gd")
const PARTS := [
	{"id":"chest", "name":"Chest", "gear_key":"wardrobe_shirt", "loot_slot":"Chest", "position":Vector3(0, 1.18, 0.0), "radius":Vector3(0.29, 0.24, 0.20)},
	{"id":"left_leg", "name":"Left leg", "gear_key":"wardrobe_pants", "loot_slot":"Left leg", "position":Vector3(0.17, 0.63, 0.0), "radius":Vector3(0.16, 0.27, 0.16)},
	{"id":"right_leg", "name":"Right leg", "gear_key":"wardrobe_pants", "loot_slot":"Right leg", "position":Vector3(-0.17, 0.63, 0.0), "radius":Vector3(0.16, 0.27, 0.16)},
	{"id":"left_arm", "name":"Left arm", "gear_key":"wardrobe_arms", "loot_slot":"Left arm", "position":Vector3(0.40, 1.13, 0.0), "radius":Vector3(0.13, 0.26, 0.14)},
	{"id":"right_arm", "name":"Right arm", "gear_key":"wardrobe_arms", "loot_slot":"Right arm", "position":Vector3(-0.40, 1.13, 0.0), "radius":Vector3(0.13, 0.26, 0.14)},
	{"id":"left_hand", "name":"Left hand", "gear_key":"wardrobe_hands", "loot_slot":"Left hand", "position":Vector3(0.46, 0.82, 0.12), "radius":Vector3(0.11, 0.11, 0.11)},
	{"id":"right_hand", "name":"Right hand", "gear_key":"wardrobe_hands", "loot_slot":"Right hand", "position":Vector3(-0.46, 0.82, 0.12), "radius":Vector3(0.11, 0.11, 0.11)},
	{"id":"left_boot", "name":"Left boot", "gear_key":"wardrobe_boots", "loot_slot":"Left boot", "position":Vector3(0.16, 0.12, 0.02), "radius":Vector3(0.14, 0.13, 0.20)},
	{"id":"right_boot", "name":"Right boot", "gear_key":"wardrobe_boots", "loot_slot":"Right boot", "position":Vector3(-0.16, 0.12, 0.02), "radius":Vector3(0.14, 0.13, 0.20)},
	{"id":"head", "name":"Head", "gear_key":"wardrobe_hat", "loot_slot":"Head", "position":Vector3(0, 1.79, 0.0), "radius":Vector3(0.19, 0.20, 0.19)},
	{"id":"face", "name":"Face", "gear_key":"wardrobe_mask", "loot_slot":"Face", "position":Vector3(0, 1.57, 0.16), "radius":Vector3(0.12, 0.10, 0.10)},
	{"id":"belt", "name":"Belt", "gear_key":"wardrobe_belt", "loot_slot":"Belt", "position":Vector3(0, 0.96, 0.12), "radius":Vector3(0.25, 0.09, 0.10)},
	{"id":"back", "name":"Back", "gear_key":"wardrobe_back", "loot_slot":"Back", "position":Vector3(0, 1.13, -0.20), "radius":Vector3(0.24, 0.33, 0.12)},
]
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
const RARITY_COLORS := ["aab3be", "63d28c", "65b7ff", "c27bff", "f0cf62", "ff874c"]
const ABILITY_OPTIONS := [
	{"id":"", "name":"Empty slot"},
	{"id":"punch_left", "name":"Left punch"},
	{"id":"punch_right", "name":"Right punch"},
	{"id":"block", "name":"Block"},
	{"id":"front_kick", "name":"Front kick"},
	{"id":"dash", "name":"Dash"},
]
const DEFAULT_INPUT_ORDER := ["mouse_left","mouse_right","mouse_both","key_1","key_2","key_3","key_4","key_5","key_6","key_7","key_8","key_9"]

var profile: Dictionary = {}
var slots: Dictionary = {}
var selected_part := "chest"
var part_list: VBoxContainer
var detail_panel: VBoxContainer
var selected_label: Label
var slot_summary: Label
var gear_choice: OptionButton
var ability_choice: OptionButton
var input_choice: OptionButton
var viewport: SubViewport
var preview_container: SubViewportContainer
var preview: Node3D
var preview_camera: Camera3D
var preview_status: Label
var gear_grid: GridContainer
var crystal_grid: GridContainer
var animation_grid: GridContainer
var gear_detail: VBoxContainer
var part_labels: Dictionary = {}
var crystal_status: Label
var animation_status: Label
var equip_button: Button
var animation_detail: VBoxContainer
var inventory_gear: Array[Dictionary] = []
var inventory_crystals: Array[Dictionary] = []
var inventory_animations: Array[Dictionary] = []
var selected_gear_id := ""
var selected_crystal_id := ""
var selected_animation := ""
var part_hotspots: Dictionary = {}
var current_gear_item: Dictionary = {}
var dragging_preview := false
var last_pointer := Vector2.ZERO
var preview_spell_node: MeshInstance3D
var preview_spell_age := 0.0
var preview_spell_duration := 0.9
var preview_spell_is_barrier := false
var preview_spell_base_scale := Vector3.ONE
var barrier_preview_materials: Array = []
var active_hotkey_capture:Dictionary={}
var preview_loading := false
var loading_spinner: Label
var preview_loading_overlay: ColorRect
var preview_refresh_generation := 0
var gear_size_update_timer: Timer

func _process(delta: float) -> void:
	_poll_hotkey_mouse_capture()
	_update_part_hotspots()
	if preview_loading and is_instance_valid(loading_spinner):
		loading_spinner.rotation += delta * 4.5
	if preview_spell_is_barrier:
		preview_spell_age+=delta
		BodyBarrierOverlay.set_strength(barrier_preview_materials,0.88+0.12*sin(preview_spell_age*10.0))
		return
	if not is_instance_valid(preview_spell_node):return
	preview_spell_age += delta
	var remaining := clampf(1.0-preview_spell_age/preview_spell_duration,0.0,1.0)
	if preview_spell_is_barrier:
		preview_spell_node.scale=preview_spell_base_scale*(1.0+sin(preview_spell_age*10.0)*0.025)
	else:
		preview_spell_node.position.z += delta * 3.0
		preview_spell_node.scale = preview_spell_base_scale * (0.82+sin(preview_spell_age*18.0)*0.12) * remaining
	var material := preview_spell_node.material_override as StandardMaterial3D
	if material != null:material.albedo_color.a = (0.10+sin(preview_spell_age*10.0)*0.035) if preview_spell_is_barrier else remaining
	if preview_spell_age >= preview_spell_duration:
		preview_spell_node.queue_free()
		preview_spell_node = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var config := ConfigFile.new()
	if config.load(CHARACTER_PATH) != OK:
		set_process(false)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/home.tscn")
		return
	profile = config.get_value("character", "profile", {})
	if profile.is_empty():
		set_process(false)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/home.tscn")
		return
	_migrate_equipped_gear()
	_ensure_slots()
	_migrate_gear_abilities()
	_migrate_legacy_rival_loot()
	_ensure_demo_inventory()
	_ensure_animation_inventory()
	_sync_animation_bindings()
	_mark_loadout_discoveries_seen()
	gear_size_update_timer = Timer.new()
	gear_size_update_timer.one_shot = true
	gear_size_update_timer.wait_time = 0.18
	gear_size_update_timer.timeout.connect(_commit_gear_size_update)
	add_child(gear_size_update_timer)
	_build_ui()
	_select_part(selected_part)
	GameDiagnostics.log_event("loadout_opened", {"character":profile.get("name", ""), "parts":PARTS.size(), "filled_slots":3})

func _mark_loadout_discoveries_seen() -> void:
	var unseen: Variant = profile.get("unseen_loadout_ids", [])
	if not unseen is Array or unseen.is_empty():
		return
	profile["unseen_loadout_ids"] = []
	var config := ConfigFile.new()
	config.set_value("character", "profile", profile)
	if config.save(CHARACTER_PATH) != OK:
		return
	var roster := ConfigFile.new()
	if roster.load("user://story_characters.cfg") != OK:
		return
	var characters: Array = roster.get_value("roster", "characters", [])
	var character_id := str(profile.get("character_id", ""))
	for index in range(characters.size()):
		if characters[index] is Dictionary and (str(characters[index].get("character_id", "")) == character_id or (character_id.is_empty() and str(characters[index].get("name", "")) == str(profile.get("name", "")))):
			characters[index] = profile.duplicate(true)
			break
	roster.set_value("roster", "characters", characters)
	roster.save("user://story_characters.cfg")
	GameDiagnostics.log_event("loadout_discoveries_seen", {"count":unseen.size()})

func _ensure_slots() -> void:
	var saved: Variant = profile.get("gear_slots", {})
	slots = saved.duplicate(true) if saved is Dictionary else {}
	var defaults := {
		"chest":{"ability":"", "input":"mouse_both"},
		"left_arm":{"ability":"punch_left", "input":"mouse_left"},
		"right_arm":{"ability":"", "input":"mouse_right"},
	}
	for part in PARTS:
		var id: String = part.id
		if not slots.has(id):
			slots[id] = defaults.get(id, {"ability":"", "input":"key_1"}).duplicate(true)
		else:
			var value: Variant = slots[id]
			if not value is Dictionary:
				slots[id] = defaults.get(id, {"ability":"", "input":"key_1"}).duplicate(true)
			elif defaults.has(id):
				for key in defaults[id]:
					if not slots[id].has(key):
						slots[id][key] = defaults[id][key]

func _migrate_equipped_gear() -> void:
	var part_gear: Dictionary = profile.get("story_part_gear", {})
	var equipped: Array = profile.get("story_equipped_items", [])
	if equipped.is_empty():
		return
	for item in profile.get("story_loot", []):
		if not item is Dictionary:
			continue
		var id := str(item.get("id", item.get("name", "gear")))
		if not equipped.has(id):
			continue
		var slot := str(item.get("slot", ""))
		var part_ids: Array[String] = []
		match slot:
			"Chest": part_ids = ["chest"]
			"Bottoms": part_ids = ["left_leg"]
			"Arms": part_ids = ["left_arm"]
			"Left arm": part_ids = ["left_arm"]
			"Right arm": part_ids = ["right_arm"]
			"Left leg": part_ids = ["left_leg"]
			"Right leg": part_ids = ["right_leg"]
			"Left hand": part_ids = ["left_hand"]
			"Right hand": part_ids = ["right_hand"]
			"Hands": part_ids = ["left_hand"]
			"Belt": part_ids = ["belt"]
			"Footwear": part_ids = ["left_boot"]
			"Left boot": part_ids = ["left_boot"]
			"Right boot": part_ids = ["right_boot"]
			"Legs": part_ids = ["left_leg", "right_leg"]
			"Head": part_ids = ["head"]
			"Face": part_ids = ["face"]
			"Back": part_ids = ["back"]
		for part_id in part_ids:
			if not part_gear.has(part_id):
				part_gear[part_id] = id
	profile["story_part_gear"] = part_gear

func _migrate_legacy_rival_loot() -> void:
	# Older saves recorded rival clothing without the animations it carried.
	# Restore known chest blocks and arm punches, and split old shared arm wraps
	# into a right-arm item so both punches are visible and lootable.
	var loot:Array=profile.get("story_loot",[])
	var right_side_clones:Array[Dictionary]=[]
	var victories:Dictionary={}
	for record in profile.get("story_history",[]):
		if record is Dictionary and bool(record.get("won",false)):
			victories[int(record.get("fight",0))]=true
	var right_arm_available:=false
	for item in loot:
		if not item is Dictionary:continue
		var slot:=str(item.get("slot",""))
		if slot=="Chest" and not item.has("ability") and str(item.get("id", "")).begins_with("fight-3-"):item["ability"]="block"
		elif slot=="Arms":
			item["slot"]="Left arm"
			item["part"]="left_arm"
			if not str(item.get("name","")).to_lower().contains("left"):
				item["name"]=str(item.get("name","Arm wraps")).replace(" arm wraps"," left arm wraps")
			if not item.has("ability"):item["ability"]="punch_left"
		elif slot in ["Left arm","Right arm"]:
			item["part"]="left_arm" if slot=="Left arm" else "right_arm"
			if slot=="Right arm":right_arm_available=true
		elif slot in ["Bottoms","Legs"]:
			var shared_bottom:Dictionary=item.duplicate(true)
			item["slot"]="Left leg"
			item["part"]="left_leg"
			if not str(item.get("name","")).to_lower().contains("left"):
				item["name"]=str(item.get("name","Bottoms")).replace(" bottoms"," left trouser leg")
			shared_bottom["id"]="%s-right-leg"%str(shared_bottom.get("id",shared_bottom.get("name","legacy-bottoms")))
			shared_bottom["slot"]="Right leg"
			shared_bottom["part"]="right_leg"
			shared_bottom["name"]=str(shared_bottom.get("name","Bottoms")).replace(" bottoms"," right trouser leg")
			right_side_clones.append(shared_bottom)
		elif slot=="Footwear":
			var shared_boots:Dictionary=item.duplicate(true)
			item["slot"]="Left boot"
			item["part"]="left_boot"
			if not str(item.get("name","")).to_lower().contains("left"):
				item["name"]=str(item.get("name","Footwear")).replace(" footwear"," left boot")
			shared_boots["id"]="%s-right-boot"%str(shared_boots.get("id",shared_boots.get("name","legacy-footwear")))
			shared_boots["slot"]="Right boot"
			shared_boots["part"]="right_boot"
			shared_boots["name"]=str(shared_boots.get("name","Footwear")).replace(" footwear"," right boot")
			right_side_clones.append(shared_boots)
		elif slot=="Hands":
			var shared_hand:Dictionary=item.duplicate(true)
			item["slot"]="Left hand"
			item["part"]="left_hand"
			item["name"]=str(item.get("name","Hand gear")).replace("hands","left hand")
			shared_hand["id"]="%s-right-hand"%str(shared_hand.get("id",shared_hand.get("name","legacy-hand")))
			shared_hand["slot"]="Right hand"
			shared_hand["part"]="right_hand"
			shared_hand["name"]=str(shared_hand.get("name","Hand gear")).replace("hands","right hand")
			right_side_clones.append(shared_hand)
	for fight in victories:
		var right_id:="fight-%d-right-arm"%int(fight)
		if not right_arm_available:loot.append({"id":right_id,"name":"Peasant right arm wraps","slot":"Right arm","part":"right_arm","ability":"punch_right"})
		break
	for duplicate in right_side_clones:
		var duplicate_id:=str(duplicate.get("id",""))
		var exists:=false
		for existing in loot:
			if existing is Dictionary and str(existing.get("id",""))==duplicate_id:exists=true;break
		if not exists:loot.append(duplicate)
	profile["story_loot"]=loot

func _ensure_demo_inventory() -> void:
	var saved_items:Variant=profile.get("gear_inventory",[])
	inventory_gear.clear()
	var prior_starters:Dictionary={}
	if saved_items is Array and not saved_items.is_empty():
		for item in saved_items:
			if item is Dictionary and str(item.get("id", "")).begins_with("starter_"):
				prior_starters[str(item.get("id", ""))]=item.duplicate(true)
			elif item is Dictionary and not str(item.get("id", "")).begins_with("demo_") and not str(item.get("name", "")).to_lower().begins_with("bare "):
				var normalized:Dictionary=item.duplicate(true)
				_normalize_gear_side(normalized)
				inventory_gear.append(normalized)
	# The creator's chosen appearance is the only starting gear. Remove old
	# placeholder rows for parts set to None/Bare, while keeping genuine loot.
	for index in range(inventory_gear.size() - 1, -1, -1):
		var saved_id := str(inventory_gear[index].get("id", ""))
		if saved_id.begins_with("starter_"):
			inventory_gear.remove_at(index)
	var equipped:Dictionary=profile.get("story_part_gear",{}).duplicate(true)
	for part in PARTS:
		var part_id:=str(part.id)
		var appearance:=_base_appearance(part_id)
		var appearance_key:=str(part.get("gear_key", ""))
		var selected_look:=str(appearance.get(appearance_key, "None")) if not appearance_key.is_empty() else "None"
		if selected_look.to_lower() in ["", "none", "bare"]:
			if str(equipped.get(part_id, "")).begins_with("starter_"):equipped.erase(part_id)
			continue
		var starter_id:="starter_%s"%part_id
		var base_animations:Array=["punch_left"] if part_id=="left_arm" else []
		var starter:Dictionary=prior_starters.get(starter_id,{"id":starter_id,"part":part_id,"slot":str(part.loot_slot),"rarity":1,"native_animations":base_animations,"crystal_links":{}}).duplicate(true)
		starter["name"]=selected_look+" "+str(part.name).to_lower()
		starter["part"]=part_id
		starter["slot"]=str(part.loot_slot)
		starter["appearance"]=appearance
		if not starter.has("native_animations"):starter["native_animations"]=base_animations
		if not starter.has("crystal_links"):starter["crystal_links"]={}
		if part_id=="left_arm":
			var starter_slots:Array=starter.get("animation_slots",[])
			if starter_slots.is_empty():
				starter["animation_slots"]=[{"animation":"punch_left","spell_ids":[],"spell_id":"","input":"mouse_left"}]
			else:
				var has_punch:=false
				for pair in starter_slots:
					if pair is Dictionary and str(pair.get("animation",""))=="punch_left":has_punch=true
				# Older profiles may have the starter punch stored in the loose
				# animation inventory instead of on its arm gear. Put it back in
				# the original slot during migration, then the inventory pass below
				# removes the duplicate loose copy.
				var saved_animations:Array=profile.get("animation_inventory",[])
				var punch_is_owned:=false
				for saved_animation in saved_animations:
					if saved_animation is Dictionary and str(saved_animation.get("id",""))=="animation_punch_left":punch_is_owned=true
				if not has_punch and punch_is_owned:
					for slot_index in range(starter_slots.size()):
						if starter_slots[slot_index] is Dictionary and str(starter_slots[slot_index].get("animation","")).is_empty():
							starter_slots[slot_index]={"animation":"punch_left","spell_ids":[],"spell_id":"","input":"mouse_left"}
							break
				starter["animation_slots"]=starter_slots
		inventory_gear.append(starter)
		if not equipped.has(part_id) or str(equipped[part_id]).begins_with("starter_"):
			equipped[part_id]=starter_id
	profile["story_part_gear"]=equipped
	for loot in profile.get("story_loot",[]):
		if not loot is Dictionary:continue
		if str(loot.get("name", "")).to_lower().begins_with("bare "):continue
		var loot_id:=str(loot.get("id",loot.get("name","loot")))
		var loot_slot:=str(loot.get("slot",""))
		var part_id:=_part_id_for_slot(loot_slot)
		var animations:Array=loot.get("native_animations",[]).duplicate(true)
		if loot.has("ability") and not animations.has(str(loot.ability)):animations.append(str(loot.ability))
		if animations.is_empty():
			var fallback_animation:=str({"Arms":"punch_left","Left arm":"punch_left","Right arm":"punch_right"}.get(loot_slot,""))
			if not fallback_animation.is_empty():animations.append(fallback_animation)
		var existing:=_gear_by_id(loot_id)
		if not existing.is_empty():
			existing["slot"]=loot_slot
			existing["part"]=str(loot.get("part",part_id))
			existing["name"]=str(loot.get("name",existing.get("name","Gear")))
			var existing_animations:Array=existing.get("native_animations",[])
			for animation_id in animations:
				if not existing_animations.has(animation_id):existing_animations.append(animation_id)
			existing["native_animations"]=existing_animations
			if loot.has("animation_slots"):existing["animation_slots"]=loot["animation_slots"].duplicate(true)
			if loot.has("crystal_links"):existing["crystal_links"]=loot["crystal_links"].duplicate(true)
			continue
		var gear_item:Dictionary={"id":loot_id,"name":str(loot.get("name","Gear")),"part":str(loot.get("part",part_id)),"slot":loot_slot,"rarity":int(loot.get("rarity",1)),"appearance":_appearance_from_loot(loot),"native_animations":animations,"crystal_links":loot.get("crystal_links",{}).duplicate(true)}
		for key in ["animation_slots","spell_ids","spells"]:
			if loot.has(key):gear_item[key]=loot[key].duplicate(true) if loot[key] is Array or loot[key] is Dictionary else loot[key]
		inventory_gear.append(gear_item)
	var saved_crystals:Variant=profile.get("spell_inventory",profile.get("crystal_inventory",[]))
	if saved_crystals is Array and not saved_crystals.is_empty():
		for crystal in saved_crystals:
			if crystal is Dictionary:inventory_crystals.append(crystal.duplicate(true))
	profile["spell_inventory_initialized"] = true
	profile["gear_inventory"]=inventory_gear.duplicate(true)
	profile["crystal_inventory"]=inventory_crystals.duplicate(true)
	profile["spell_inventory"]=inventory_crystals.duplicate(true)
	_save_profile_only()

func _ensure_animation_inventory() -> void:
	var saved:Variant=profile.get("animation_inventory",[])
	inventory_animations.clear()
	if saved is Array:
		for animation in saved:
			if animation is Dictionary:
				var entry:Dictionary=animation.duplicate(true)
				var animation_id:=str(entry.get("animation",""))
				entry["body_type"]=_animation_body_type(animation_id)
				entry["part"]=_animation_part(animation_id)
				inventory_animations.append(entry)
	var spell_catalog:Array=profile.get("spell_catalog",[]).duplicate(true)
	for spell in inventory_crystals:
		if not _dictionary_array_has_id(spell_catalog,str(spell.get("id",""))):spell_catalog.append(spell.duplicate(true))
	profile["spell_catalog"]=spell_catalog
	var migrate_blue_shirt_block:=false
	for item in inventory_gear:
		var capacity:=_pair_capacity(item)
		var pair_slots:Array=item.get("animation_slots",[]).duplicate(true)
		var reserved_inputs:Array=[]
		for existing_pair in pair_slots:
			if existing_pair is Dictionary and not str(existing_pair.get("animation","")).is_empty():
				var existing_input:=str(existing_pair.get("input",""))
				if not existing_input.is_empty():reserved_inputs.append(existing_input)
		if pair_slots.is_empty():
			var links:Dictionary=item.get("crystal_links",{})
			for animation_id in item.get("native_animations",[]):
				var id:=str(animation_id)
				var default_input:=_default_assignment_input(id,reserved_inputs)
				pair_slots.append({"animation":id,"spell_ids":_spell_ids_from_value(links.get(id,"")),"input":default_input})
				reserved_inputs.append(default_input)
		else:
			# Older saves can have a reserved empty slot alongside a legacy
			# native_animations list. Migrate those animations into the first open
			# slots instead of silently leaving the item unable to use them.
			var legacy_links:Dictionary=item.get("crystal_links",{})
			for animation_value in item.get("native_animations",[]):
				var legacy_animation:=str(animation_value)
				var already_attached:=false
				for existing_pair in pair_slots:
					if existing_pair is Dictionary and str(existing_pair.get("animation",""))==legacy_animation:
						already_attached=true
						break
				if already_attached:continue
				for pair_index in range(pair_slots.size()):
					if pair_slots[pair_index] is Dictionary and str(pair_slots[pair_index].get("animation","" )).is_empty():
						var default_input:=_default_assignment_input(legacy_animation,reserved_inputs)
						pair_slots[pair_index]={"animation":legacy_animation,"spell_ids":_spell_ids_from_value(legacy_links.get(legacy_animation,"")),"input":default_input}
						reserved_inputs.append(default_input)
						break
		if migrate_blue_shirt_block and str(item.get("id",""))=="demo_shirt_blue":
			var has_animation:=false
			for existing_pair in pair_slots:
				if existing_pair is Dictionary and not str(existing_pair.get("animation","")).is_empty():has_animation=true
			if not has_animation and not pair_slots.is_empty():
				pair_slots[0]={"animation":"block","spell_ids":[],"input":"mouse_both"}
				reserved_inputs.append("mouse_both")
		while pair_slots.size()<capacity:
			pair_slots.append({"animation":"","spell_ids":[],"input":"key_1"})
		while pair_slots.size()>capacity:
			var extra:Dictionary=pair_slots.pop_back()
			var extra_animation:=str(extra.get("animation",""))
			var extra_spells:=_pair_spell_ids(extra)
			if not extra_animation.is_empty():_add_animation_to_inventory(extra_animation)
			for extra_spell in extra_spells:_add_spell_to_inventory(extra_spell)
		# Older starter-arm saves could leave the default punch detached in the
		# animation inventory. Restore it to its original left-arm slot so the
		# character keeps the basic combat move they started with.
		if str(item.get("id",""))=="starter_left_arm":
			var has_left_punch:=false
			for slot in pair_slots:
				if slot is Dictionary and str(slot.get("animation",""))=="punch_left":has_left_punch=true
			if not has_left_punch:
				for animation in inventory_animations:
					if str(animation.get("id",""))=="animation_punch_left":
						for slot_index in range(pair_slots.size()):
							if pair_slots[slot_index] is Dictionary and str(pair_slots[slot_index].get("animation","" )).is_empty():
								pair_slots[slot_index]={"animation":"punch_left","spell_ids":[],"spell_id":"","input":"mouse_left"}
								break
						break
		for slot in pair_slots:
			if not slot is Dictionary:continue
			if not slot.has("animation"):slot["animation"]=""
			var attached_spells:=_pair_spell_ids(slot)
			slot["spell_ids"]=attached_spells
			slot["spell_id"]=str(attached_spells[0]) if not attached_spells.is_empty() else ""
			if not slot.has("input") or str(slot.get("input","")).is_empty():
				var default_input:=_default_assignment_input(str(slot.get("animation","")),reserved_inputs) if not str(slot.get("animation","")).is_empty() else "key_1"
				slot["input"]=default_input
				if not str(slot.get("animation","")).is_empty():reserved_inputs.append(default_input)
		item["animation_slots"]=pair_slots
		var attached:Array=[]
		var crystal_links:Dictionary={}
		for slot in pair_slots:
			var animation_id:=str(slot.get("animation",""))
			if animation_id.is_empty():continue
			attached.append(animation_id)
			var spell_ids:=_pair_spell_ids(slot)
			if not spell_ids.is_empty():crystal_links[animation_id]=spell_ids.duplicate()
		item["native_animations"]=attached
		item["crystal_links"]=crystal_links
		for animation_id in attached:
			_remove_animation_from_inventory(str(animation_id))
			for spell_id in _spell_ids_from_value(crystal_links.get(str(animation_id),[])):_remove_spell_from_inventory(spell_id)
	var attached_ids:Dictionary={}
	var punch_available:=false
	for item in inventory_gear:
		if item.get("native_animations",[]).has("punch_left"):punch_available=true
		for slot in item.get("animation_slots",[]):
			var animation_id:=str(slot.get("animation",""))
			if not animation_id.is_empty():
				attached_ids["animation_%s"%animation_id]=true
				if animation_id=="punch_left":punch_available=true
	inventory_animations=inventory_animations.filter(func(entry:Dictionary):return not attached_ids.has(str(entry.get("id",""))))
	for animation in inventory_animations:
		if str(animation.get("animation",""))=="punch_left":punch_available=true
	if not punch_available:
		_add_animation_to_inventory("punch_left")
	profile["gear_inventory"]=inventory_gear.duplicate(true)
	profile["animation_inventory"]=inventory_animations.duplicate(true)
	profile["spell_inventory"]=inventory_crystals.duplicate(true)
	profile["crystal_inventory"]=inventory_crystals.duplicate(true)
	profile["blue_shirt_block_migrated"]=true
	_save_profile_only()

func _dictionary_array_has_id(items:Array,item_id:String) -> bool:
	for item in items:
		if item is Dictionary and str(item.get("id",""))==item_id:return true
	return false

func _spell_ids_from_value(value:Variant) -> Array[String]:
	var ids:Array[String]=[]
	if value is Array:
		for spell_id in value:
			if not str(spell_id).is_empty():ids.append(str(spell_id))
	elif value is Dictionary:
		for spell_id in value.get("spell_ids",[]):
			if not str(spell_id).is_empty():ids.append(str(spell_id))
	elif not str(value).is_empty():
		ids.append(str(value))
	return ids

func _pair_spell_ids(pair:Dictionary) -> Array[String]:
	var ids:=_spell_ids_from_value(pair.get("spell_ids",[]))
	var legacy_id:=str(pair.get("spell_id",""))
	if not legacy_id.is_empty() and not ids.has(legacy_id):ids.append(legacy_id)
	return ids

func _remove_animation_from_inventory(animation_id:String) -> void:
	var animation_item_id:="animation_%s"%animation_id
	for index in range(inventory_animations.size()-1,-1,-1):
		if str(inventory_animations[index].get("id",""))==animation_item_id:inventory_animations.remove_at(index)

func _remove_spell_from_inventory(spell_id:String) -> void:
	for index in range(inventory_crystals.size()-1,-1,-1):
		if str(inventory_crystals[index].get("id",""))==spell_id:inventory_crystals.remove_at(index)

func _default_input_for_animation(animation_id:String) -> String:
	return {"punch_left":"mouse_left","punch_right":"mouse_right","block":"mouse_both"}.get(animation_id,"key_1")

func _animation_name(animation_id:String) -> String:
	return {"punch_left":"Left punch","punch_right":"Right punch","block":"Block","front_kick":"Front kick","dash":"Dash"}.get(animation_id,animation_id.replace("_"," ").capitalize())

func _animation_body_type(animation_id:String) -> String:
	# Animation category is the body region the motion belongs to. Gear only
	# accepts animations from the same category.
	return {"punch_left":"arm","punch_right":"arm","block":"chest","front_kick":"leg","dash":"foot"}.get(animation_id,"")

func _part_body_type(part_id:String) -> String:
	return {"chest":"chest","left_arm":"arm","right_arm":"arm","left_hand":"hand","right_hand":"hand","left_leg":"leg","right_leg":"leg","left_boot":"foot","right_boot":"foot","head":"head","face":"face","belt":"waist","back":"back"}.get(part_id,"")

func _animation_part(animation_id:String) -> String:
	return {"punch_left":"left_arm","punch_right":"right_arm","block":"chest","front_kick":"left_leg","dash":"left_boot"}.get(animation_id,"chest")

func _animation_compatible_with_part(animation_id:String,part_id:String) -> bool:
	var animation_type:=_animation_body_type(animation_id)
	if animation_type.is_empty() or animation_type!=_part_body_type(part_id):return false
	# Side-specific punches stay on their matching arm; generic leg and foot
	# motions can be placed on either matching side.
	if animation_id=="punch_left":return part_id=="left_arm"
	if animation_id=="punch_right":return part_id=="right_arm"
	return animation_id in ["block","front_kick","dash"]

func _add_animation_to_inventory(animation_id:String) -> void:
	if animation_id.is_empty():return
	var animation_item_id:="animation_%s"%animation_id
	for item in inventory_animations:
		if str(item.get("id",""))==animation_item_id:return
	inventory_animations.append({"id":animation_item_id,"name":_animation_name(animation_id),"animation":animation_id,"body_type":_animation_body_type(animation_id),"part":_animation_part(animation_id)})

func _add_spell_to_inventory(spell_id:String) -> void:
	if spell_id.is_empty():return
	for spell in inventory_crystals:
		if str(spell.get("id",""))==spell_id:return
	for spell in profile.get("spell_catalog",profile.get("spell_inventory",profile.get("crystal_inventory",[]))):
		if spell is Dictionary and str(spell.get("id",""))==spell_id:
			inventory_crystals.append(spell.duplicate(true))
			return

func _base_appearance(part_id:String) -> Dictionary:
	var part:=_part_data(part_id)
	var gear_key:=str(part.get("gear_key",""))
	var color_key:=str({"chest":"shirt_color","left_arm":"gloves_color","right_arm":"gloves_color","left_hand":"handwear_color","right_hand":"handwear_color","left_leg":"bottoms_color","right_leg":"bottoms_color","left_boot":"footwear_color","right_boot":"footwear_color","head":"hat_color","face":"mask_color","belt":"belt_color","back":"back_color"}.get(part_id,""))
	var appearance:Dictionary={}
	if not gear_key.is_empty():appearance[gear_key]=profile.get(gear_key,"None")
	if not color_key.is_empty():appearance[color_key]=profile.get(color_key,Color.WHITE)
	if part_id=="chest":appearance["wardrobe_shirt"]=profile.get("wardrobe_shirt","Peasant")
	var size_key := _size_key_for_part(part_id)
	if not size_key.is_empty():appearance["gear_size"] = float(profile.get(size_key, 1.0))
	return appearance

func _size_key_for_part(part_id:String) -> String:
	return str({
		"chest":"top_size",
		"left_arm":"gloves_size", "right_arm":"gloves_size",
		"left_hand":"handwear_size", "right_hand":"handwear_size",
		"left_leg":"bottoms_size", "right_leg":"bottoms_size",
		"left_boot":"footwear_size", "right_boot":"footwear_size",
		"head":"hat_size", "face":"mask_size", "belt":"belt_size", "back":"back_size",
	}.get(part_id, ""))

func _appearance_from_loot(item:Dictionary) -> Dictionary:
	var name_:String=str(item.get("name","")).to_lower()
	var slot_:String=str(item.get("slot",""))
	var variant:="Peasant"
	if "traveler" in name_ or "dash boot" in name_:variant="Traveler"
	elif "guard" in name_ or "reinforced" in name_:variant="Guard castoff"
	match slot_:
		"Chest":return {"wardrobe_shirt":variant,"shirt_color":Color("426c91")}
		"Bottoms", "Legs", "Left leg", "Right leg":return {"wardrobe_pants":variant,"bottoms_color":Color("34383e")}
		"Arms", "Left arm", "Right arm":return {"wardrobe_arms":variant,"gloves_color":Color("29313b")}
		"Left hand", "Right hand", "Hands":return {"wardrobe_hands":"Fingerless gloves","handwear_color":Color("29313b")}
		"Footwear", "Left boot", "Right boot":return {"wardrobe_boots":variant,"footwear_color":Color("354438")}
		"Head":return {"wardrobe_hat":"Hood","hat_color":Color("3b3028")}
		"Face":return {"wardrobe_mask":"Rogue mask","mask_color":Color("29313b")}
		"Belt":return {"wardrobe_belt":"Leather belt","belt_color":Color("8a6135")}
	return {}

func _part_id_for_slot(slot:String) -> String:
	return {"Chest":"chest","Bottoms":"left_leg","Legs":"left_leg","Left leg":"left_leg","Right leg":"right_leg","Arms":"left_arm","Left arm":"left_arm","Right arm":"right_arm","Left hand":"left_hand","Right hand":"right_hand","Hands":"left_hand","Footwear":"left_boot","Left boot":"left_boot","Right boot":"right_boot","Head":"head","Face":"face","Belt":"belt","Back":"back"}.get(slot,"chest")

func _normalize_gear_side(item:Dictionary) -> void:
	var slot:=str(item.get("slot",""))
	var part:=str(item.get("part",""))
	if slot=="Arms":slot="Right arm" if part=="right_arm" else "Left arm"
	elif slot in ["Bottoms","Legs"]:slot="Right leg" if part=="right_leg" else "Left leg"
	elif slot=="Footwear":slot="Right boot" if part=="right_boot" else "Left boot"
	elif slot=="Hands":slot="Right hand" if part=="right_hand" else "Left hand"
	item["slot"]=slot
	item["part"]=_part_id_for_slot(slot)
	var item_name:=str(item.get("name","Gear"))
	var side:="left" if slot.to_lower().begins_with("left") else ("right" if slot.to_lower().begins_with("right") else "")
	if not side.is_empty() and not item_name.to_lower().contains(side):
		if slot.ends_with("arm"):item_name=item_name.replace("arm wraps","%s arm wraps"%side)
		elif slot.ends_with("leg"):item_name=item_name.replace("bottoms","%s trouser leg"%side)
		elif slot.ends_with("boot"):item_name=item_name.replace("footwear","%s boot"%side)
		elif slot.ends_with("hand"):item_name=item_name.replace("hands","%s hand"%side)
	item["name"]=item_name

func _gear_by_id(item_id:String) -> Dictionary:
	for item in inventory_gear:
		if str(item.get("id",""))==item_id:return item
	return {}

func _save_profile_only() -> void:
	for item in inventory_gear:
		IconMetadata.normalize(item)
	for item in inventory_crystals:
		IconMetadata.normalize(item)
	for item in inventory_animations:
		IconMetadata.normalize(item)
	for collection_key in ["story_loot", "spell_catalog"]:
		var collection:Variant=profile.get(collection_key, [])
		if not collection is Array:continue
		for item in collection:
			if item is Dictionary:IconMetadata.normalize(item)
	profile["gear_inventory"]=inventory_gear.duplicate(true)
	profile["crystal_inventory"]=inventory_crystals.duplicate(true)
	profile["spell_inventory"]=inventory_crystals.duplicate(true)
	profile["animation_inventory"]=inventory_animations.duplicate(true)
	var config:=ConfigFile.new()
	config.set_value("character","profile",profile)
	config.save(CHARACTER_PATH)

func _migrate_gear_abilities() -> void:
	var part_gear: Dictionary = profile.get("story_part_gear", {})
	for part_id in part_gear:
		if not slots.has(part_id):
			continue
		for item in profile.get("story_loot", []):
			if item is Dictionary and str(item.get("id", item.get("name", "gear"))) == str(part_gear[part_id]) and item.has("ability"):
				if str(slots.get(part_id, {}).get("ability", "")).is_empty():
					slots[part_id]["ability"] = str(item.ability)
				break

func _build_ui() -> void:
	var book_theme := Theme.new()
	book_theme.set_color("font_color", "Label", Color("382c1c"))
	book_theme.set_color("font_color", "Button", Color("382c1c"))
	book_theme.set_color("font_color", "OptionButton", Color("382c1c"))
	theme = book_theme
	var background := ColorRect.new()
	background.color = Color("302116")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var cover := PanelContainer.new()
	var cover_style := StyleBoxFlat.new()
	cover_style.bg_color = Color("d8c7a4")
	cover_style.border_color = Color("765b38")
	cover_style.set_border_width_all(3)
	cover_style.set_corner_radius_all(8)
	cover.add_theme_stylebox_override("panel", cover_style)
	margin.add_child(cover)
	var book_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		book_margin.add_theme_constant_override("margin_" + side, 14)
	cover.add_child(book_margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	book_margin.add_child(columns)
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size.x = 420
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = Color("e8ddc4")
	page_style.border_color = Color("b5a27f")
	page_style.set_border_width_all(1)
	left_panel.add_theme_stylebox_override("panel", page_style)
	columns.add_child(left_panel)
	var inner := MarginContainer.new()
	for side in ["left", "right"]:
		inner.add_theme_constant_override("margin_" + side, 14)
	inner.add_theme_constant_override("margin_top", 12)
	inner.add_theme_constant_override("margin_bottom", 10)
	left_panel.add_child(inner)
	var left_column := VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 5)
	inner.add_child(left_column)
	var title := Label.new()
	title.text = "LOADOUT"
	title.add_theme_font_size_override("font_size", 25)
	left_column.add_child(title)
	selected_label = Label.new()
	selected_label.add_theme_font_size_override("font_size", 17)
	left_column.add_child(selected_label)
	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_column.add_child(inventory_scroll)
	var inventory_column := VBoxContainer.new()
	inventory_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_column.add_theme_constant_override("separation", 6)
	inventory_scroll.add_child(inventory_column)
	var gear_heading:=Label.new()
	gear_heading.text="GEAR"
	gear_heading.add_theme_color_override("font_color",Color("e9c982"))
	inventory_column.add_child(gear_heading)
	gear_grid=GridContainer.new()
	gear_grid.columns=4
	gear_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	gear_grid.add_theme_constant_override("h_separation",6)
	gear_grid.add_theme_constant_override("v_separation",6)
	inventory_column.add_child(gear_grid)
	gear_detail=VBoxContainer.new()
	gear_detail.add_theme_constant_override("separation",2)
	inventory_column.add_child(gear_detail)
	var animation_heading:=Label.new()
	animation_heading.text="ANIMATIONS"
	animation_heading.add_theme_color_override("font_color",Color("d7c5ff"))
	inventory_column.add_child(animation_heading)
	animation_grid=GridContainer.new()
	animation_grid.columns=5
	animation_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	animation_grid.add_theme_constant_override("h_separation",5)
	animation_grid.add_theme_constant_override("v_separation",5)
	inventory_column.add_child(animation_grid)
	animation_status=Label.new()
	animation_status.text="Drag onto gear · click to preview."
	animation_status.add_theme_font_size_override("font_size",11)
	animation_status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	animation_status.add_theme_color_override("font_color",Color("655740"))
	inventory_column.add_child(animation_status)
	var divider := HSeparator.new()
	inventory_column.add_child(divider)
	var crystal_heading:=Label.new()
	crystal_heading.text="SPELLS"
	crystal_heading.add_theme_color_override("font_color",Color("496d88"))
	inventory_column.add_child(crystal_heading)
	crystal_grid=GridContainer.new()
	crystal_grid.columns=5
	crystal_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	crystal_grid.add_theme_constant_override("h_separation",5)
	crystal_grid.add_theme_constant_override("v_separation",5)
	inventory_column.add_child(crystal_grid)
	crystal_status=Label.new()
	crystal_status.text="Drag onto an animation."
	crystal_status.add_theme_font_size_override("font_size",11)
	crystal_status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	crystal_status.add_theme_color_override("font_color",Color("655740"))
	inventory_column.add_child(crystal_status)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	left_column.add_child(buttons)
	var back := Button.new()
	back.text = "BACK"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.custom_minimum_size = Vector2(82, 40)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/story_opponents.tscn"))
	buttons.add_child(back)
	var spine := ColorRect.new()
	spine.color = Color("98794d")
	spine.custom_minimum_size.x = 8
	spine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(spine)
	_build_preview_panel(columns)
	_build_part_hotspots()
	_refresh_inventory()
	_refresh_crystals()
	_refresh_animations()

func _build_preview_panel(columns: HBoxContainer) -> void:
	var preview_column := VBoxContainer.new()
	preview_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(preview_column)
	var heading := Label.new()
	heading.text = "CLICK A BODY PART  ·  DRAG TO ROTATE  ·  WHEEL TO ZOOM"
	heading.add_theme_color_override("font_color", Color("614421"))
	preview_column.add_child(heading)
	preview_status = Label.new()
	preview_status.text = "Preparing character preview…"
	preview_status.add_theme_color_override("font_color", Color("655740"))
	preview_column.add_child(preview_status)
	preview_container = SubViewportContainer.new()
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_container.stretch = true
	preview_container.gui_input.connect(_on_preview_input)
	preview_column.add_child(preview_container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 900)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_container.add_child(viewport)
	preview_loading = true
	preview_loading_overlay = ColorRect.new()
	preview_loading_overlay.color = Color(0.10, 0.08, 0.06, 0.62)
	preview_loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_loading_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.add_child(preview_loading_overlay)
	var loading_center := CenterContainer.new()
	loading_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_loading_overlay.add_child(loading_center)
	var loading_content := VBoxContainer.new()
	loading_content.alignment = BoxContainer.ALIGNMENT_CENTER
	loading_content.add_theme_constant_override("separation", 8)
	loading_center.add_child(loading_content)
	loading_spinner = Label.new()
	loading_spinner.text = "◌"
	loading_spinner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_spinner.add_theme_font_size_override("font_size", 54)
	loading_spinner.add_theme_color_override("font_color", Color("e9c982"))
	loading_content.add_child(loading_spinner)
	var loading_text := Label.new()
	loading_text.text = "Loading character…"
	loading_text.add_theme_font_size_override("font_size", 18)
	loading_text.add_theme_color_override("font_color", Color("f4ead5"))
	loading_content.add_child(loading_text)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("c8b28c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9bed1")
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	viewport.add_child(environment_node)
	preview_camera = Camera3D.new()
	preview_camera.position = Vector3(0, 1.02, 4.15)
	preview_camera.fov = 33
	viewport.add_child(preview_camera)
	preview_camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, -28, 0)
	key_light.light_energy = 1.45
	viewport.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-1.8, 1.4, 1.5)
	fill_light.light_color = Color("87b7e1")
	fill_light.light_energy = 0.7
	fill_light.omni_range = 7
	viewport.add_child(fill_light)
	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(1.5, 2.2, -1.0)
	rim_light.light_color = Color("e5b971")
	rim_light.light_energy = 1.0
	rim_light.omni_range = 6
	viewport.add_child(rim_light)
	preview = PreviewCharacter.new()
	viewport.add_child(preview)
	call_deferred("_populate_preview")

func _populate_preview() -> void:
	await get_tree().process_frame
	var preview_started := Time.get_ticks_usec()
	preview.set_profile(_preview_profile_with_equipped_gear())
	barrier_preview_materials=BodyBarrierOverlay.apply(preview.skeleton)
	await get_tree().process_frame
	preview_loading = false
	if is_instance_valid(preview_loading_overlay):preview_loading_overlay.hide()
	preview_status.text = "Select a body marker. Gear appears on the character when equipped."
	GameDiagnostics.log_timing("loadout_character_preview", preview_started, {"body":profile.get("body", "Masculine"), "parts":PARTS.size()})

func _select_part(part_id: String) -> void:
	selected_part = part_id
	var part := _part_data(part_id)
	if part.is_empty():
		return
	selected_label.text = str(part.name).to_upper()
	if preview_status!=null:preview_status.text="Gear appears on the character when selected."
	selected_gear_id=str(profile.get("story_part_gear",{}).get(part_id,""))
	selected_animation=""
	_refresh_inventory()
	_refresh_crystals()
	GameDiagnostics.log_event("loadout_part_selected", {"part":part_id,"gear":selected_gear_id})

func _refresh_inventory() -> void:
	if gear_grid==null:return
	for child in gear_grid.get_children():
		gear_grid.remove_child(child)
		child.queue_free()
	var matched:=0
	for item in _sort_by_rarity(inventory_gear):
		if str(item.get("part",""))!=selected_part:continue
		matched+=1
		gear_grid.add_child(_make_gear_card(item))
	gear_grid.add_child(_make_none_gear_card())
	if matched==0:
		gear_grid.add_child(_make_empty_inventory_tile("NO GEAR"))
	if not selected_gear_id.is_empty():
		_show_gear_detail(_gear_by_id(selected_gear_id))
	else:
		# An empty equipment slot must not keep showing the previously equipped
		# item's size and animation controls. Inventory cards remain available
		# above so another piece can still be equipped with one click.
		_show_gear_detail({})

func _make_empty_inventory_tile(label_text:String) -> Control:
	var tile:=PanelContainer.new()
	tile.custom_minimum_size=Vector2(76,76)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.16,0.19,0.23,0.25)
	style.set_border_width_all(1)
	style.border_color=Color(0.58,0.64,0.70,0.32)
	style.set_corner_radius_all(6)
	tile.add_theme_stylebox_override("panel",style)
	var label:=Label.new()
	label.text=label_text
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",10)
	label.add_theme_color_override("font_color",Color(0.75,0.81,0.87,0.52))
	tile.add_child(label)
	return tile

func _make_none_gear_card() -> Button:
	var card:=Button.new()
	card.custom_minimum_size=Vector2(76,76)
	card.text="×"
	card.tooltip_text="Empty this equipment slot"
	card.add_theme_font_size_override("font_size",30)
	card.add_theme_color_override("font_color",Color("655740"))
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("17202b")
	style.set_border_width_all(1)
	style.border_color=Color("5b6875")
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("normal",style)
	card.pressed.connect(_unequip_selected_part)
	return card

func _make_gear_card(item:Dictionary) -> Button:
	var card=DraggableItem.new()
	card.custom_minimum_size=Vector2(76,76)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.focus_mode=Control.FOCUS_NONE
	var gear_id:=str(item.get("id",""))
	card.set_meta("gear_id",gear_id)
	card.configure_drop_target("animation",gear_id)
	card.item_dropped.connect(_on_gear_card_drop)
	var animation_names:PackedStringArray=[]
	for animation in item.get("native_animations",[]):animation_names.append(_animation_label(str(animation)))
	var spell_names:PackedStringArray=[]
	for spell_id in _gear_spell_ids(item):spell_names.append(_spell_name(str(spell_id)))
	card.tooltip_text="%s\n%s animation slot%s\nAnimations: %s\nSpells: %s"%[item.get("name","Gear"),_pair_capacity(item),"" if _pair_capacity(item)==1 else "s",", ".join(animation_names) if not animation_names.is_empty() else "None",", ".join(spell_names) if not spell_names.is_empty() else "None"]
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172536")
	style.set_border_width_all(2)
	style.border_color=_rarity_color(item)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("normal",style)
	var hover:=style.duplicate() as StyleBoxFlat
	hover.bg_color=Color("22364b")
	card.add_theme_stylebox_override("hover",hover)
	var press:=style.duplicate() as StyleBoxFlat
	press.bg_color=Color("2c4359")
	card.add_theme_stylebox_override("pressed",press)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom=-12
	center.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(center)
	var icon=GearIcon.new()
	icon.custom_minimum_size=Vector2(50,50)
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	icon.configure(str(item.get("part","chest")),_gear_color(item),_rarity_color(item))
	center.add_child(icon)
	if str(profile.get("story_part_gear",{}).get(selected_part,""))==str(item.get("id","")):
		var equipped_mark:=Label.new()
		equipped_mark.text="✓"
		equipped_mark.add_theme_color_override("font_color",Color("71d9ad"))
		equipped_mark.add_theme_font_size_override("font_size",14)
		equipped_mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		equipped_mark.position=Vector2(-22,2)
		equipped_mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(equipped_mark)
	card.pressed.connect(_select_gear_card.bind(str(item.get("id",""))))
	return card

func _gear_equipped_animation_count(item:Dictionary) -> int:
	var count:=0
	var pairs:Array=item.get("animation_slots",[])
	if not pairs.is_empty():
		for pair in pairs:
			if pair is Dictionary and not str(pair.get("animation","")).is_empty():count+=1
		return count
	for animation in item.get("native_animations",[]):
		if not str(animation).is_empty():count+=1
	return count

func _gear_equipped_spell_count(item:Dictionary) -> int:
	var count:=0
	var pairs:Array=item.get("animation_slots",[])
	if not pairs.is_empty():
		for pair in pairs:
			if not (pair is Dictionary):continue
			count+=_pair_spell_ids(pair).size()
			count+=pair.get("spells",[]).size()
		return count
	var legacy_ids:Array=item.get("spell_ids",[])
	var legacy_spells:Array=item.get("spells",[])
	count+=legacy_ids.size()+legacy_spells.size()
	var links:Dictionary=item.get("crystal_links",{})
	for spell_id in links.values():
		if spell_id is Array:count+=spell_id.size()
		elif not str(spell_id).is_empty():count+=1
	return count

func _gear_spell_ids(item:Dictionary) -> Array[String]:
	var result:Array[String]=[]
	for pair in item.get("animation_slots",[]):
		if not pair is Dictionary:continue
		for spell_id in pair.get("spell_ids",[]):
			if not str(spell_id).is_empty() and not result.has(str(spell_id)):result.append(str(spell_id))
		var single:=str(pair.get("spell_id",""))
		if not single.is_empty() and not result.has(single):result.append(single)
	for spell_id in item.get("spell_ids",[]):
		if not str(spell_id).is_empty() and not result.has(str(spell_id)):result.append(str(spell_id))
	for spell in item.get("spells",[]):
		var value:=str(spell.get("spell",spell.get("name",""))) if spell is Dictionary else str(spell)
		if not value.is_empty() and not result.has(value):result.append(value)
	for value in item.get("crystal_links",{}).values():
		for spell_id in (value if value is Array else [value]):
			if not str(spell_id).is_empty() and not result.has(str(spell_id)):result.append(str(spell_id))
	return result

func _select_gear_card(item_id:String) -> void:
	selected_gear_id=item_id
	var item:=_gear_by_id(item_id)
	if item.is_empty():return
	selected_animation=""
	if str(profile.get("story_part_gear",{}).get(selected_part,""))!=item_id:
		_equip_selected_gear()
	else:
		_show_gear_detail(item)
	GameDiagnostics.log_event("inventory_gear_selected",{"part":selected_part,"item":item_id})

func _show_gear_detail(item:Dictionary) -> void:
	if gear_detail==null:return
	for child in gear_detail.get_children():
		gear_detail.remove_child(child)
		child.queue_free()
	if item.is_empty():return
	var heading:=Label.new()
	var slot_word:="ANIMATION SLOT" if _pair_capacity(item)==1 else "ANIMATION SLOTS"
	heading.text="%s  ·  %d %s"%[str(item.get("name","Gear")),_pair_capacity(item),slot_word]
	heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size",12)
	heading.add_theme_color_override("font_color",_rarity_color(item))
	gear_detail.add_child(heading)
	var size_key := _size_key_for_part(str(item.get("part", selected_part)))
	if not size_key.is_empty():
		var size_row := HBoxContainer.new()
		size_row.add_theme_constant_override("separation", 8)
		gear_detail.add_child(size_row)
		var appearance:Dictionary = item.get("appearance", {})
		var initial_size := float(appearance.get("gear_size", profile.get(size_key, 1.0)))
		var size_label := Label.new()
		size_label.text = "SIZE  %d%%" % roundi(initial_size * 100.0)
		size_label.custom_minimum_size.x = 76
		size_label.add_theme_font_size_override("font_size", 11)
		size_label.add_theme_color_override("font_color", Color("655740"))
		size_row.add_child(size_label)
		var size_slider := HSlider.new()
		size_slider.min_value = 0.85
		size_slider.max_value = 1.50
		size_slider.step = 0.01
		size_slider.value = initial_size
		size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_slider.custom_minimum_size.y = 22
		size_slider.tooltip_text = "Resize this gear piece"
		size_slider.value_changed.connect(_on_gear_size_changed.bind(str(item.get("id", "")), size_label))
		size_row.add_child(size_slider)
	animation_detail=VBoxContainer.new()
	animation_detail.add_theme_constant_override("separation",3)
	gear_detail.add_child(animation_detail)
	var pair_slots:Array=item.get("animation_slots",[])
	for slot_index in range(_pair_capacity(item)):
		var pair:Dictionary=pair_slots[slot_index] if slot_index<pair_slots.size() else {"animation":"","spell_id":"","input":"key_1"}
		var row:=HBoxContainer.new()
		row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation",4)
		animation_detail.add_child(row)
		var animation_id:=str(pair.get("animation",""))
		var animation_label:="＋ ANIMATION" if animation_id.is_empty() else "✦ "+_animation_name(animation_id)
		var animation_socket=DropSocket.new()
		animation_socket.configure("animation","animation:%s:%d"%[str(item.get("id","")),slot_index],animation_label,_rarity_color(item),Vector2(130,32),not animation_id.is_empty())
		animation_socket.tooltip_text="Drop a compatible animation here%s"%["" if animation_id.is_empty() else " · "+_animation_name(animation_id)]
		if not animation_id.is_empty():
			animation_socket.configure_drag({"kind":"animation","id":"animation_%s"%animation_id,"animation":animation_id,"name":_animation_name(animation_id),"source_gear_id":str(item.get("id","")),"source_slot_index":slot_index})
		animation_socket.item_dropped.connect(_on_loadout_socket_drop)
		if not animation_id.is_empty():
			animation_socket.gui_input.connect(_on_animation_socket_gui_input.bind(animation_id))
		row.add_child(animation_socket)
		var remove:=Button.new()
		remove.text="−"
		remove.custom_minimum_size=Vector2(30,32)
		remove.tooltip_text="Return this animation and its spell to inventory"
		remove.disabled=animation_id.is_empty()
		remove.pressed.connect(_remove_animation_from_gear.bind(str(item.get("id","")),slot_index))
		row.add_child(remove)
		var input_button:=Button.new()
		input_button.custom_minimum_size=Vector2(72,32)
		input_button.disabled=animation_id.is_empty()
		input_button.text=_input_name(str(pair.get("input",_default_input_for_animation(animation_id))))
		input_button.tooltip_text="Choose an input for this animation"
		input_button.pressed.connect(_open_hotkey_picker.bind(str(item.get("id","")),slot_index))
		row.add_child(input_button)
		var spells_row:=HFlowContainer.new()
		spells_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		spells_row.add_theme_constant_override("h_separation",4)
		spells_row.add_theme_constant_override("v_separation",3)
		animation_detail.add_child(spells_row)
		for spell_id in _pair_spell_ids(pair):
			var spell_chip:=HBoxContainer.new()
			spell_chip.add_theme_constant_override("separation",2)
			var spell_name:=Label.new()
			spell_name.text="◆ "+_spell_name(spell_id)
			spell_name.add_theme_font_size_override("font_size",11)
			spell_name.add_theme_color_override("font_color",_spell_color(spell_id))
			spell_name.tooltip_text=_spell_name(spell_id)
			spell_chip.add_child(spell_name)
			var remove_spell:=Button.new()
			remove_spell.text="−"
			remove_spell.custom_minimum_size=Vector2(24,24)
			remove_spell.tooltip_text="Return this spell to the spell inventory"
			remove_spell.pressed.connect(_remove_spell_from_animation.bind(str(item.get("id","")),slot_index,spell_id))
			spell_chip.add_child(remove_spell)
			spells_row.add_child(spell_chip)
		var spell_socket=DropSocket.new()
		spell_socket.configure("spell","spell:%s:%d"%[str(item.get("id","")),slot_index],"＋ SPELL",Color("91c5ff"),Vector2(96,28))
		spell_socket.tooltip_text="Drop another spell here to bind it to this animation"
		if animation_id.is_empty():
			spell_socket.mouse_filter=Control.MOUSE_FILTER_IGNORE
			spell_socket.modulate=Color(1.0,1.0,1.0,0.45)
		spell_socket.item_dropped.connect(_on_loadout_socket_drop)
		spells_row.add_child(spell_socket)
	_refresh_animations()

func _on_gear_size_changed(value:float, item_id:String, size_label:Label) -> void:
	if is_instance_valid(size_label):size_label.text = "SIZE  %d%%" % roundi(value * 100.0)
	var item := _gear_by_id(item_id)
	if item.is_empty():return
	var appearance:Dictionary = item.get("appearance", {}).duplicate(true)
	appearance["gear_size"] = value
	item["appearance"] = appearance
	for index in range(inventory_gear.size()):
		if str(inventory_gear[index].get("id", "")) == item_id:
			inventory_gear[index] = item
			break
	var item_part := str(item.get("part", selected_part))
	var part_data := _part_data(item_part)
	var equipped: Dictionary = profile.get("story_part_gear", {})
	if is_instance_valid(preview) and str(equipped.get(item_part, "")) == item_id and not part_data.is_empty():
		var side := "left" if item_part.begins_with("left_") else ("right" if item_part.begins_with("right_") else "")
		preview.set_wardrobe_size(str(part_data.get("gear_key", "")), value, side)
	if is_instance_valid(gear_size_update_timer):gear_size_update_timer.start()
	GameDiagnostics.log_event("loadout_gear_size_changed", {"gear":item_id, "size":value})

func _commit_gear_size_update() -> void:
	_save_profile_only()

func _on_loadout_socket_drop(payload:Dictionary,socket_id:String) -> void:
	var pieces:=socket_id.split(":")
	if pieces.size()!=3:return
	var gear_id:=str(pieces[1])
	var slot_index:=int(pieces[2])
	if str(payload.get("kind", ""))=="spell":
		_assign_spell_to_animation(str(payload.get("id","")),gear_id,slot_index)
	elif pieces[0]=="animation":
		if payload.has("source_gear_id"):
			_move_equipped_animation(payload,gear_id,slot_index)
		else:
			_assign_animation_to_gear(str(payload.get("animation","")),gear_id,slot_index)
	elif pieces[0]=="spell":
		_assign_spell_to_animation(str(payload.get("id","")),gear_id,slot_index)

func _on_gear_card_drop(payload:Dictionary,gear_id:String) -> void:
	if str(payload.get("kind", ""))!="animation":return
	var item:=_gear_by_id(gear_id)
	if item.is_empty():return
	var pair_slots:Array=item.get("animation_slots",[])
	for slot_index in range(pair_slots.size()):
		if pair_slots[slot_index] is Dictionary and str(pair_slots[slot_index].get("animation", "")).is_empty():
			if payload.has("source_gear_id"):
				_move_equipped_animation(payload,gear_id,slot_index)
			else:
				_assign_animation_to_gear(str(payload.get("animation", "")),gear_id,slot_index)
			return
	if is_instance_valid(animation_status):
		animation_status.text="No open animation slot on this gear."
	GameDiagnostics.log_event("loadout_animation_drop_rejected",{"gear":gear_id,"reason":"no_open_slot"})

func _move_equipped_animation(payload:Dictionary,target_gear_id:String,target_slot_index:int) -> void:
	var animation_id:=str(payload.get("animation",""))
	var source_gear_id:=str(payload.get("source_gear_id",""))
	var source_slot_index:=int(payload.get("source_slot_index",-1))
	if animation_id.is_empty() or source_gear_id.is_empty():return
	if source_gear_id==target_gear_id and source_slot_index==target_slot_index:return
	var source_item:=_gear_by_id(source_gear_id)
	var target_item:=_gear_by_id(target_gear_id)
	if source_item.is_empty() or target_item.is_empty():return
	if not _animation_compatible_with_part(animation_id,str(target_item.get("part",""))):
		animation_status.text="%s can’t be used on this gear slot."%_animation_name(animation_id)
		return
	var source_slots:Array=source_item.get("animation_slots",[])
	var target_slots:Array=target_item.get("animation_slots",[])
	if source_slot_index<0 or source_slot_index>=source_slots.size() or target_slot_index<0 or target_slot_index>=target_slots.size():return
	var source_pair:Dictionary=source_slots[source_slot_index]
	var target_pair:Dictionary=target_slots[target_slot_index]
	if str(source_pair.get("animation",""))!=animation_id or not str(target_pair.get("animation","")).is_empty():return
	for other_index in range(target_slots.size()):
		if other_index!=target_slot_index and str(target_slots[other_index].get("animation",""))==animation_id:
			animation_status.text="That animation is already on this gear."
			return
	target_slots[target_slot_index]=source_pair.duplicate(true)
	source_slots[source_slot_index]={"animation":"","spell_ids":[],"spell_id":"","input":"key_1"}
	source_item["animation_slots"]=source_slots
	target_item["animation_slots"]=target_slots
	_sync_gear_animation_cache(source_item)
	_sync_gear_animation_cache(target_item)
	selected_gear_id=target_gear_id
	selected_animation=animation_id
	_save_slots()
	var equipped:Dictionary=profile.get("story_part_gear",{})
	if str(equipped.get(str(source_item.get("part","")),""))==source_gear_id or str(equipped.get(str(target_item.get("part","")),""))==target_gear_id:
		_refresh_equipped_preview()
	_refresh_inventory()
	_refresh_crystals()
	_refresh_animations()
	_show_gear_detail(target_item)
	GameDiagnostics.log_event("loadout_animation_moved",{"animation":animation_id,"source_gear":source_gear_id,"source_slot":source_slot_index,"target_gear":target_gear_id,"target_slot":target_slot_index})

func _gear_pair_slot(item:Dictionary,index:int) -> Dictionary:
	var pair_slots:Array=item.get("animation_slots",[])
	if index<0 or index>=pair_slots.size():return {}
	return pair_slots[index]

func _assign_animation_to_gear(animation_id:String,gear_id:String,slot_index:int) -> void:
	var animation_item_id:="animation_%s"%animation_id
	var inventory_index:=-1
	for index in range(inventory_animations.size()):
		if str(inventory_animations[index].get("id",""))==animation_item_id:
			inventory_index=index
			break
	var item:=_gear_by_id(gear_id)
	if inventory_index<0 or item.is_empty():return
	if not _animation_compatible_with_part(animation_id,str(item.get("part",""))):
		animation_status.text="%s can’t be used on this gear slot."%_animation_name(animation_id)
		return
	var pair_slots:Array=item.get("animation_slots",[])
	if slot_index<0 or slot_index>=pair_slots.size():return
	for other_index in range(pair_slots.size()):
		if other_index!=slot_index and str(pair_slots[other_index].get("animation",""))==animation_id:
			animation_status.text="That animation is already on this gear."
			return
	var target:Dictionary=pair_slots[slot_index]
	if not str(target.get("animation","")).is_empty():
		animation_status.text="Remove the current animation first."
		return
	target["animation"]=animation_id
	target["input"]=_next_default_input()
	pair_slots[slot_index]=target
	item["animation_slots"]=pair_slots
	inventory_animations.remove_at(inventory_index)
	_sync_gear_animation_cache(item)
	selected_gear_id=gear_id
	selected_animation=animation_id
	_save_slots()
	_refresh_equipped_preview() if str(profile.get("story_part_gear",{}).get(selected_part,""))==gear_id else _save_profile_only()
	_refresh_inventory()
	_refresh_crystals()
	_refresh_animations()
	_show_gear_detail(item)
	GameDiagnostics.log_event("loadout_animation_equipped",{"gear":gear_id,"animation":animation_id,"slot":slot_index})

func _assign_spell_to_animation(spell_id:String,gear_id:String,slot_index:int) -> void:
	var spell_index:=-1
	for index in range(inventory_crystals.size()):
		if str(inventory_crystals[index].get("id",""))==spell_id:
			spell_index=index
			break
	var item:=_gear_by_id(gear_id)
	if spell_index<0 or item.is_empty():return
	var pair_slots:Array=item.get("animation_slots",[])
	if slot_index<0 or slot_index>=pair_slots.size():return
	var target:Dictionary=pair_slots[slot_index]
	if str(target.get("animation","")).is_empty():
		crystal_status.text="Add an animation to this slot before attaching a spell."
		return
	var attached_spells:=_pair_spell_ids(target)
	if attached_spells.has(spell_id):return
	attached_spells.append(spell_id)
	target["spell_ids"]=attached_spells
	target["spell_id"]=str(attached_spells[0])
	pair_slots[slot_index]=target
	item["animation_slots"]=pair_slots
	inventory_crystals.remove_at(spell_index)
	_sync_gear_animation_cache(item)
	selected_gear_id=gear_id
	selected_animation=str(target.get("animation",""))
	_save_profile_only()
	_refresh_inventory()
	_refresh_crystals()
	_refresh_animations()
	_show_gear_detail(item)
	crystal_status.text="%s linked to %s."%[_spell_name(spell_id),_animation_name(selected_animation)]
	GameDiagnostics.log_event("loadout_spell_equipped",{"gear":gear_id,"spell":spell_id,"animation":selected_animation,"slot":slot_index,"spell_count":attached_spells.size()})

func _remove_spell_from_animation(gear_id:String,slot_index:int,spell_id:String) -> void:
	var item:=_gear_by_id(gear_id)
	var pair_slots:Array=item.get("animation_slots",[]) if not item.is_empty() else []
	if slot_index<0 or slot_index>=pair_slots.size():return
	var pair:Dictionary=pair_slots[slot_index]
	var attached_spells:=_pair_spell_ids(pair)
	if not attached_spells.has(spell_id):return
	attached_spells.erase(spell_id)
	pair["spell_ids"]=attached_spells
	pair["spell_id"]=str(attached_spells[0]) if not attached_spells.is_empty() else ""
	pair_slots[slot_index]=pair
	item["animation_slots"]=pair_slots
	_add_spell_to_inventory(spell_id)
	_sync_gear_animation_cache(item)
	_save_profile_only()
	_refresh_inventory()
	_refresh_crystals()
	_refresh_animations()
	_show_gear_detail(item)
	GameDiagnostics.log_event("loadout_spell_removed",{"gear":gear_id,"spell":spell_id,"animation":pair.get("animation",""),"slot":slot_index})

func _remove_animation_from_gear(gear_id:String,slot_index:int) -> void:
	var item:=_gear_by_id(gear_id)
	var pair_slots:Array=item.get("animation_slots",[]) if not item.is_empty() else []
	if slot_index<0 or slot_index>=pair_slots.size():return
	var pair:Dictionary=pair_slots[slot_index]
	var animation_id:=str(pair.get("animation",""))
	var spell_ids:=_pair_spell_ids(pair)
	if animation_id.is_empty():return
	_add_animation_to_inventory(animation_id)
	for spell_id in spell_ids:_add_spell_to_inventory(spell_id)
	pair_slots[slot_index]={"animation":"","spell_ids":[],"spell_id":"","input":"key_1"}
	item["animation_slots"]=pair_slots
	_sync_gear_animation_cache(item)
	selected_animation=""
	_save_slots()
	_refresh_equipped_preview() if str(profile.get("story_part_gear",{}).get(selected_part,""))==gear_id else _save_profile_only()
	_refresh_inventory()
	_refresh_crystals()
	_refresh_animations()
	_show_gear_detail(item)
	GameDiagnostics.log_event("loadout_animation_removed",{"gear":gear_id,"animation":animation_id,"spells":spell_ids,"slot":slot_index})

func _sync_gear_animation_cache(item:Dictionary) -> void:
	var animations:Array=[]
	var links:Dictionary={}
	for pair in item.get("animation_slots",[]):
		var animation_id:=str(pair.get("animation",""))
		if animation_id.is_empty():continue
		animations.append(animation_id)
		var spell_ids:=_pair_spell_ids(pair)
		if not spell_ids.is_empty():links[animation_id]=spell_ids.duplicate()
	item["native_animations"]=animations
	item["crystal_links"]=links

func _input_name(input_id:String) -> String:
	if input_id.is_empty():return "Set command"
	var pieces:=input_id.split("+")
	var display:Array[String]=[]
	for piece in pieces:
		match piece:
			"shift":display.append("Shift")
			"ctrl":display.append("Ctrl")
			"alt":display.append("Alt")
			"mouse_left":display.append("Left click")
			"mouse_right":display.append("Right click")
			"mouse_both":display.append("Both clicks")
			"mouse_middle":display.append("Middle click")
			_:
				var key_name:=piece.trim_prefix("key_").replace("_"," ")
				display.append(key_name.to_upper())
	return "+".join(display)

func _default_assignment_input(animation_id:String,extra_used:Array=[]) -> String:
	var preferred:=_default_input_for_animation(animation_id)
	if preferred in ["mouse_left","mouse_right","mouse_both"] and not extra_used.has(preferred):
		var used:=false
		for item in inventory_gear:
			for pair in item.get("animation_slots",[]):
				if pair is Dictionary and not str(pair.get("animation","")).is_empty() and str(pair.get("input",""))==preferred:
					used=true
					break
			if used:break
		if not used:return preferred
	return _next_default_input(extra_used)

func _next_default_input(extra_used:Array=[]) -> String:
	var occupied:Dictionary={}
	for used in extra_used:occupied[str(used)]=true
	for item in inventory_gear:
		for pair in item.get("animation_slots",[]):
			if not pair is Dictionary or str(pair.get("animation","")).is_empty():continue
			var assigned:=str(pair.get("input",""))
			if not assigned.is_empty():occupied[assigned]=true
	for input_id in DEFAULT_INPUT_ORDER:
		if not occupied.has(input_id):return input_id
	return DEFAULT_INPUT_ORDER[randi_range(0,DEFAULT_INPUT_ORDER.size()-1)]

func _open_hotkey_picker(gear_id:String,slot_index:int) -> void:
	var item:=_gear_by_id(gear_id)
	var pair_slots:Array=item.get("animation_slots",[]) if not item.is_empty() else []
	if slot_index<0 or slot_index>=pair_slots.size():return
	var pair:Dictionary=pair_slots[slot_index]
	var dialog:=Window.new()
	dialog.title="Set command"
	dialog.exclusive=true
	dialog.transient=true
	dialog.unresizable=true
	dialog.min_size=Vector2i(400,220)
	dialog.size=Vector2i(400,220)
	add_child(dialog)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,20)
	dialog.add_child(margin)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	margin.add_child(content)
	var description:=Label.new()
	description.text=_animation_name(str(pair.get("animation","Animation")))
	description.add_theme_font_size_override("font_size",19)
	description.add_theme_color_override("font_color",Color("a9bfce"))
	content.add_child(description)
	var current:=Label.new()
	current.text="Current · "+_input_name(str(pair.get("input","")))
	current.add_theme_color_override("font_color",Color("e9c982"))
	content.add_child(current)
	var record:=Button.new()
	record.text="RECORD"
	record.custom_minimum_size.y=46
	var record_style:=StyleBoxFlat.new()
	record_style.bg_color=Color("725d3e")
	record_style.border_color=Color("c9a96a")
	record_style.set_border_width_all(1)
	record_style.set_corner_radius_all(5)
	record.add_theme_stylebox_override("normal",record_style)
	var record_hover:=record_style.duplicate() as StyleBoxFlat
	record_hover.bg_color=Color("8a7049")
	record.add_theme_stylebox_override("hover",record_hover)
	record.add_theme_color_override("font_color",Color("fff0cc"))
	record.add_theme_color_override("font_hover_color",Color.WHITE)
	content.add_child(record)
	var help:=Label.new()
	help.text="Esc cancels."
	help.add_theme_font_size_override("font_size",11)
	help.add_theme_color_override("font_color",Color("8093a5"))
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(help)
	var capture_state:Dictionary={"active":false}
	dialog.close_requested.connect(func():
		capture_state["active"]=false
		if active_hotkey_capture==capture_state:active_hotkey_capture={}
		dialog.queue_free()
	)
	var overlay:=Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.focus_mode=Control.FOCUS_ALL
	overlay.visible=false
	dialog.add_child(overlay)
	var shade:=ColorRect.new()
	shade.color=Color("0b111b",0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	var prompt:=Label.new()
	prompt.text="PRESS A KEY OR CLICK\nEsc cancels"
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	prompt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prompt.add_theme_font_size_override("font_size",20)
	prompt.add_theme_color_override("font_color",Color("e9c982"))
	prompt.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(prompt)
	overlay.gui_input.connect(_capture_hotkey_event.bind(gear_id,slot_index,dialog,capture_state,prompt))
	record.pressed.connect(func():
		capture_state["active"]=true
		capture_state["await_mouse_release"]=true
		capture_state["previous_mouse"]={MOUSE_BUTTON_LEFT:false,MOUSE_BUTTON_RIGHT:false}
		capture_state["gear_id"]=gear_id
		capture_state["slot_index"]=slot_index
		capture_state["dialog"]=dialog
		capture_state["prompt"]=prompt
		active_hotkey_capture=capture_state
		overlay.visible=true
		overlay.grab_focus()
	)
	dialog.popup_centered()
	GameDiagnostics.log_event("loadout_hotkey_picker_opened",{"gear":gear_id,"animation":pair.get("animation",""),"current_input":pair.get("input","")})

func _capture_hotkey_event(event:InputEvent,gear_id:String,slot_index:int,dialog:Window,capture_state:Dictionary,prompt:Label) -> void:
	if not bool(capture_state.get("active",false)):return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_name:=OS.get_keycode_string(event.keycode if event.keycode!=0 else event.physical_keycode).to_lower()
		if key_name in ["escape"]:
			capture_state["active"]=false
			active_hotkey_capture={}
			prompt.text="PRESS A KEY OR CLICK\nEsc cancels"
			get_viewport().set_input_as_handled()
			return
		var reason:=_hotkey_rejection_reason(key_name)
		if not reason.is_empty():
			prompt.text=reason+"\nTry another command."
			get_viewport().set_input_as_handled()
			return
		var binding:=_binding_modifiers(event)+"key_"+key_name.replace(" ","_")
		_commit_recorded_binding(gear_id,slot_index,binding,dialog,capture_state,prompt)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:
		var mouse_name:="mouse_left" if event.button_index==MOUSE_BUTTON_LEFT else ("mouse_right" if event.button_index==MOUSE_BUTTON_RIGHT else "mouse_middle")
		var binding:=_binding_modifiers(event)+mouse_name
		_commit_recorded_binding(gear_id,slot_index,binding,dialog,capture_state,prompt)
		get_viewport().set_input_as_handled()

func _poll_hotkey_mouse_capture() -> void:
	if active_hotkey_capture.is_empty() or not bool(active_hotkey_capture.get("active",false)):return
	var previous:Dictionary=active_hotkey_capture.get("previous_mouse",{})
	var pressed_any:=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if bool(active_hotkey_capture.get("await_mouse_release",false)):
		if not pressed_any:active_hotkey_capture["await_mouse_release"]=false
		previous[MOUSE_BUTTON_LEFT]=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		previous[MOUSE_BUTTON_RIGHT]=Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		return
	for button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
		var is_pressed:=Input.is_mouse_button_pressed(button_index)
		var was_pressed:=bool(previous.get(button_index,false))
		if is_pressed and not was_pressed:
			var mouse_name:="mouse_left" if button_index==MOUSE_BUTTON_LEFT else "mouse_right"
			var modifiers:=""
			if Input.is_key_pressed(KEY_CTRL):modifiers+="ctrl+"
			if Input.is_key_pressed(KEY_ALT):modifiers+="alt+"
			if Input.is_key_pressed(KEY_SHIFT):modifiers+="shift+"
			_commit_recorded_binding(str(active_hotkey_capture.get("gear_id","")),int(active_hotkey_capture.get("slot_index",-1)),modifiers+mouse_name,active_hotkey_capture.get("dialog"),active_hotkey_capture,active_hotkey_capture.get("prompt"))
			return
		previous[button_index]=is_pressed
	active_hotkey_capture["previous_mouse"]=previous

func _commit_recorded_binding(gear_id:String,slot_index:int,input_id:String,dialog:Window,capture_state:Dictionary,prompt:Label) -> void:
	if _animation_input_in_use(input_id,gear_id,slot_index):
		prompt.text="That command is already assigned. Press a different one.\nEsc cancels"
		return
	capture_state["active"]=false
	active_hotkey_capture={}
	_set_animation_input(gear_id,slot_index,input_id,dialog)

func _binding_modifiers(event:InputEventWithModifiers) -> String:
	var result:=""
	if event.ctrl_pressed:result+="ctrl+"
	if event.alt_pressed:result+="alt+"
	if event.shift_pressed:result+="shift+"
	return result

func _hotkey_rejection_reason(key_name:String) -> String:
	if key_name in ["w","a","s","d"]:return "WASD is reserved for movement."
	if key_name in ["escape","enter","kp enter","f"]:return "That key is reserved by the game."
	return ""

func _set_animation_input(gear_id:String,slot_index:int,input_id:String,dialog:Window) -> void:
	var item:=_gear_by_id(gear_id)
	var pair_slots:Array=item.get("animation_slots",[]) if not item.is_empty() else []
	if slot_index<0 or slot_index>=pair_slots.size():return
	if _animation_input_in_use(input_id,gear_id,slot_index):
		GameDiagnostics.log_event("loadout_animation_input_conflict",{"gear":gear_id,"input":input_id})
		return
	var pair:Dictionary=pair_slots[slot_index]
	pair["input"]=input_id
	pair_slots[slot_index]=pair
	item["animation_slots"]=pair_slots
	_save_profile_only()
	_show_gear_detail(item)
	GameDiagnostics.log_event("loadout_animation_input_changed",{"gear":gear_id,"animation":pair.get("animation",""),"input":input_id})
	dialog.queue_free()

func _animation_input_in_use(input_id:String,gear_id:String,slot_index:int) -> bool:
	var equipped:Dictionary=profile.get("story_part_gear",{})
	var checked:Dictionary={}
	for equipped_id in equipped.values():
		var item:=_gear_by_id(str(equipped_id))
		if item.is_empty() or checked.has(str(item.get("id",""))):continue
		checked[str(item.get("id",""))]=true
		for index in range(item.get("animation_slots",[]).size()):
			var pair:Dictionary=item["animation_slots"][index]
			if str(item.get("id",""))==gear_id and index==slot_index:continue
			if not str(pair.get("animation","")).is_empty() and str(pair.get("input",""))==input_id:return true
	return false

func _select_animation(animation_id:String) -> void:
	selected_animation=animation_id
	_show_gear_detail(_gear_by_id(selected_gear_id))
	animation_status.text="%s · click to preview"%_animation_name(animation_id)
	_preview_animation(animation_id)

func _equip_selected_gear() -> void:
	var item:=_gear_by_id(selected_gear_id)
	if item.is_empty():return
	var equipped:Dictionary=profile.get("story_part_gear",{})
	if str(equipped.get(selected_part,""))==selected_gear_id:
		return
	equipped[selected_part]=selected_gear_id
	profile["story_part_gear"]=equipped
	_sync_animation_bindings()
	_save_slots()
	_refresh_equipped_preview()
	_refresh_inventory()
	_show_gear_detail(_gear_by_id(selected_gear_id))
	GameDiagnostics.log_event("loadout_gear_equipped",{"part":selected_part,"item":equipped[selected_part]})

func _sync_animation_bindings() -> void:
	var equipped:Dictionary=profile.get("story_part_gear",{})
	for part_id in ["left_arm","right_arm","chest","left_leg","right_leg","left_boot","right_boot"]:
		var item:=_gear_by_id(str(equipped.get(part_id,"")))
		var selected_pair:Dictionary={}
		for pair in item.get("animation_slots",[]) if not item.is_empty() else []:
			var animation_id:=str(pair.get("animation",""))
			if not animation_id.is_empty() and _animation_compatible_with_part(animation_id,part_id):
				selected_pair=pair
				break
		if not slots.has(part_id):slots[part_id]={"ability":"","input":"key_1"}
		slots[part_id]["ability"]=str(selected_pair.get("animation",""))
		if not selected_pair.is_empty():slots[part_id]["input"]=str(selected_pair.get("input",_default_input_for_animation(str(selected_pair.get("animation","")))))
	_save_slots()

func _refresh_crystals() -> void:
	if crystal_grid==null:return
	for child in crystal_grid.get_children():
		crystal_grid.remove_child(child)
		child.queue_free()
	if inventory_crystals.is_empty():
		crystal_grid.add_child(_make_empty_inventory_tile("NO SPELLS"))
	for spell in _sort_by_rarity(inventory_crystals):
		var button=DraggableItem.new()
		button.custom_minimum_size=Vector2(56,56)
		button.tooltip_text="%s\n%s"%[spell.get("name","Spell"),spell.get("spell","unknown")]
		button.focus_mode=Control.FOCUS_NONE
		var crystal_style:=StyleBoxFlat.new()
		crystal_style.bg_color=Color("172536")
		crystal_style.set_border_width_all(2)
		crystal_style.border_color=spell.get("color",Color("9ecbff"))
		crystal_style.set_corner_radius_all(6)
		button.add_theme_stylebox_override("normal",crystal_style)
		var crystal_center:=CenterContainer.new()
		crystal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		crystal_center.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(crystal_center)
		var crystal_icon=GearIcon.new()
		crystal_icon.custom_minimum_size=Vector2(46,46)
		crystal_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		crystal_icon.configure("crystal",spell.get("color",Color.WHITE),spell.get("color",Color.WHITE),str(spell.get("element","magic")))
		crystal_center.add_child(crystal_icon)
		button.set_payload({"kind":"spell","id":str(spell.get("id","")),"name":str(spell.get("name","Spell"))})
		button.pressed.connect(_select_crystal.bind(str(spell.get("id",""))))
		crystal_grid.add_child(button)
func _refresh_animations() -> void:
	if animation_grid==null:return
	for child in animation_grid.get_children():
		animation_grid.remove_child(child)
		child.queue_free()
	var matched:=0
	for animation in _sort_by_rarity(inventory_animations):
		var animation_id:=str(animation.get("animation",""))
		if not _animation_compatible_with_part(animation_id,selected_part):continue
		matched+=1
		var button=DraggableItem.new()
		button.custom_minimum_size=Vector2(56,56)
		button.tooltip_text="%s · %s animation"%[_animation_name(animation_id),_animation_body_type(animation_id).to_upper()]
		button.focus_mode=Control.FOCUS_NONE
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("172536")
		style.set_border_width_all(2)
		style.border_color=Color("c5a8ff")
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override("normal",style)
		var center:=CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(center)
		var icon=GearIcon.new()
		icon.custom_minimum_size=Vector2(46,46)
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		icon.configure("animation",Color("b8a1df"),Color("c5a8ff"),"",animation_id)
		center.add_child(icon)
		button.set_payload({"kind":"animation","id":str(animation.get("id","")),"animation":animation_id,"name":_animation_name(animation_id)})
		button.pressed.connect(_select_animation_inventory.bind(animation_id))
		animation_grid.add_child(button)
	if matched==0:
		animation_grid.add_child(_make_empty_inventory_tile("NO ANIMATIONS"))

func _select_animation_inventory(animation_id:String) -> void:
	selected_animation=animation_id
	animation_status.text="Previewing %s"%_animation_name(animation_id)
	_preview_animation(animation_id)
	GameDiagnostics.log_event("inventory_animation_selected",{"animation":animation_id,"part":selected_part})

func _on_animation_socket_gui_input(event:InputEvent,animation_id:String) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		selected_animation=animation_id
		animation_status.text="Previewing %s"%_animation_name(animation_id)
		_preview_animation(animation_id)
		GameDiagnostics.log_event("equipped_animation_selected",{"animation":animation_id,"part":selected_part,"gear":selected_gear_id})
		get_viewport().set_input_as_handled()

func _preview_animation(animation_id:String) -> void:
	if is_instance_valid(preview) and preview.has_method("play_preview_animation"):
		var played:bool=preview.play_preview_animation(animation_id)
		preview_status.text="Previewing %s"%_animation_name(animation_id) if played else "%s preview unavailable"%_animation_name(animation_id)
		GameDiagnostics.log_event("loadout_animation_preview",{"animation":animation_id,"played":played})

func _select_crystal(crystal_id:String) -> void:
	selected_crystal_id=crystal_id
	var spell:=_spell_by_id(crystal_id)
	crystal_status.text="%s selected · drag onto an animation socket"%spell.get("spell",spell.get("name","Spell"))
	_preview_spell(spell)
	if Input.is_key_pressed(KEY_SHIFT):_link_selected_crystal()
	GameDiagnostics.log_event("inventory_spell_selected",{"spell":crystal_id,"animation":selected_animation})

func _preview_spell(spell:Dictionary) -> void:
	if not is_instance_valid(preview) or not is_instance_valid(viewport):return
	if is_instance_valid(preview_spell_node):preview_spell_node.queue_free()
	var name := str(spell.get("spell",spell.get("name","Fireball"))).to_lower()
	preview_spell_is_barrier=name.contains("barrier") or str(spell.get("effect","")).to_lower()=="barrier"
	BodyBarrierOverlay.set_strength(barrier_preview_materials,0.0)
	preview_spell_age=0.0
	if preview_spell_is_barrier:
		BodyBarrierOverlay.set_strength(barrier_preview_materials,1.0)
		preview_status.text="Previewing Barrier · a close body-fitted shell"
		GameDiagnostics.log_event("loadout_spell_preview",{"spell":spell.get("id",""),"appearance":"body_surface_barrier"})
		return
	preview_spell_base_scale=Vector3.ONE
	var cast_clip := "palm_fireball"
	if name.contains("ice"):cast_clip="ice_shard"
	elif name.contains("lightning"):cast_clip="lightning_arc"
	elif name.contains("wind"):cast_clip="wind_burst"
	elif name.contains("water"):cast_clip="water_orb"
	var cast_played:bool=false if preview_spell_is_barrier else preview.play_preview_animation("spells/"+cast_clip)
	var hand_name := "hand_l" if selected_animation=="punch_left" else "hand_r"
	var launch: Vector3 = Vector3(0,0.91,0) if preview_spell_is_barrier else preview.preview_bone_position(hand_name)+Vector3(0,0.04,0.18)
	var color:Color=spell.get("color",Color("ff774c"))
	var mesh:Mesh
	if preview_spell_is_barrier:
		var capsule:=CapsuleMesh.new();capsule.radius=0.49;capsule.height=1.82;capsule.radial_segments=18;capsule.rings=8;mesh=capsule
	elif name.contains("lightning"):
		var capsule:=CapsuleMesh.new();capsule.radius=0.045;capsule.height=0.62;mesh=capsule
	elif name.contains("wind"):
		var torus:=TorusMesh.new();torus.inner_radius=0.10;torus.outer_radius=0.20;mesh=torus
	elif name.contains("ice"):
		var prism:=PrismMesh.new();prism.size=Vector3(0.28,0.34,0.45);mesh=prism
	else:
		var orb:=SphereMesh.new();orb.radius=0.19;orb.height=0.38;orb.radial_segments=16;orb.rings=8;mesh=orb
	preview_spell_node=MeshInstance3D.new()
	preview_spell_node.name="LoadoutSpellPreview"
	preview_spell_node.mesh=mesh
	preview_spell_node.position=launch
	if preview_spell_is_barrier:
		preview_spell_base_scale=Vector3(0.72,0.91,0.56)*float(profile.get("height",1.0))
		preview_spell_node.scale=preview_spell_base_scale
	preview_spell_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color(color.r,color.g,color.b,0.11 if preview_spell_is_barrier else 0.94)
	material.emission_enabled=true
	material.emission=color
	material.emission_energy_multiplier=0.72 if preview_spell_is_barrier else 1.7
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode=BaseMaterial3D.CULL_DISABLED if preview_spell_is_barrier else BaseMaterial3D.CULL_BACK
	preview_spell_node.material_override=material
	viewport.add_child(preview_spell_node)
	preview_spell_age=0.0
	preview_status.text="Previewing %s%s"%[spell.get("name",spell.get("spell","Spell"))," · cast pose unavailable" if not cast_played else ""]
	GameDiagnostics.log_event("loadout_spell_preview",{"spell":spell.get("id",""),"cast_animation":cast_clip,"cast_played":cast_played})

func _link_selected_crystal() -> void:
	var item:=_gear_by_id(selected_gear_id)
	if item.is_empty() or selected_crystal_id.is_empty() or selected_animation.is_empty():
		crystal_status.text="Select a gear animation, then choose a spell."
		return
	var pair_slots:Array=item.get("animation_slots",[])
	for index in range(pair_slots.size()):
		if str(pair_slots[index].get("animation",""))==selected_animation:
			_assign_spell_to_animation(selected_crystal_id,selected_gear_id,index)
			return
	crystal_status.text="That animation is not on this gear."

func _crystal_by_id(crystal_id:String) -> Dictionary:
	for crystal in inventory_crystals:
		if str(crystal.get("id",""))==crystal_id:return crystal
	return {}

func _crystal_name(crystal_id:String) -> String:
	return _spell_name(crystal_id)

func _spell_by_id(spell_id:String) -> Dictionary:
	for spell in inventory_crystals:
		if str(spell.get("id",""))==spell_id:return spell
	for spell in profile.get("spell_catalog",[]):
		if spell is Dictionary and str(spell.get("id",""))==spell_id:return spell
	return {}

func _spell_name(spell_id:String) -> String:
	var spell:=_spell_by_id(spell_id)
	return str(spell.get("name",spell.get("spell","Spell")))

func _spell_color(spell_id:String) -> Color:
	return _spell_by_id(spell_id).get("color",Color("91c5ff"))

func _animation_label(animation_id:String) -> String:
	return _animation_name(animation_id)

func _sort_by_rarity(items:Array) -> Array:
	var sorted:Array=items.duplicate()
	sorted.sort_custom(func(a:Dictionary,b:Dictionary) -> bool:
		var rarity_a:=clampi(int(a.get("rarity",1)),1,6)
		var rarity_b:=clampi(int(b.get("rarity",1)),1,6)
		if rarity_a==rarity_b:return str(a.get("name","")).to_lower()<str(b.get("name","")).to_lower()
		return rarity_a>rarity_b
	)
	return sorted

func _pair_capacity(item:Dictionary) -> int:
	return clampi(int(item.get("rarity",1)),1,6)

func _rarity_name(item:Dictionary) -> String:
	return RARITY_NAMES[_pair_capacity(item)-1]

func _rarity_color(item:Dictionary) -> Color:
	return Color(RARITY_COLORS[_pair_capacity(item)-1])

func _gear_color(item:Dictionary) -> Color:
	var appearance:Dictionary=item.get("appearance",{})
	for key in ["shirt_color","gloves_color","handwear_color","bottoms_color","footwear_color","hat_color","mask_color","belt_color","back_color"]:
		if typeof(appearance.get(key))==TYPE_COLOR:return appearance[key]
	return Color("526b82")

func _unequip_selected_part() -> void:
	var equipped:Dictionary=profile.get("story_part_gear",{})
	equipped[selected_part]=""
	profile["story_part_gear"]=equipped
	selected_gear_id=""
	selected_animation=""
	_sync_animation_bindings()
	_save_slots()
	_refresh_equipped_preview()
	_refresh_inventory()
	_refresh_crystals()
	GameDiagnostics.log_event("loadout_gear_unequipped",{"part":selected_part})

## Script-facing Loadout action. Uses the same inventory, persistence, and
## preview-refresh path as selecting or removing gear in the visible UI.
func bot_set_gear(part_id: String, item_id: String) -> Dictionary:
	if _part_data(part_id).is_empty():
		return {"ok":false,"error":"Unknown body slot: %s" % part_id}
	if not item_id.is_empty() and _gear_by_id(item_id).is_empty():
		return {"ok":false,"error":"Gear %s is not in this character's inventory." % item_id}
	selected_part = part_id
	var equipped: Dictionary = profile.get("story_part_gear", {})
	equipped[part_id] = item_id
	profile["story_part_gear"] = equipped
	selected_gear_id = item_id
	selected_animation = ""
	_sync_animation_bindings()
	_save_profile_only()
	_save_bot_profile_to_roster()
	if selected_label != null:
		selected_label.text = str(_part_data(part_id).get("name", part_id)).to_upper()
	_refresh_equipped_preview()
	_refresh_inventory()
	_refresh_crystals()
	GameDiagnostics.log_event("bot_gear_changed", {"part":part_id,"item":item_id,"equipped":not item_id.is_empty()})
	return {"ok":true,"part":part_id,"item":item_id,"equipped":not item_id.is_empty()}

func _save_bot_profile_to_roster() -> void:
	var roster := ConfigFile.new()
	if roster.load("user://story_characters.cfg") != OK:
		return
	var characters: Array = roster.get_value("roster", "characters", [])
	var character_id := str(profile.get("character_id", ""))
	for index in range(characters.size()):
		if characters[index] is Dictionary and str(characters[index].get("character_id", "")) == character_id:
			characters[index] = profile.duplicate(true)
			break
	roster.set_value("roster", "characters", characters)
	roster.save("user://story_characters.cfg")

func _build_part_hotspots() -> void:
	for part in PARTS:
		var id:=str(part.id)
		var button:=Button.new()
		button.name="PartMarker_%s"%id
		button.text="●"
		button.custom_minimum_size=Vector2(34,34)
		button.size=Vector2(34,34)
		button.focus_mode=Control.FOCUS_NONE
		button.tooltip_text=str(part.name)
		button.pressed.connect(_select_part.bind(id))
		var style:=StyleBoxFlat.new()
		style.bg_color=Color(0.04,0.07,0.11,0.80)
		style.set_corner_radius_all(20)
		style.set_border_width_all(2)
		style.border_color=Color("9fb8ca")
		button.add_theme_stylebox_override("normal",style)
		var hover:=style.duplicate() as StyleBoxFlat
		hover.bg_color=Color(0.17,0.26,0.36,0.95)
		hover.border_color=Color("f0cf62")
		button.add_theme_stylebox_override("hover",hover)
		button.add_theme_color_override("font_color",Color("c9d7e2"))
		button.add_theme_color_override("font_hover_color",Color("ffe08a"))
		add_child(button)
		part_hotspots[id]=button
		var label_panel := PanelContainer.new()
		label_panel.name = "PartLabel_%s" % id
		label_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label_style := StyleBoxFlat.new()
		label_style.bg_color = Color(0.04, 0.07, 0.11, 0.88)
		label_style.set_corner_radius_all(5)
		label_style.set_border_width_all(1)
		label_style.border_color = Color("9fb8ca")
		label_style.content_margin_left = 6
		label_style.content_margin_right = 6
		label_style.content_margin_top = 2
		label_style.content_margin_bottom = 2
		label_panel.add_theme_stylebox_override("panel", label_style)
		var part_label := Label.new()
		part_label.text = str(part.name)
		part_label.add_theme_font_size_override("font_size", 13)
		part_label.add_theme_color_override("font_color", Color("f4ead5"))
		label_panel.add_child(part_label)
		add_child(label_panel)
		part_labels[id] = label_panel
	_update_part_hotspots()

func _update_part_hotspots() -> void:
	if not is_instance_valid(preview) or not is_instance_valid(preview_camera) or not is_instance_valid(preview_container):return
	var looking_at_back:=preview.to_local(preview_camera.global_position).z<0.0
	var root_origin:=get_global_transform_with_canvas().origin
	var preview_rect:=preview_container.get_global_rect()
	for part in PARTS:
		var id:=str(part.id)
		var button:Button=part_hotspots.get(id)
		var label_panel:PanelContainer=part_labels.get(id)
		if not is_instance_valid(button):continue
		if id=="back" and not looking_at_back or id=="face" and looking_at_back:
			button.visible=false
			if is_instance_valid(label_panel):label_panel.visible=false
			continue
		var center_world:Vector3=preview.to_global(part.position)
		if preview_camera.is_position_behind(center_world):
			button.visible=false
			if is_instance_valid(label_panel):label_panel.visible=false
			continue
		var point:=preview_rect.position+preview_camera.unproject_position(center_world)*(preview_rect.size/Vector2(viewport.size))
		# Offset paired hotspots away from the silhouette so the markers and their
		# labels have room without making them hard to associate with the body part.
		match id:
			"left_arm": point += Vector2(26.0, -3.0)
			"right_arm": point += Vector2(-26.0, -3.0)
			"left_hand": point += Vector2(34.0, 0.0)
			"right_hand": point += Vector2(-34.0, 0.0)
			"left_leg": point += Vector2(24.0, 0.0)
			"right_leg": point += Vector2(-24.0, 0.0)
			"left_boot": point += Vector2(28.0, 4.0)
			"right_boot": point += Vector2(-28.0, 4.0)
			"head": point += Vector2(-8.0, -8.0)
			"face": point += Vector2(8.0, 2.0)
			"chest": point += Vector2(0.0, -12.0)
			"belt": point += Vector2(0.0, 12.0)
		button.position=point-root_origin-button.size*0.5
		button.visible=preview_rect.has_point(point)
		if is_instance_valid(label_panel):
			label_panel.visible=button.visible
			if button.visible:
				var label_size := label_panel.get_combined_minimum_size()
				label_panel.size = label_size
				# Anatomical left appears on screen-right in this front-facing preview.
				var is_paired_side := id in ["left_arm", "right_arm", "left_hand", "right_hand", "left_leg", "right_leg", "left_boot", "right_boot"]
				var place_right := id.begins_with("left_") if is_paired_side else true
				var label_x := point.x + button.size.x * 0.5 + 6.0 if place_right else point.x - button.size.x * 0.5 - label_size.x - 6.0
				label_x = clampf(label_x, preview_rect.position.x + 4.0, preview_rect.end.x - label_size.x - 4.0)
				label_panel.position = Vector2(label_x, point.y - label_size.y * 0.5) - root_origin
		var style:=button.get_theme_stylebox("normal") as StyleBoxFlat
		if style!=null:
			style.border_color=Color("f0cf62") if id==selected_part else Color("9fb8ca")
		if is_instance_valid(label_panel):
			var label_style := label_panel.get_theme_stylebox("panel") as StyleBoxFlat
			if label_style != null:
				label_style.border_color = Color("f0cf62") if id == selected_part else Color("9fb8ca")

func _select_metadata(choice: OptionButton, value: String) -> void:
	for index in choice.item_count:
		if str(choice.get_item_metadata(index)) == value:
			choice.select(index)
			return
	choice.select(0)

func _on_ability_selected(index: int) -> void:
	var slot: Dictionary = slots[selected_part]
	var requested := str(ability_choice.get_item_metadata(index))
	var unlocked: Array = profile.get("combat_abilities", [])
	if requested in ["front_kick", "dash"] and not unlocked.has(requested):
		_select_metadata(ability_choice, str(slot.get("ability", "")))
		return
	slot["ability"] = requested
	_save_slots()
	GameDiagnostics.log_event("loadout_ability_changed", {"part":selected_part, "ability":slot.ability})

func _on_gear_selected(index: int) -> void:
	var item_id := str(gear_choice.get_item_metadata(index))
	var part_gear: Dictionary = profile.get("story_part_gear", {})
	part_gear[selected_part] = item_id
	profile["story_part_gear"] = part_gear
	if item_id != "current":
		for item in profile.get("story_loot", []):
			if item is Dictionary and str(item.get("id", item.get("name", "gear"))) == item_id and item.has("ability"):
				slots[selected_part]["ability"] = str(item.ability)
				break
	_save_slots()
	_select_part(selected_part)
	_refresh_equipped_preview()
	GameDiagnostics.log_event("loadout_gear_equipped", {"part":selected_part, "gear_id":item_id})

func _equipped_item_name(part_id:String) -> String:
	var part_gear:Dictionary=profile.get("story_part_gear",{})
	var item_id:=str(part_gear.get(part_id,"current"))
	var gear_item:=_gear_by_id(item_id)
	if not gear_item.is_empty():return str(gear_item.get("name","Gear"))
	if item_id.is_empty():return "None"
	if item_id=="current":
		var part:=_part_data(part_id)
		return str(profile.get(str(part.get("gear_key","")),"None"))
	for item in profile.get("story_loot",[]):
		if item is Dictionary and str(item.get("id",item.get("name","gear")))==item_id:
			return str(item.get("name","Gear"))
	return "Unknown gear"

func _preview_profile_with_equipped_gear() -> Dictionary:
	var result:=profile.duplicate(true)
	var part_gear:Dictionary=result.get("story_part_gear",{})
	var unequipped_parts:Dictionary={}
	for part_id in ["left_arm", "right_arm", "left_leg", "right_leg", "left_boot", "right_boot"]:
		if part_gear.has(part_id):
			unequipped_parts[part_id] = str(part_gear.get(part_id, "")).is_empty()
	result["story_unequipped_parts"] = unequipped_parts
	for gear_key in ["wardrobe_shirt","wardrobe_pants","wardrobe_arms","wardrobe_hands","wardrobe_boots","wardrobe_hat","wardrobe_mask","wardrobe_belt","wardrobe_back"]:
		var related_parts:Array=[]
		for part in PARTS:
			if str(part.get("gear_key",""))==gear_key:related_parts.append(str(part.id))
		var has_explicit_slot:=false
		var has_equipped_item:=false
		for part_id in related_parts:
			if not part_gear.has(part_id):continue
			has_explicit_slot=true
			if not str(part_gear.get(part_id,"" )).is_empty():has_equipped_item=true
		if has_explicit_slot and not has_equipped_item:result[gear_key]="None"
	for part_id in part_gear:
		var item_id:=str(part_gear[part_id])
		if item_id.is_empty():continue
		var item:=_gear_by_id(item_id)
		if item.is_empty():continue
		var appearance:Dictionary=item.get("appearance",{})
		for appearance_key in appearance:
			result[appearance_key]=appearance[appearance_key]
		var size_key := _size_key_for_part(str(item.get("part", part_id)))
		if not size_key.is_empty() and appearance.has("gear_size"):
			result[size_key] = float(appearance.get("gear_size", result.get(size_key, 1.0)))
	# Arm wardrobe meshes include shoulder caps that are designed to meet the
	# chest garment. Keep the arm gear in the loadout, but hide its rendered mesh
	# while the chest is bare so those caps do not float over the exposed torso.
	if str(part_gear.get("chest", "current")) == "":
		result["wardrobe_arms"] = "None"
	return result

func _clothing_variant(item_name:String) -> String:
	if item_name.contains("bare") or item_name.contains("none"):return "Bare"
	if item_name.contains("traveler") or item_name.contains("dash boots") or item_name.contains("greaves"):return "Traveler"
	if item_name.contains("guard") or item_name.contains("reinforced"):return "Guard castoff"
	return "Peasant"

func _refresh_equipped_preview() -> void:
	if preview==null:return
	preview_refresh_generation += 1
	call_deferred("_refresh_equipped_preview_deferred",preview_refresh_generation)

func _refresh_equipped_preview_deferred(generation:int) -> void:
	preview_loading = true
	if is_instance_valid(preview_loading_overlay):preview_loading_overlay.show()
	if preview_status!=null:preview_status.text="Loading character…"
	await get_tree().process_frame
	if generation!=preview_refresh_generation or not is_instance_valid(preview):return
	var refresh_started:=Time.get_ticks_usec()
	preview.set_profile(_preview_profile_with_equipped_gear())
	barrier_preview_materials=BodyBarrierOverlay.apply(preview.skeleton)
	await get_tree().process_frame
	if generation!=preview_refresh_generation:return
	preview_loading=false
	if is_instance_valid(preview_loading_overlay):preview_loading_overlay.hide()
	if preview_status!=null:preview_status.text="Gear appears on the character when selected."
	_update_part_hotspots()
	GameDiagnostics.log_timing("loadout_equipped_gear_preview",refresh_started,{"part":selected_part,"gear":_equipped_item_name(selected_part)})

func _on_input_selected(index: int) -> void:
	var slot: Dictionary = slots[selected_part]
	slot["input"] = str(input_choice.get_item_metadata(index))
	_save_slots()
	GameDiagnostics.log_event("loadout_hotkey_changed", {"part":selected_part, "input":slot.input})

func _save_slots() -> void:
	profile["gear_slots"] = slots.duplicate(true)
	var equipped_ids: Array = []
	for item_id in profile.get("story_part_gear", {}).values():
		if not str(item_id).is_empty() and str(item_id) != "current" and not equipped_ids.has(str(item_id)):
			equipped_ids.append(str(item_id))
	profile["story_equipped_items"] = equipped_ids
	var abilities: Array[String] = []
	for item_id in profile.get("story_part_gear",{}).values():
		var item:=_gear_by_id(str(item_id))
		if item.is_empty():continue
		for animation in item.get("native_animations",[]):
			if str(animation) in ["front_kick","dash"] and not abilities.has(str(animation)):abilities.append(str(animation))
	for item in profile.get("story_loot", []):
		if item is Dictionary and equipped_ids.has(str(item.get("id", item.get("name", "gear")))) and item.has("ability"):
			var ability := str(item.ability)
			if not abilities.has(ability):
				abilities.append(ability)
	profile["combat_abilities"] = abilities
	profile["gear_inventory"]=inventory_gear.duplicate(true)
	profile["crystal_inventory"]=inventory_crystals.duplicate(true)
	profile["spell_inventory"]=inventory_crystals.duplicate(true)
	profile["animation_inventory"]=inventory_animations.duplicate(true)
	var config := ConfigFile.new()
	config.set_value("character", "profile", profile)
	if config.save(CHARACTER_PATH) != OK:
		return
	var roster := ConfigFile.new()
	if roster.load("user://story_characters.cfg") == OK:
		var characters: Array = roster.get_value("roster", "characters", [])
		for index in range(characters.size()):
			if characters[index] is Dictionary and str(characters[index].get("character_id", "")) == str(profile.get("character_id", "")):
				characters[index] = profile
				break
		roster.set_value("roster", "characters", characters)
		roster.save("user://story_characters.cfg")

func _part_data(part_id: String) -> Dictionary:
	for part in PARTS:
		if str(part.id) == part_id:
			return part
	return {}

func _on_preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			preview_camera.position.z=clampf(preview_camera.position.z+(-0.25 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 0.25),2.8,6.0)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			dragging_preview = event.pressed
			last_pointer = event.position
			if event.pressed:
				var picked := _pick_part(event.position)
				if not picked.is_empty():
					_select_part(picked)
	elif event is InputEventMouseMotion and dragging_preview:
		preview.rotation.y += (event.position.x - last_pointer.x) * 0.01
		last_pointer = event.position

func _pick_part(pointer: Vector2) -> String:
	var viewport_point := pointer * Vector2(viewport.size) / preview_container.size
	var looking_at_back := preview.to_local(preview_camera.global_position).z < 0.0
	var best_part := ""
	var best_score := INF
	for part in PARTS:
		if part.id == "back" and not looking_at_back:
			continue
		if part.id == "face" and looking_at_back:
			continue
		var center_world: Vector3 = preview.to_global(part.position)
		if preview_camera.is_position_behind(center_world):
			continue
		var center := preview_camera.unproject_position(center_world)
		var radius_x := preview_camera.unproject_position(preview.to_global(part.position + Vector3(part.radius.x, 0, 0))).distance_to(center)
		var radius_y := preview_camera.unproject_position(preview.to_global(part.position + Vector3(0, part.radius.y, 0))).distance_to(center)
		var nx := absf(viewport_point.x - center.x) / maxf(radius_x + 8.0, 1.0)
		var ny := absf(viewport_point.y - center.y) / maxf(radius_y + 8.0, 1.0)
		var score := nx * nx + ny * ny
		if maxf(nx, ny) <= 1.0 and score < best_score:
			best_score = score
			best_part = str(part.id)
	return best_part

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and not get_viewport().gui_get_focus_owner() is LineEdit:
		if event.keycode in [KEY_BRACKETLEFT,KEY_BRACKETRIGHT]:
			var selected := 0
			for index in PARTS.size():
				if str(PARTS[index].id)==selected_part:selected=index;break
			_select_part(str(PARTS[posmod(selected+(-1 if event.keycode==KEY_BRACKETLEFT else 1),PARTS.size())].id))
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_A,KEY_D] and preview!=null:
			preview.rotation.y+=(-1 if event.keycode==KEY_A else 1)*PI/8
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_MINUS,KEY_EQUAL,KEY_KP_ADD,KEY_KP_SUBTRACT] and preview_camera!=null:
			preview_camera.position.z=clampf(preview_camera.position.z+(-0.25 if event.keycode in [KEY_EQUAL,KEY_KP_ADD] else 0.25),2.8,6.0)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		var viewport := get_viewport()
		get_tree().change_scene_to_file("res://scenes/story_opponents.tscn")
		if viewport != null:
			viewport.set_input_as_handled()
