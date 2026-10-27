extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name()=="headless":
		push_error("Run this startup check with the native display")
		quit(1)
		return
	var mode:=DisplayServer.window_get_mode()
	var size:=DisplayServer.window_get_size()
	var screen:=DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	print("WINDOW mode=%d borderless=%s size=%s screen=%s"%[mode,DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS),size,screen])
	var correct: bool=mode==DisplayServer.WINDOW_MODE_FULLSCREEN and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS) and size==screen
	if correct:print("PASS: native borderless fullscreen at the monitor resolution, without exclusive fullscreen")
	else:push_error("Native window must open in borderless fullscreen at monitor size")
	quit(0 if correct else 1)
