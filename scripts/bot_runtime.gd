extends CanvasLayer
## Local, scriptable development interface. Human UI and bot scripts share the
## same scene transitions and Loadout gear mutation methods.

const BASE_PORT := 47830
const FALLBACK_PORT_BASE := 50000
const PORTS_PER_INSTANCE := 8
const MAIN_SCENE := "res://scenes/home.tscn"
const SCENES := {
	"home": MAIN_SCENE,
	"story": "res://scenes/story_character_select.tscn",
	"book": "res://scenes/story_opponents.tscn",
	"loadout": "res://scenes/story_loadout.tscn",
	"create": "res://scenes/combat_sandbox.tscn",
	"fight": "res://scenes/fight.tscn",
	"dev": "res://scenes/story_dev_menu.tscn",
	"clothing": "res://scenes/clothing_pavlov.tscn",
	"pavlov": "res://scenes/animation_pavlov.tscn",
	"placement": "res://scenes/character_placement.tscn",
	"character_create": "res://scenes/story_character_creator.tscn",
	"replays": "res://scenes/story_replays.tscn",
}

var server := TCPServer.new()
var peers: Array[StreamPeerTCP] = []
var peer_buffers: Dictionary = {}
var port := BASE_PORT + 1
var running := false
var current_function := ""
var script_name := ""
var current_step := 0
var total_steps := 0
var wait_remaining := 0.0
var expected_scene := ""
var transition_from_instance := 0
var last_error := ""
var run_manifest_path := ""
var run_history: Array[Dictionary] = []
var status_panel: PanelContainer
var status_label: Label
var status_close_button: Button
var blink_time := 0.0
var expected_change := false
var abort_requested := false
var unexpected_scene_elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	var instance_id := _instance_id()
	var preferred_port := BASE_PORT + instance_id
	var fallback_start := FALLBACK_PORT_BASE + (instance_id - 1) * PORTS_PER_INSTANCE
	var candidates: Array[int] = [preferred_port]
	for candidate in range(fallback_start, fallback_start + PORTS_PER_INSTANCE):
		if candidate != preferred_port:
			candidates.append(candidate)
	var last_listen_error := ERR_CANT_CREATE
	var attempted: Array[int] = []
	for candidate in candidates:
		attempted.append(candidate)
		last_listen_error = server.listen(candidate, "127.0.0.1")
		if last_listen_error == OK:
			port = candidate
			break
		server.stop()
	if port > 0 and server.is_listening():
		_write_port_discovery_file()
		if port != preferred_port:
			GameDiagnostics.log_event("bot_server_port_fallback", {"instance":instance_id,"preferred_port":preferred_port,"port":port,"attempted":attempted})
		GameDiagnostics.log_event("bot_server_started", {"port":port,"host":"127.0.0.1","instance":instance_id})
	else:
		port = 0
		_remove_port_discovery_file()
		last_error = "Local bot API could not start. Tried port %d and fallback ports %d–%d (%s)." % [preferred_port, fallback_start, fallback_start + PORTS_PER_INSTANCE - 1, error_string(last_listen_error)]
		GameDiagnostics.log_event("bot_server_start_failed", {"instance":instance_id,"preferred_port":preferred_port,"fallback_start":fallback_start,"ports_per_instance":PORTS_PER_INSTANCE,"attempted":attempted,"error":last_listen_error,"message":last_error})
	_build_status_overlay()
	get_tree().tree_changed.connect(_on_tree_changed)
	_update_overlay()

func _instance_id() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--fightlab-instance="):
			return maxi(1, int(argument.trim_prefix("--fightlab-instance=")))
	return 1

func _write_port_discovery_file() -> void:
	var file := FileAccess.open(_port_discovery_path(), FileAccess.WRITE)
	if file == null:
		GameDiagnostics.log_event("bot_port_discovery_write_failed", {"port":port,"error":FileAccess.get_open_error()})
		return
	file.store_string(str(port))
	file.close()

func _remove_port_discovery_file() -> void:
	var path := ProjectSettings.globalize_path(_port_discovery_path())
	if FileAccess.file_exists(_port_discovery_path()):
		DirAccess.remove_absolute(path)

