extends Node
## Persistent, structured diagnostics for input, UI interaction, engine output and errors.

const ROOT := "user://logs"
const MAX_LOG_BYTES := 8 * 1024 * 1024
const ROTATED_FILES := 3
const MAX_SESSIONS := 20
const SLOW_FRAME_MS := 33.3
const SLOW_REPORT_INTERVAL_MS := 1000

class FightLabLogger extends Logger:
	var sink: Node

	func _log_message(message: String, error: bool) -> void:
		if is_instance_valid(sink):
			sink.call("_capture_engine_message", message, error)

	func _log_error(function_name: String, file_name: String, line_number: int, code: String, rationale: String, editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		if is_instance_valid(sink):
			sink.call("_capture_engine_error", function_name, file_name, line_number, code, rationale, editor_notify, error_type, script_backtraces)

var _logger: FightLabLogger
var _file_mutex := Mutex.new()
var _session_dir := ""
var _scene_path := ""
var _elapsed_since_summary := 0.0
var _event_sequence := 0
var _last_axes: Dictionary = {}
var _last_axis_log_time: Dictionary = {}
var _slow_frame_count := 0
var _slow_frame_peak_ms := 0.0
var _slow_frame_last_ms := 0.0
var _last_slow_report_ms := 0
var _last_timing_sample_ms := 0
var _physics_steps_since_process := 0
var _scene_entered_usec := 0
var _slow_operation_buckets: Dictionary = {}
var _native_log_offset := 0
var _native_sync_elapsed := 0.0
var _native_error_context := false

func _init() -> void:
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "-").replace("T", "_")
	_session_dir = "%s/sessions/%s_%d" % [ROOT, stamp, OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_session_dir))
	# Godot's native file logger is shared across launches. Start at its current
	# end so this session doesn't copy every previous session into its own logs.
	var NATIVE_LOG_PATH := str(ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log"))
	if FileAccess.file_exists(NATIVE_LOG_PATH):
		var existing_native_log := FileAccess.open(NATIVE_LOG_PATH, FileAccess.READ)
		if existing_native_log != null:
			_native_log_offset = existing_native_log.get_length()
			existing_native_log.close()
	_prune_old_sessions()
	for name in ["events.jsonl", "clicks.jsonl", "interactions.jsonl", "console.log", "engine_console.log", "errors.log", "errors.jsonl"]:
		_write_text("%s/%s" % [_session_dir, name], "")
	_logger = FightLabLogger.new()
	_logger.sink = self
	OS.add_logger(_logger)

func _ready() -> void:
	log_event("session_start", {
		"godot": Engine.get_version_info(),
		"platform": OS.get_name(),
		"executable": OS.get_executable_path(),
		"command_line": OS.get_cmdline_args(),
		"user_args": OS.get_cmdline_user_args(),
		"session_dir": _session_dir
	})
	_write_text("%s/latest_session.txt" % ROOT, ProjectSettings.globalize_path(_session_dir) + "\n")
	get_tree().node_added.connect(_on_node_added)
	_instrument_tree(get_tree().root)
	_scene_path = _current_scene_path()
	_scene_entered_usec = Time.get_ticks_usec()
	_last_slow_report_ms = Time.get_ticks_msec()
	_last_timing_sample_ms = Time.get_ticks_msec()
	log_event("scene_enter", {"scene": _scene_path})
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_sync_native_log()

func _process(delta: float) -> void:
	_native_sync_elapsed += delta
	if _native_sync_elapsed >= 0.25:
		_native_sync_elapsed = 0.0
		_sync_native_log()
	var current := _current_scene_path()
	if current != _scene_path:
		var now_usec := Time.get_ticks_usec()
		log_event("scene_change", {"from": _scene_path, "to": current, "previous_scene_ms": float(now_usec - _scene_entered_usec) / 1000.0})
		_scene_path = current
		_scene_entered_usec = now_usec
	if delta * 1000.0 >= SLOW_FRAME_MS:
		_slow_frame_count += 1
		_slow_frame_last_ms = delta * 1000.0
		_slow_frame_peak_ms = maxf(_slow_frame_peak_ms, _slow_frame_last_ms)
	var process_count := _physics_steps_since_process
	_physics_steps_since_process = 0
	if process_count > 1:
		log_event("physics_catchup", {"steps_before_render":process_count, "frame_ms":delta * 1000.0})
	var now_ms := Time.get_ticks_msec()
	if now_ms - _last_slow_report_ms >= SLOW_REPORT_INTERVAL_MS:
		if _slow_frame_count > 0:
			log_event("slow_frame_batch", {"count":_slow_frame_count, "peak_ms":_slow_frame_peak_ms, "last_ms":_slow_frame_last_ms, "threshold_ms":SLOW_FRAME_MS, "severity":"error" if _slow_frame_peak_ms >= 100.0 else "warning"})
		_slow_frame_count = 0
		_slow_frame_peak_ms = 0.0
		_last_slow_report_ms = now_ms
		_flush_slow_operations()
	if now_ms - _last_timing_sample_ms >= 1000:
		_sample_engine_timing()
		_last_timing_sample_ms = now_ms
	_elapsed_since_summary += delta
	if _elapsed_since_summary >= 10.0:
		_elapsed_since_summary = 0.0
		log_event("performance_snapshot", {
			"scene": _scene_path,
			"fps": Engine.get_frames_per_second(),
			"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"physics_process_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"navigation_process_ms": Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS) * 1000.0,
			"process_frames": Engine.get_process_frames(),
			"physics_frames": Engine.get_physics_frames(),
			"static_memory_bytes": OS.get_static_memory_usage(),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
			"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
		})

