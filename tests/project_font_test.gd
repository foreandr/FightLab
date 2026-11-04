extends SceneTree
var checked:=0
func _initialize() -> void:call_deferred("run")
func verify_controls(node:Node) -> void:
	if node is Control:
		var font:Font=node.get_theme_font("font")
		assert(font.get_font_name().begins_with("Rajdhani"),"Wrong font at "+str(node.get_path())+": "+font.get_font_name())
		checked+=1
	for child in node.get_children():verify_controls(child)
func capture(name_:String) -> void:
	for i in 3:await process_frame
	verify_controls(current_scene)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/font_"+name_+".png")
func run() -> void:
	assert(load(ProjectSettings.get_setting("gui/theme/custom_font")).get_font_name().begins_with("Rajdhani"))
	change_scene_to_file("res://scenes/home.tscn")
	await capture("home")
	change_scene_to_file("res://scenes/story_opponents.tscn")
	await capture("story")
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	while true:
		await process_frame
		if current_scene!=null and bool(current_scene.get("default_unit_ready")) and not is_instance_valid(current_scene.get("loading_layer")):break
	current_scene.select_group("Spells")
	var b=current_scene.spell_builder
	b.draft_path="user://logs/font_preview_draft.cfg"
	b.preview_preferences_path="user://logs/font_preview_prefs.cfg"
	b.open_projectile_workspace();b.preview_projectile_effect("Fire")
	await capture("spells")
	b.open_fire_shape_picker()
	await capture("shapes")
	# World labels should resolve the same font without per-mode overrides.
	var implicit:=Label3D.new()
	var explicit:=Label3D.new()
	implicit.text="Animation Bot 10 physical"
	explicit.text=implicit.text
	explicit.font=load(ProjectSettings.get_setting("gui/theme/custom_font"))
	root.add_child(implicit);root.add_child(explicit)
	await process_frame
	assert(implicit.generate_triangle_mesh().get_faces()==explicit.generate_triangle_mesh().get_faces(),"3D labels do not inherit the project font")
	print("PROJECT FONT PASSED: Cinzel inherited by ",checked," controls across Home, Story, Create, spell popup and 3D labels")
	quit()