func _port_discovery_path() -> String:
	return "user://bot_api_port.txt" if _instance_id()==1 else "user://bot_api_port_instance_%d.txt" % _instance_id()

func _process(delta: float) -> void:
	if server.is_connection_available():
		var peer := server.take_connection()
		if peer != null:
			peer.poll()
			peers.append(peer)
			peer_buffers[peer.get_instance_id()] = ""
	for peer in peers.duplicate():
		if not is_instance_valid(peer):
			peers.erase(peer)
			continue
		peer.poll()
		var id: int = peer.get_instance_id()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			peers.erase(peer)
			peer_buffers.erase(id)
			continue
		var available: int = peer.get_available_bytes()
		if available <= 0:
			continue
		var read_result: Array = peer.get_data(available)
		if int(read_result[0]) != OK:
			_continue_peer_close(peer)
			continue
		var buffer := str(peer_buffers.get(id, "")) + (read_result[1] as PackedByteArray).get_string_from_utf8()
		if buffer.contains("\n"):
			var request_line := buffer.get_slice("\n", 0).strip_edges()
			peer_buffers[id] = ""
			_handle_request_line(peer, request_line)
		else:
			peer_buffers[id] = buffer.left(65536)
	if running and not expected_scene.is_empty():
		var actual := _scene_id()
		var current_instance := get_tree().current_scene.get_instance_id() if is_instance_valid(get_tree().current_scene) else 0
		if expected_change:
			if actual == expected_scene and current_instance != transition_from_instance:
				expected_change = false
				unexpected_scene_elapsed = 0.0
		elif actual == expected_scene:
			unexpected_scene_elapsed = 0.0
		elif actual == "none":
			# Scene changes briefly clear current_scene; wait for the destination to settle
			# so the diagnostic reports the real screen instead of a transient null.
			unexpected_scene_elapsed += delta
			if unexpected_scene_elapsed >= 0.75:
				_fail_run("Unexpected screen: expected %s, but no scene became active" % expected_scene)
		else:
			unexpected_scene_elapsed = 0.0
			_fail_run("Unexpected screen: expected %s, found %s" % [expected_scene, actual])
	if wait_remaining > 0.0 and running:
		wait_remaining = maxf(0.0, wait_remaining - delta)
		_update_overlay()
	blink_time += delta
	if is_instance_valid(status_panel) and (running or not last_error.is_empty()):
		status_panel.modulate.a = 0.78 + 0.22 * (0.5 + 0.5 * sin(blink_time * 5.0))

func _continue_peer_close(peer: StreamPeerTCP) -> void:
	var id := peer.get_instance_id()
	peers.erase(peer)
	peer_buffers.erase(id)
	peer.disconnect_from_host()

func _handle_request_line(peer: StreamPeerTCP, line: String) -> void:
	var parsed: Variant = JSON.parse_string(line)
	var result: Dictionary
	if not parsed is Dictionary:
		result = {"ok":false,"error":"Send one JSON object per line."}
	else:
		result = await _dispatch(parsed)
	var response := (JSON.stringify(result) + "\n").to_utf8_buffer()
	peer.put_data(response)