func _physics_process(_delta: float) -> void:
	_physics_steps_since_process += 1

func _sample_engine_timing() -> void:
	var process_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var navigation_ms := Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS) * 1000.0
	var slow_process := process_ms >= 25.0
	var slow_physics := physics_ms >= 8.0
	var slow_navigation := navigation_ms >= 8.0
	if slow_process or slow_physics or slow_navigation:
		log_event("slow_engine_timing", {
			"process_ms":process_ms,
			"physics_process_ms":physics_ms,
			"navigation_process_ms":navigation_ms,
			"process_threshold_ms":25.0,
			"physics_threshold_ms":8.0,
			"scene":_scene_path,
			"severity":"error" if process_ms >= 50.0 or physics_ms >= 16.0 else "warning"
		})

func log_timing(operation: String, started_usec: int, details: Dictionary = {}) -> void:
	var elapsed_ms := float(Time.get_ticks_usec() - started_usec) / 1000.0
	var record := details.duplicate(true)
	record["operation"] = operation
	record["duration_ms"] = elapsed_ms
	record["slow"] = elapsed_ms >= SLOW_FRAME_MS
	log_event("operation_timing", record)

func track_loop_time(operation: String, started_usec: int, threshold_ms: float, details: Dictionary = {}) -> void:
	var elapsed_ms := float(Time.get_ticks_usec() - started_usec) / 1000.0
	if elapsed_ms < threshold_ms:
		return
	var bucket: Dictionary = _slow_operation_buckets.get(operation, {"count":0, "peak_ms":0.0, "last_ms":0.0})
	bucket["count"] = int(bucket.get("count", 0)) + 1
	bucket["peak_ms"] = maxf(float(bucket.get("peak_ms", 0.0)), elapsed_ms)
	bucket["last_ms"] = elapsed_ms
	bucket["threshold_ms"] = threshold_ms
	bucket["details"] = details.duplicate(true)
	_slow_operation_buckets[operation] = bucket

