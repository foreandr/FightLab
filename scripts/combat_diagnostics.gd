extends RefCounted
## Optional host telemetry; shared combat can also load without the game's UI.
static func event(host:Node,name:String,details:Dictionary) -> void:
	var diagnostics:=host.get_node_or_null("/root/GameDiagnostics")
	if is_instance_valid(diagnostics):diagnostics.log_event(name,details)