func _dispatch(request: Dictionary) -> Dictionary:
	var command := str(request.get("command", ""))
	match command:
		"help":
			return {"ok":true,"commands":["help","status","bot.clear_error","menus.list","menu.open","state.inspect","gear.list","gear.equip","gear.unequip","ui.list","ui.activate","input.key","input.tap","clothing.list","clothing.show","clothing.stats","wait","screenshot","assert","bot.run"]}
		"status":
			return _status()
		"ui.list":
			return {"ok":true,"actions":KeyboardAccess.list_actions()}
		"ui.activate":
			return KeyboardAccess.activate(str(request.get("id","")),request.get("value",""))
		"input.key":
			return KeyboardAccess.send_key(str(request.get("key","")),bool(request.get("pressed",true)),bool(request.get("ctrl",false)),bool(request.get("shift",false)),bool(request.get("alt",false)))
		"input.tap":
			var response := KeyboardAccess.send_key(str(request.get("key","")),true,bool(request.get("ctrl",false)),bool(request.get("shift",false)),bool(request.get("alt",false)))
			await get_tree().process_frame
			KeyboardAccess.send_key(str(request.get("key","")),false,bool(request.get("ctrl",false)),bool(request.get("shift",false)),bool(request.get("alt",false)))
			return response
		"bot.clear_error":
			last_error = ""
			expected_scene = ""
			expected_change = false
			unexpected_scene_elapsed = 0.0
			_update_overlay()
			GameDiagnostics.log_event("bot_error_cleared")
			return {"ok":true}
		"menus.list":
			return {"ok":true,"menus":SCENES.keys(),"current":_scene_id()}
		"menu.open":
			return await _open_menu(str(request.get("menu", "")))
		"state.inspect":
			return _inspect_state()
		"clothing.list":
			var pool = preload("res://scripts/clothing_pool.gd")
			var matches: Array = []
			var category := str(request.get("category","all"))
			var body_part := str(request.get("body_part","all"))
			var query := str(request.get("search","")).to_lower()
			for item in pool.catalog():
				if category != "all" and pool.category(item) != category: continue
				if body_part != "all" and pool.body_part(item) != body_part: continue
				if not query.is_empty() and not query in (str(item.name)+" "+str(item.source)).to_lower(): continue
				matches.append(item)
			var offset := clampi(int(request.get("offset",0)),0,matches.size())
			var limit := clampi(int(request.get("limit",100)),1,500)
			return {"ok":true,"total":matches.size(),"offset":offset,"limit":limit,"items":matches.slice(offset,mini(offset+limit,matches.size()))}
		"clothing.stats":
			var pool = preload("res://scripts/clothing_pool.gd")
			var categories := {}
			var body_parts := {}
			for item in pool.imported():
				var category: String = pool.category(item)
				categories[category] = int(categories.get(category,0))+1
				var part: String = pool.body_part(item)
				body_parts[part] = int(body_parts.get(part,0))+1
			return {"ok":true,"imported_models":pool.imported().size(),"review_options":pool.catalog().size(),"categories":categories,"body_parts":body_parts}
		"clothing.show":
			var scene := get_tree().current_scene
			if _scene_id() != "clothing" or not scene.has_method("bot_show_item"):
				return {"ok":false,"error":"Open Clothing Pavlov first."}
			return scene.bot_show_item(str(request.get("id","")))
		"gear.list":
			return _gear_list(str(request.get("part", "")))
		"gear.equip":
			return await _set_gear(str(request.get("part", "")), str(request.get("item", "")))
		"gear.unequip":
			return await _set_gear(str(request.get("part", "")), "")
		"wait":
			var seconds := clampf(float(request.get("seconds", 0.0)), 0.0, 300.0)
			await _wait(seconds, "wait")
			return {"ok":last_error.is_empty(),"waited_seconds":seconds}
		"screenshot":
			return await _take_screenshot(str(request.get("name", "bot_capture")))
		"assert":
			return _assert_request(request)
		"bot.run":
			return _start_script(request)
		_:
			return {"ok":false,"error":"Unknown command: %s" % command}

func _status() -> Dictionary:
	return {"ok":true,"api_port":port,"running":running,"function":current_function,"step":current_step,"total_steps":total_steps,"waiting_seconds":snappedf(wait_remaining, 0.1),"scene":_scene_id(),"expected_scene":expected_scene,"error":last_error}

func _open_menu(menu_id: String) -> Dictionary:
	if not SCENES.has(menu_id):
		return {"ok":false,"error":"Unknown menu: %s" % menu_id}
	var path := str(SCENES[menu_id])
	transition_from_instance = get_tree().current_scene.get_instance_id() if is_instance_valid(get_tree().current_scene) else 0
	expected_scene = menu_id
	expected_change = true
	GameDiagnostics.log_event("bot_menu_open", {"menu":menu_id,"scene":path})
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		expected_change = false
		last_error = "Could not open menu %s (error %d)" % [menu_id,error]
		GameDiagnostics.log_event("bot_error", {"error":last_error})
		return {"ok":false,"error":last_error}
	for frame in 12:
		await get_tree().process_frame
		var current_instance := get_tree().current_scene.get_instance_id() if is_instance_valid(get_tree().current_scene) else 0
		if _scene_id() == menu_id and current_instance != transition_from_instance:
			expected_change = false
			return {"ok":true,"menu":menu_id}
	last_error = "Menu %s did not finish loading" % menu_id
	GameDiagnostics.log_event("bot_error", {"error":last_error})
	return {"ok":false,"error":last_error}

