extends Control
## Keep the creator visible as a lightweight transition while arena resources load.

const FIGHT_SCENE := "res://scenes/fight.tscn"
const LOAD_PATHS := [
	"res://assets/characters/base/Superhero_Male_FullBody.gltf",
	"res://assets/characters/base/Superhero_Female_FullBody.gltf",
	"res://assets/combat/animations/UAL1_Standard.glb",
	"res://assets/combat/animations/UAL2_Standard.glb",
	"res://assets/combat/animations/fight_anims.res",
	"res://assets/combat/animations/boxing.res",
	"res://assets/combat/animations/duel.res",
	"res://assets/combat/animations/spells.res",
	"res://assets/combat/animations/battle.res",
	"res://assets/combat/animations/editor_attacks.res",
]

var elapsed := 0.0
var progress_bar: ProgressBar
var fight_scene: PackedScene
var loaded_paths := {}
var load_paths: Array[String] = []
var load_started_usec := 0
var asset_started_usec: Dictionary = {}
var last_progress_log := 0.0

func _ready() -> void:
	load_started_usec = Time.get_ticks_usec()
	_build_screen()
	for path in LOAD_PATHS:
		_queue_load(path)
	_queue_profile_assets()
	for path in load_paths:
		asset_started_usec[path] = Time.get_ticks_usec()
		var result := ResourceLoader.load_threaded_request(path)
		if result != OK:
			loaded_paths[path] = true
			GameDiagnostics.log_event("asset_load_request_failed", {"path":path, "error":result})
	# Parse the fight scene on the main thread. Threaded scene parsing can fail
	# while resolving shaders from script preloads, even though those shaders
	# load normally on their own.
	await get_tree().process_frame
	var scene_started_usec := Time.get_ticks_usec()
	fight_scene = load(FIGHT_SCENE) as PackedScene
	GameDiagnostics.log_timing("fight_scene_resource_load", scene_started_usec, {"loaded":fight_scene != null})

func _process(delta: float) -> void:
	elapsed += delta
	var total_progress := 0.0
	var completed := 0
	for path in load_paths:
		if loaded_paths.get(path, false):
			total_progress += 1.0
			completed += 1
			continue
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path)
			loaded_paths[path] = true
			GameDiagnostics.log_timing("asset_load", int(asset_started_usec.get(path, Time.get_ticks_usec())), {"path":path, "result":"loaded"})
			total_progress += 1.0
			completed += 1
			if path == FIGHT_SCENE:
				fight_scene = resource as PackedScene
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loaded_paths[path] = true
			GameDiagnostics.log_event("asset_load_failed", {"path":path, "status":status, "elapsed_ms":float(Time.get_ticks_usec() - int(asset_started_usec.get(path, Time.get_ticks_usec()))) / 1000.0})
			total_progress += 1.0
			completed += 1
		else:
			if not progress.is_empty():
				total_progress += float(progress[0])
	progress_bar.value = total_progress / load_paths.size() * 100.0
	if elapsed >= 0.55 and completed == load_paths.size():
		_enter_fight(false)
	elif elapsed >= 25.0:
		_enter_fight(true)
	elif elapsed - last_progress_log >= 2.0:
		last_progress_log = elapsed
		GameDiagnostics.log_event("asset_load_progress", {"elapsed_ms":elapsed * 1000.0, "completed":completed, "total":load_paths.size(), "progress_percent":progress_bar.value, "pending_paths":_pending_asset_paths()})