func _flush_slow_operations() -> void:
	for operation in _slow_operation_buckets:
		var details: Dictionary = _slow_operation_buckets[operation].duplicate(true)
		details["operation"] = operation
		log_event("slow_operation_batch", details)
	_slow_operation_buckets.clear()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var target := _hovered_control()
		var details := {
			"button": _mouse_button_name(event.button_index),
			"button_index": event.button_index,
			"pressed": event.pressed,
			"double_click": event.double_click,
			"position": [event.position.x, event.position.y],
			"target": _describe_control(target) if target != null else _world_target(event.position)
		}
		log_event("click", details)
	elif event is InputEventKey:
		if event.echo:
			return
		log_event("key_input", {
			"keycode": event.keycode,
			"physical_keycode": event.physical_keycode,
			"pressed": event.pressed,
			"echo": event.echo,
			"scene": _scene_path
		})
	elif event is InputEventJoypadButton:
		log_event("controller_button", {
			"device": event.device,
			"button": event.button_index,
			"pressed": event.pressed,
			"pressure": event.pressure,
			"scene": _scene_path
		})
	elif event is InputEventJoypadMotion:
		_log_axis_if_meaningful(event)
	elif event is InputEventScreenTouch:
		log_event("touch", {"index":event.index, "pressed":event.pressed, "position":[event.position.x, event.position.y], "target":_describe_control(_hovered_control()) if _hovered_control() != null else _world_target(event.position)})

func log_event(category: String, details: Dictionary = {}) -> void:
	_event_sequence += 1
	var record := {
		"sequence": _event_sequence,
		"time": Time.get_datetime_string_from_system(true),
		"monotonic_ms": Time.get_ticks_msec(),
		"process_frame": Engine.get_process_frames(),
		"physics_frame": Engine.get_physics_frames(),
		"category": category,
		"scene": _scene_path,
		"details": details
	}
	var line := JSON.stringify(record)
	_append_line("%s/events.jsonl" % _session_dir, line)
	if category == "click":
		_append_line("%s/clicks.jsonl" % _session_dir, line)
	elif category.begins_with("ui_"):
		_append_line("%s/interactions.jsonl" % _session_dir, line)

func _capture_engine_message(message: String, error: bool) -> void:
	var level := "STDERR" if error else "STDOUT"
	var line := "%s [%s] %s" % [Time.get_datetime_string_from_system(true), level, message]
	_append_line("%s/console.log" % _session_dir, line)
	if error:
		_append_line("%s/errors.log" % _session_dir, line)