func _gear_list(part: String) -> Dictionary:
	var profile := _load_profile()
	var items: Array = profile.get("gear_inventory", [])
	var results: Array[Dictionary] = []
	for item in items:
		if item is Dictionary and (part.is_empty() or str(item.get("part", "")) == part):
			results.append({"id":item.get("id", ""),"name":item.get("name", "Gear"),"part":item.get("part", ""),"slot":item.get("slot", "")})
	return {"ok":true,"gear":results}

func _set_gear(part: String, item_id: String) -> Dictionary:
	if part not in ["chest","left_arm","right_arm","left_leg","right_leg","left_boot","right_boot","left_hand","right_hand","head","face","belt","back"]:
		return {"ok":false,"error":"Unknown body slot: %s" % part}
	if _scene_id() != "loadout":
		return {"ok":false,"error":"Open Loadout before changing equipped gear."}
	var scene := get_tree().current_scene
	if not is_instance_valid(scene) or not scene.has_method("bot_set_gear"):
		return {"ok":false,"error":"Current Loadout does not expose the bot gear action."}
	var result: Variant = await scene.call("bot_set_gear", part, item_id)
	if not result is Dictionary:
		return {"ok":false,"error":"Loadout rejected the gear change."}
	# Wait for the same preview refresh started by the visible Loadout action. This
	# keeps scripted screenshots and timed holds aligned with what the player sees.
	var preview_started := Time.get_ticks_msec()
	await get_tree().process_frame
	while is_instance_valid(scene) and bool(scene.get("preview_loading")) and Time.get_ticks_msec() - preview_started < 15000:
		await get_tree().process_frame
	if is_instance_valid(scene) and bool(scene.get("preview_loading")):
		return {"ok":false,"error":"Character preview did not finish loading after gear changed."}
	GameDiagnostics.log_event("bot_gear_preview_ready", {"part":part,"item":item_id,"elapsed_ms":Time.get_ticks_msec()-preview_started})
	return result

func _inspect_state() -> Dictionary:
	var profile := _load_profile()
	var part_gear: Dictionary = profile.get("story_part_gear", {})
	return {"ok":true,"scene":_scene_id(),"character":profile.get("name", ""),"equipped":part_gear.duplicate(true),"story_stage":profile.get("story_stage", 1)}

func _assert_request(request: Dictionary) -> Dictionary:
	var assertion := str(request.get("check", ""))
	var passed := false
	match assertion:
		"scene_is": passed = _scene_id() == str(request.get("value", ""))
		"gear_is": passed = str(_load_profile().get("story_part_gear", {}).get(str(request.get("part", "")), "")) == str(request.get("value", ""))
		_: return {"ok":false,"error":"Unknown assertion: %s" % assertion}
	if not passed:
		last_error = "Assertion failed: %s" % assertion
		GameDiagnostics.log_event("bot_assertion_failed", {"check":assertion,"request":request})
	return {"ok":passed,"check":assertion,"error":last_error if not passed else ""}

func _start_script(request: Dictionary) -> Dictionary:
	if running:
		return {"ok":false,"error":"A bot script is already running."}
	var commands: Variant = request.get("steps", [])
	if not commands is Array or commands.is_empty():
		return {"ok":false,"error":"bot.run needs a non-empty steps array."}
	running = true
	abort_requested = false
	last_error = ""
	expected_scene = ""
	expected_change = false
	unexpected_scene_elapsed = 0.0
	current_function = str(request.get("name", "Bot script"))
	if current_function.is_empty():current_function = "Bot script"
	script_name = current_function
	current_step = 0
	total_steps = commands.size()
	wait_remaining = 0.0
	run_history.clear()
	_begin_manifest(request, commands)
	GameDiagnostics.log_event("bot_script_started", {"name":current_function,"steps":total_steps,"scene":_scene_id()})
	_update_overlay()
	_execute_script(commands)
	return {"ok":true,"accepted":true,"name":script_name,"steps":total_steps}