func _enter_fight(timed_out: bool) -> void:
	set_process(false)
	GameDiagnostics.log_event("fight_load_complete", {"elapsed_ms":elapsed * 1000.0, "total_assets":load_paths.size(), "timed_out":timed_out, "scene_ready":fight_scene != null})
	if fight_scene == null:
		fight_scene = load(FIGHT_SCENE) as PackedScene
	if fight_scene != null:
		get_tree().change_scene_to_packed(fight_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/story_character_creator.tscn")
	GameDiagnostics.log_timing("fight_resource_preload", load_started_usec, {"total_assets":load_paths.size(), "timed_out":timed_out})

func _pending_asset_paths() -> Array[String]:
	var pending: Array[String] = []
	for path in load_paths:
		if not loaded_paths.get(path, false):
			pending.append(path)
	return pending

func _queue_profile_assets() -> void:
	var config := ConfigFile.new()
	if config.load("user://story_character.cfg") != OK:
		return
	var profile: Dictionary = config.get_value("character", "profile", {})
	var gender := "Male" if str(profile.get("body", "Masculine")) == "Masculine" else "Female"
	var prefix := "Male_" if gender == "Male" else "Female_"
	var character_base := "res://assets/characters/base/"
	var combat_base := "res://assets/combat/"
	var wardrobe_base := "res://assets/characters/wardrobe/quaternius_fantasy/"
	var external_base := "res://assets/characters/wardrobe/external/"
	var skin := str(profile.get("skin", "Light"))
	_queue_load(character_base + ("T_Superhero_Male_%s.png" % skin if gender == "Male" else "T_Superhero_Female_%s_BaseColor.png" % skin))
	var hair := str(profile.get("hair", "Short"))
	if str(profile.get("wardrobe_hat", "None")) == "Hood":
		hair = "None"
	var hair_asset := "Hair_BuzzedFemale" if gender == "Female" else "Hair_Buzzed"
	match hair:
		"Buns": hair_asset = "Hair_Buns"
		"Long": hair_asset = "Hair_Long"
		"Side part": hair_asset = "Hair_SimpleParted"
	if hair != "None":
		_queue_load(combat_base + "hair/%s.gltf" % hair_asset)
	_queue_load(combat_base + "hair/%s.gltf" % ("Eyebrows_Regular" if gender == "Male" else "Eyebrows_Female"))
	for entry in [["wardrobe_shirt", "Body"], ["wardrobe_arms", "Arms"], ["wardrobe_pants", "Legs"], ["wardrobe_boots", "Feet"]]:
		var variant := str(profile.get(entry[0], "Peasant"))
		if variant.ends_with(":Field"):
			_queue_load("res://assets/characters/wardrobe/pavlov_imports/" + ("T_Peasant_2_BaseColor.png" if variant.begins_with("Peasant") else "T_Ranger_3_BaseColor.png"))
			variant = variant.get_slice(":",0)
		if variant not in ["Peasant", "Traveler", "Guard castoff"]:
			continue
		var set_name := "Peasant"
		if variant == "Traveler" or (variant == "Guard castoff" and entry[1] in ["Body", "Arms", "Feet"]):
			set_name = "Ranger"
		var part: String = entry[1]
		if set_name == "Ranger" and part == "Feet" and gender == "Male":
			part = "Feet_Boots"
		_queue_load(wardrobe_base + prefix + set_name + "_" + part + ".gltf")
	if str(profile.get("wardrobe_hands", "None")) == "Fingerless gloves":
		_queue_load(wardrobe_base + prefix + "Peasant_Arms.gltf")
	if str(profile.get("wardrobe_belt", "None")) == "Leather belt":
		_queue_load(wardrobe_base + prefix + "Ranger_Body.gltf")
	if str(profile.get("wardrobe_hat", "None")) == "Hood":
		_queue_load(wardrobe_base + prefix + "Ranger_Head_Hood.gltf")
	if str(profile.get("wardrobe_mask", "None")) in ["Rogue mask", "Cloth mask"]:
		_queue_load(external_base + "rogue_mask_scott_marshall.glb")
	var back := str(profile.get("wardrobe_back", "None"))
	if back == "Cape":
		_queue_load(external_base + "completionist_cape_julien_savoie.glb")
	elif back == "Backpack":
		_queue_load(external_base + "backpack_quaternius.glb")
	var clothing_pool = preload("res://scripts/clothing_pool.gd")
	for slot in ["wardrobe_hat","wardrobe_mask","wardrobe_back","wardrobe_shirt","wardrobe_boots","wardrobe_pants","wardrobe_hands","wardrobe_arms","wardrobe_belt","wardrobe_necklace","wardrobe_earrings","wardrobe_shoulders","wardrobe_bracelet"]:
		var imported_item: Dictionary = clothing_pool.item_for_value(str(profile.get(slot,"")))
		if not imported_item.is_empty() and not bool(imported_item.get("runtime",false)):
			_queue_load(clothing_pool.IMPORT_BASE + str(imported_item.file))

func _queue_load(path: String) -> void:
	if not load_paths.has(path):
		load_paths.append(path)

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("0c1724")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var padding:=MarginContainer.new()
	padding.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	padding.offset_left=-230
	padding.offset_right=230
	padding.offset_top=-48
	padding.offset_bottom=48
	for side in ["left","top","right","bottom"]:padding.add_theme_constant_override("margin_"+side,6)
	add_child(padding)
	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation",6)
	padding.add_child(center)
	var title := Label.new()
	title.text = "ENTERING THE ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("e9c982"))
	center.add_child(title)
	var message := Label.new()
	message.text = "Preparing the fight..."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 15)
	message.add_theme_color_override("font_color", Color("b8c6d2"))
	center.add_child(message)
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 14)
	center.add_child(progress_bar)
