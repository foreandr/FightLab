extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func frames(count: int=4) -> void:
	for i in count:await physics_frame
func escape() -> InputEventKey:
	var key:=InputEventKey.new()
	key.keycode=KEY_ESCAPE
	key.pressed=true
	return key
func run() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/home.tscn","Default launch must be Home")
	var home=load("res://scenes/home.tscn").instantiate()
	root.add_child(home)
	current_scene=home
	await frames()
	check(home.navigation_buttons.has_all(["Story","Fight","Create"]),"Home must offer Story, Fight and Create")
	home.navigation_buttons.Story.pressed.emit()
	check(home.page=="Story" and home.navigation_buttons.has("Back"),"Story must have an honest placeholder and a way back")
	home.navigation_buttons.Back.pressed.emit()
	home.navigation_buttons.Create.pressed.emit()
	check(home.navigation_buttons.has_all(["Animations","Spells","Back"]),"Create must offer Animations and Spells")
	home.navigation_buttons.Animations.pressed.emit()
	await frames()
	var animations=current_scene
	check(animations.editor_section=="Animations" and animations.title_label.text.contains("ANIMATIONS"),"Animations must open the current animation editor with its new name")
	check(animations.chosen_steps().is_empty() and animations.chain_chips.is_empty(),"Animations should open with a blank chain")
	for node in animations.find_children("*","Button",true,false):
		check(node.text not in ["Quick dash","Dash only","Dash → Knee","Jump → Flip → Twist"],"Removed controls must not remain in the editor")
	animations.set_chain(["Dash","Jump","Flip","Land"])
	check(animations.chosen_steps()==["Dash","Jump","Flip","Land"],"Users must still be able to construct their own motion chains")
	animations.return_home()
	await frames()
	home=current_scene
	check(not paused and Engine.time_scale==1,"Returning Home must restore the menu after paused editing")
	home.navigation_buttons.Create.pressed.emit()
	home.navigation_buttons.Spells.pressed.emit()
	await frames()
	var spells=current_scene
	check(spells.editor_section=="Spells" and spells.title_label.text.contains("SPELLS"),"Spells must open the focused spell testing workspace")
	check(not spells.chain_panel.visible,"Spell workspace must not display the animation-chain builder")
	for node in spells.find_children("*","Button",true,false):
		check(node.text not in ["Pause [Space]","Run [Space]","Resume [Space]","Reframe [F]","Fight [B]"],"Spell Create must also omit the removed bottom controls")
	spells.toggle_slow()
	check(spells.slow_button.text=="Normal [T]","Slow control must still update without a Space button")
	spells.toggle_slow()
	for id in ["fireball_ground","cinder_slash_ground","freezing_ray_ground","armor_ground","overdrive_ground","flash_ground"]:
		check(spells.moves.any(func(entry):return entry.id==id),"Spell workspace missing "+id)
	spells._unhandled_key_input(escape())
	await frames()
	home=current_scene
	home.navigation_buttons.Fight.pressed.emit()
	await frames()
	check(current_scene.fighters.size()==3,"Fight must open the existing three-way arena")
	current_scene._unhandled_key_input(escape())
	await frames()
	check(current_scene.page=="Home","Escape from Fight must return Home")
	current_scene.queue_free()
	await frames()
	if failures.is_empty():print("PASS: default Home, Story/Back, Create/Animations/Spells, blank chains, removed controls, Fight and return navigation")
	quit(0 if failures.is_empty() else 1)