func start_gear_demo() -> Dictionary:
	return _start_script({"name":"Gear equip / wait / remove","steps":[
		{"command":"menu.open","menu":"loadout"},
		{"command":"gear.equip","part":"left_arm","item":"starter_left_arm"},
		{"command":"screenshot","name":"left-arm-equipped"},
		{"command":"wait","seconds":5.0},
		{"command":"gear.unequip","part":"left_arm"},
		{"command":"screenshot","name":"left-arm-unequipped"}
	]})

func _execute_script(commands: Array) -> void:
	for command in commands:
		if not running or abort_requested:
			break
		current_step += 1
		current_function = script_name
		var step_started := Time.get_ticks_msec()
		var result: Dictionary = await _dispatch(command if command is Dictionary else {})
		var row := {"step":current_step,"command":command,"result":result,"elapsed_ms":Time.get_ticks_msec()-step_started}
		run_history.append(row)
		GameDiagnostics.log_event("bot_step", row)
		if not bool(result.get("ok", false)):
			if last_error.is_empty():
				_fail_run(str(result.get("error", "Bot command failed")))
			else:
				_write_manifest("failed")
			_update_overlay()
			return
		_write_manifest("running")
		_update_overlay()
	if running:
		running = false
		current_function = ""
		script_name = ""
		expected_scene = ""
		wait_remaining = 0.0
		GameDiagnostics.log_event("bot_script_completed", {"steps":current_step,"manifest":run_manifest_path})
		_write_manifest("complete")
		_update_overlay()

func _wait(seconds: float, function_name: String) -> void:
	var started_usec := Time.get_ticks_usec()
	var deadline_usec := started_usec + int(round(seconds * 1000000.0))
	wait_remaining = seconds
	current_function = function_name
	GameDiagnostics.log_event("bot_wait_started", {"seconds":seconds,"function":function_name})
	_update_overlay()
	while running and Time.get_ticks_usec() < deadline_usec:
		wait_remaining = maxf(0.0, float(deadline_usec - Time.get_ticks_usec()) / 1000000.0)
		_update_overlay()
		await get_tree().process_frame
	var elapsed_ms := float(Time.get_ticks_usec() - started_usec) / 1000.0
	wait_remaining = 0.0
	if running:
		GameDiagnostics.log_event("bot_wait_completed", {"seconds":seconds,"elapsed_ms":elapsed_ms,"function":function_name})

func _take_screenshot(name: String) -> Dictionary:
	await RenderingServer.frame_post_draw
	var safe_name := name.strip_edges().replace("/", "_").replace("\\", "_")
	if safe_name.is_empty():safe_name = "bot_capture"
	var path := run_manifest_path.get_base_dir() + "/" + safe_name + ".png" if not run_manifest_path.is_empty() else "user://bot_runs/%s.png" % safe_name
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(absolute)
	return {"ok":error==OK,"screenshot":absolute,"error":"Screenshot failed (%d)"%error if error!=OK else ""}

