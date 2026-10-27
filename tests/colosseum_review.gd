extends SceneTree
var field: Node3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func run() -> void:
	field=load("res://scenes/main.tscn").instantiate()
	root.add_child(field)
	field.review_camera=true
	field.camera.position=Vector3(38,40,48)
	field.camera.fov=50
	field.camera.look_at(Vector3(0,4,0))
	field.hud.get_parent().visible=false
	await frames(180)
	field.hud.get_parent().visible=true
	field.camera.position=Vector3(0,6,14)
	field.camera.look_at(Vector3(0,1,0))
	field.review_camera=false
	await frames(720)
	field.write_report()
	field.finish_run()