func _sync_native_log() -> void:
	var NATIVE_LOG_PATH := str(ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log"))
	if not FileAccess.file_exists(NATIVE_LOG_PATH):
		return
	var native_log := FileAccess.open(NATIVE_LOG_PATH, FileAccess.READ)
	if native_log == null:
		return
	var file_length := native_log.get_length()
	if file_length < _native_log_offset:
		_native_log_offset = 0
	if file_length == _native_log_offset:
		native_log.close()
		return
	native_log.seek(_native_log_offset)
	while not native_log.eof_reached():
		var line := native_log.get_line()
		_append_line("%s/engine_console.log" % _session_dir, line)
		var normalized := line.to_lower()
		var begins_error := normalized.contains("error:") or normalized.contains("warning:") or normalized.contains("crash") or normalized.contains("exception") or normalized.contains("failed to load")
		if begins_error:
			_native_error_context = true
		if _native_error_context:
			_append_line("%s/errors.log" % _session_dir, line)
			if line.strip_edges().is_empty():
				_native_error_context = false
	_native_log_offset = native_log.get_position()
	native_log.close()

func _capture_engine_error(function_name: String, file_name: String, line_number: int, code: String, rationale: String, editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	var frames := PackedStringArray()
	for frame in script_backtraces:
		frames.append(str(frame))
	var message := "%s | %s:%d | %s | %s | %s" % [Time.get_datetime_string_from_system(true), file_name, line_number, function_name, rationale, code]
	var record := {
		"time": Time.get_datetime_string_from_system(true),
		"severity": "ERROR" if error_type in [Logger.ERROR_TYPE_ERROR, Logger.ERROR_TYPE_SCRIPT, Logger.ERROR_TYPE_SHADER] else "WARNING",
		"error_type": error_type,
		"file": file_name,
		"line": line_number,
		"function": function_name,
		"rationale": rationale,
		"code": code,
		"editor_notify": editor_notify,
		"script_backtraces": frames
	}
	_append_line("%s/errors.log" % _session_dir, message)
	_append_line("%s/errors.jsonl" % _session_dir, JSON.stringify(record))
	_append_line("%s/console.log" % _session_dir, "[ENGINE ERROR] " + message)

func _instrument_tree(node: Node) -> void:
	_instrument_node(node)
	for child in node.get_children():
		_instrument_tree(child)

func _on_node_added(node: Node) -> void:
	_instrument_node(node)

func _instrument_node(node: Node) -> void:
	if not node is Control or node.has_meta("fightlab_diagnostics_hooked"):
		return
	node.set_meta("fightlab_diagnostics_hooked", true)
	var instance_id := node.get_instance_id()
	if node is BaseButton:
		node.pressed.connect(_on_button_pressed.bind(instance_id))
		node.toggled.connect(_on_button_toggled.bind(instance_id))
	if node is Range and not node is ProgressBar and not node is TextureProgressBar:
		node.value_changed.connect(_on_range_changed.bind(instance_id))
	if node is OptionButton:
		node.item_selected.connect(_on_option_selected.bind(instance_id))
	if node is LineEdit:
		node.text_changed.connect(_on_line_edit_changed.bind(instance_id))
	if node is TextEdit:
		node.text_changed.connect(_on_text_edit_changed.bind(instance_id))
	if node is ColorPickerButton:
		node.color_changed.connect(_on_color_changed.bind(instance_id))

func _on_button_pressed(instance_id: int) -> void:
	var control := instance_from_id(instance_id) as BaseButton
	if control != null:
		log_event("ui_action", _describe_control(control))

func _on_button_toggled(pressed: bool, instance_id: int) -> void:
	var control := instance_from_id(instance_id) as BaseButton
	if control != null:
		var data := _describe_control(control)
		data["pressed"] = pressed
		log_event("ui_value", data)

func _on_range_changed(value: float, instance_id: int) -> void:
	var control := instance_from_id(instance_id) as Range
	if control != null:
		var data := _describe_control(control)
		data["value"] = value
		log_event("ui_value", data)

func _on_option_selected(index: int, instance_id: int) -> void:
	var control := instance_from_id(instance_id) as OptionButton
	if control != null:
		var data := _describe_control(control)
		data["selected_index"] = index
		data["selected_id"] = control.get_item_id(index)
		data["selected_text"] = control.get_item_text(index)
		log_event("ui_value", data)

func _on_line_edit_changed(value: String, instance_id: int) -> void:
	var control := instance_from_id(instance_id) as LineEdit
	if control != null:
		var data := _describe_control(control)
		data["text"] = value
		log_event("ui_value", data)

func _on_text_edit_changed(instance_id: int) -> void:
	var control := instance_from_id(instance_id) as TextEdit
	if control != null:
		var data := _describe_control(control)
		data["text"] = control.text
		log_event("ui_value", data)

func _on_color_changed(color: Color, instance_id: int) -> void:
	var control := instance_from_id(instance_id) as ColorPickerButton
	if control != null:
		var data := _describe_control(control)
		data["color"] = color.to_html(true)
		log_event("ui_value", data)

func _hovered_control() -> Control:
	return get_viewport().gui_get_hovered_control()

func _describe_control(control: Control) -> Dictionary:
	var path := str(control.get_path()) if control.is_inside_tree() else _detached_node_path(control)
	var details := {"name": control.name, "path": path, "detached": not control.is_inside_tree(), "type": control.get_class(), "tooltip": control.tooltip_text}
	if control is BaseButton:
		details["text"] = control.text
		details["disabled"] = control.disabled
		details["pressed"] = control.button_pressed
	if control is Range:
		details["value"] = control.value
		details["min"] = control.min_value
		details["max"] = control.max_value
	if control is OptionButton and control.selected >= 0:
		details["selected_index"] = control.selected
		details["selected_text"] = control.get_item_text(control.selected)
	if control is LineEdit:
		details["text"] = control.text
	if control is TextEdit:
		details["text_length"] = control.text.length()
	if control is Label:
		details["text"] = control.text
	return details

func _detached_node_path(node: Node) -> String:
	var segments := PackedStringArray()
	var current: Node = node
	while current != null:
		segments.append(str(current.name))
		current = current.get_parent()
	segments.reverse()
	return "<detached>/%s" % "/".join(segments)

func _world_target(screen_position: Vector2) -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return {"type": "viewport"}
	var world := get_viewport().world_3d
	if world == null:
		return {"type": "viewport_2d"}
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 1000.0)
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {"type": "world", "position": [origin.x, origin.y, origin.z]}
	var collider: Object = hit.get("collider")
	return {
		"type": "world_object",
		"node": str(collider.get_path()) if collider is Node else str(collider),
		"class": collider.get_class() if collider is Object else "unknown",
		"position": [hit.position.x, hit.position.y, hit.position.z]
	}

func _mouse_button_name(button_index: int) -> String:
	return {MOUSE_BUTTON_LEFT:"left", MOUSE_BUTTON_RIGHT:"right", MOUSE_BUTTON_MIDDLE:"middle", MOUSE_BUTTON_WHEEL_UP:"wheel_up", MOUSE_BUTTON_WHEEL_DOWN:"wheel_down", MOUSE_BUTTON_XBUTTON1:"x1", MOUSE_BUTTON_XBUTTON2:"x2"}.get(button_index, "button_%d" % button_index)

func _log_axis_if_meaningful(event: InputEventJoypadMotion) -> void:
	var key := "%d:%d" % [event.device, event.axis]
	var previous := float(_last_axes.get(key, 0.0))
	var now := Time.get_ticks_msec()
	var last_log := int(_last_axis_log_time.get(key, 0))
	var crossed_deadzone := (absf(previous) < 0.2) != (absf(event.axis_value) < 0.2)
	if crossed_deadzone or (absf(event.axis_value) >= 0.2 and (absf(event.axis_value - previous) >= 0.3 or now - last_log >= 500)):
		log_event("controller_axis", {"device":event.device, "axis":event.axis, "value":event.axis_value})
		_last_axis_log_time[key] = now
	_last_axes[key] = event.axis_value

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	log_event("controller_connection", {"device":device, "connected":connected, "name":Input.get_joy_name(device) if connected else ""})

func _on_viewport_resized() -> void:
	log_event("viewport_resized", {"size":[get_viewport().size.x, get_viewport().size.y]})

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		log_event("application_focus", {"focused":true})
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		log_event("application_focus", {"focused":false})

func _current_scene_path() -> String:
	var scene := get_tree().current_scene
	return str(scene.scene_file_path) if scene != null else ""

func _append_line(path: String, line: String) -> void:
	_file_mutex.lock()
	_rotate_if_needed(path)
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE
	var file := FileAccess.open(path, mode)
	if file != null:
		file.seek_end()
		file.store_line(line)
		file.flush()
		file.close()
	_file_mutex.unlock()

func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.flush()
		file.close()

func _rotate_if_needed(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var reader := FileAccess.open(path, FileAccess.READ)
	if reader == null:
		return
	var oversized := reader.get_length() >= MAX_LOG_BYTES
	reader.close()
	if not oversized:
		return
	var absolute := ProjectSettings.globalize_path(path)
	for index in range(ROTATED_FILES, 0, -1):
		var source := absolute if index == 1 else absolute + ".%d" % (index - 1)
		var destination := absolute + ".%d" % index
		if FileAccess.file_exists(source):
			if FileAccess.file_exists(destination):
				DirAccess.remove_absolute(destination)
			DirAccess.rename_absolute(source, destination)

func _prune_old_sessions() -> void:
	var sessions_path := "%s/sessions" % ROOT
	var sessions := DirAccess.get_directories_at(sessions_path)
	sessions.sort()
	while sessions.size() > MAX_SESSIONS:
		var oldest := sessions[0]
		sessions.remove_at(0)
		_remove_old_directory("%s/%s" % [sessions_path, oldest])

func _remove_old_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		directory.remove(file_name)
	for child_name in directory.get_directories():
		_remove_old_directory("%s/%s" % [path, child_name])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _exit_tree() -> void:
	_sync_native_log()
	log_event("session_end", {"scene": _scene_path})
	_sync_native_log()