func _begin_manifest(request: Dictionary, commands: Array) -> void:
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "-").replace("T", "_")
	var directory := "user://bot_runs/%s_%d" % [stamp, OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	run_manifest_path = directory + "/manifest.json"
	_write_manifest("running", {"request":request,"commands":commands})

func _write_manifest(status := "running", extra: Dictionary = {}) -> void:
	if run_manifest_path.is_empty():return
	var manifest := {"status":status,"function":current_function,"current_step":current_step,"total_steps":total_steps,"scene":_scene_id(),"error":last_error,"steps":run_history,"updated_at":Time.get_datetime_string_from_system(true)}
	for key in extra:manifest[key]=extra[key]
	var file := FileAccess.open(run_manifest_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t"))
		file.close()

func _fail_run(message: String) -> void:
	if not running and not last_error.is_empty():return
	running = false
	wait_remaining = 0.0
	last_error = message
	current_function = ""
	script_name = ""
	expected_change = false
	abort_requested = true
	GameDiagnostics.log_event("bot_unexpected_state", {"error":message,"scene":_scene_id(),"expected_scene":expected_scene,"step":current_step})
	GameDiagnostics.log_event("bot_script_failed", {"error":message,"manifest":run_manifest_path})
	_write_manifest("failed")
	_update_overlay()

func report_error(message: String) -> void:
	last_error = message
	GameDiagnostics.log_event("bot_error", {"error":message,"scene":_scene_id()})
	_update_overlay()

func _load_profile() -> Dictionary:
	var config := ConfigFile.new()
	if config.load("user://story_character.cfg") != OK:return {}
	var profile: Variant = config.get_value("character", "profile", {})
	return profile.duplicate(true) if profile is Dictionary else {}

func _scene_id() -> String:
	var current := get_tree().current_scene
	if not is_instance_valid(current):return "none"
	for menu in SCENES:
		if str(SCENES[menu]).get_file().get_basename() == current.scene_file_path.get_file().get_basename():return menu
	return current.scene_file_path.get_file().get_basename()

func _on_tree_changed() -> void:
	if not running or expected_scene.is_empty():return
	var actual := _scene_id()
	var current_instance := get_tree().current_scene.get_instance_id() if is_instance_valid(get_tree().current_scene) else 0
	if actual == "none":return
	if expected_change:
		if actual == expected_scene and current_instance != transition_from_instance:
			expected_change = false
			unexpected_scene_elapsed = 0.0
		return
	if actual == expected_scene:
		unexpected_scene_elapsed = 0.0
	elif actual != expected_scene:
		unexpected_scene_elapsed = 0.0
		_fail_run("Unexpected screen: expected %s, found %s" % [expected_scene, actual])

func _build_status_overlay() -> void:
	status_panel = PanelContainer.new()
	status_panel.name = "BotStatusBanner"
	status_panel.anchor_left = 0.5
	status_panel.anchor_right = 0.5
	status_panel.offset_left = -310
	status_panel.offset_right = 310
	status_panel.offset_top = 18
	status_panel.offset_bottom = 74
	status_panel.visible = false
	status_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("9b3a21")
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.border_color = Color("f0c55b")
	status_panel.add_theme_stylebox_override("panel", style)
	add_child(status_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	status_panel.add_child(row)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(status_label)
	status_close_button = Button.new()
	status_close_button.text = "X"
	status_close_button.tooltip_text = "Dismiss bot error"
	status_close_button.custom_minimum_size = Vector2(40, 40)
	status_close_button.add_theme_font_size_override("font_size", 20)
	status_close_button.visible = false
	status_close_button.pressed.connect(_dismiss_bot_error)
	row.add_child(status_close_button)

func _dismiss_bot_error() -> void:
	last_error = ""
	expected_scene = ""
	expected_change = false
	unexpected_scene_elapsed = 0.0
	GameDiagnostics.log_event("bot_error_dismissed", {"scene":_scene_id()})
	_update_overlay()

func _update_overlay() -> void:
	if not is_instance_valid(status_panel) or not is_instance_valid(status_label) or not is_instance_valid(status_close_button):return
	if running:
		status_panel.visible = true
		status_close_button.visible = false
		status_panel.get_theme_stylebox("panel").bg_color = Color("9b3a21")
		if wait_remaining > 0.0:
			status_label.text = "BOT RUNNING  ·  %s  ·  WAIT %.1fs  ·  %d/%d" % [current_function.to_upper(), wait_remaining, current_step, total_steps]
		else:
			status_label.text = "BOT RUNNING  ·  %s  ·  %d/%d" % [current_function.to_upper(), current_step, total_steps]
	elif not last_error.is_empty():
		status_panel.visible = true
		status_close_button.visible = true
		status_panel.get_theme_stylebox("panel").bg_color = Color("b52d27")
		status_label.text = "BOT ERROR  ·  " + last_error
	else:
		status_panel.visible = false
		status_close_button.visible = false
