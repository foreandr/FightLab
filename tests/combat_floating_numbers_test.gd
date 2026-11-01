extends SceneTree
const Burn=preload("res://scripts/burn_rules.gd")
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("COMBAT NUMBERS FAILED: "+message)
	quit(1)
	return false
func press_three(builder:Node,echo:bool=false,ctrl:bool=false) -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_3;event.physical_keycode=KEY_3
	event.pressed=true;event.echo=echo;event.ctrl_pressed=ctrl
	builder._input(event)
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/numbers_draft.cfg"
	b.preview_preferences_path="user://logs/numbers_preview.cfg"
	b.open_projectile_workspace()
	b.set_process(false);b.set_physics_process(false)
	editor.field.set_physics_process(false)
	b.select_demo_choice("cross",false)
	b.set_release_fraction(0.55)
	b.stop_preview_controls();b.clear_shots()
	var field=editor.field
	var actor=editor.actor
	b.set_character_god_mode(actor,false)
	b.set_character_god_mode(editor.target,true)
	editor.target.guard_energy=0;editor.target.invulnerability=0
	actor.mana=100;actor.stamina=100
	if not check(not field.combat_numbers_visible and not b.combat_numbers_button.button_pressed,"Experimental numbers should start off"):return
	press_three(b)
	if not check(field.combat_numbers_visible and b.combat_numbers_button.button_pressed,"3 does not toggle the button/world together"):return
	press_three(b,true);press_three(b,false,true)
	if not check(field.combat_numbers_visible,"Echo or Ctrl+3 toggles numbers"):return
	b.manual_aim=true;b.manual_aim_valid=true
	b.manual_aim_point=editor.target.bone_point("spine_03")
	b.play_demo_preview();b.process_demo_preview(0.385);b.play_demo_preview()
	var numbers=field.combat_numbers
	if not check(numbers.entries.size()==1 and numbers.entries[0].kind=="stamina" and is_equal_approx(numbers.entries[0].amount,7.0),"Canceled spell did not display its actual partial cost"):return
	numbers.clear()
	b.process_demo_preview(0.55)
	if not check(numbers.entries.size()==2 and actor.stamina==83 and is_equal_approx(actor.mana,100.0-float(b.demo_preview_spec().mana)),"Cast labels duplicate or disagree with committed resource costs"):return
	var kinds:Dictionary={}
	for entry in numbers.entries:
		kinds[entry.kind]=entry.amount
		if not check(entry.actor.get_ref()==actor,"Cost floats over the wrong actor"):return
	if not check(is_equal_approx(kinds.stamina,10.0) and is_equal_approx(kinds.magicka,float(b.demo_preview_spec().mana)),"Successful spell cost labels are wrong"):return
	var before:float=editor.target.damage_taken
	var expected_damage:float=field.shots.back().spec.damage
	for frame in 100:
		field.step_shots(1.0/60.0)
		if field.shots.is_empty():break
	var received:float=editor.target.damage_taken-before
	if not check(numbers.entries.size()==3 and numbers.entries.back().kind=="physical" and is_equal_approx(numbers.entries.back().amount,received) and is_equal_approx(received,expected_damage) and numbers.entries.back().actor.get_ref()==editor.target,"Damage label is not the actual hit on the immortal victim"):return
	b.update_training_dummy(0.016)
	if not check(is_equal_approx(b.dummy_last_damage,received),"Removing duplicate popup broke last spell damage readout"):return
	for child in field.get_children():
		if not check(not (child is Label3D),"Dummy-only untyped damage popup still exists alongside typed physical number"):return
	editor.target.receive_status(actor,{"projectile_element":"Fire","potency":2.0})
	field.round_active=true
	editor.target.update_status(0.5)
	if not check(numbers.entries.size()==4 and numbers.entries.back().kind=="burn" and is_equal_approx(numbers.entries.back().amount,2.0*Burn.TICK_DAMAGE) and numbers.entries.back().label.text=="%.1f burn"%(2.0*Burn.TICK_DAMAGE) and numbers.entries.back().color==numbers.COLORS.burn,"Actual burn tick is missing its red typed number"):return
	var initial_y:float=numbers.entries[0].label.global_position.y
	numbers._process(0.6)
	if not check(numbers.entries[0].label.global_position.y>initial_y and numbers.entries[0].label.modulate.a<1 and numbers.entries[0].label.modulate.a>0,"Numbers do not float and fade"):return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/combat_numbers.png")
	numbers._process(2.0)
	if not check(numbers.entries.is_empty() and not numbers.is_processing(),"Expired numbers keep rendering/processing"):return
	for index in 50:field.show_combat_number(editor.target,"physical",1)
	if not check(numbers.entries.size()==numbers.MAX_LABELS,"Spam is not bounded"):return
	press_three(b)
	if not check(not field.combat_numbers_visible and numbers.entries.is_empty(),"3 off did not remove existing numbers"):return
	actor.spend_stamina(1)
	if not check(numbers.entries.is_empty(),"Disabled numbers still spawn labels"):return
	press_three(b)
	field.show_combat_number(editor.target,"physical",1)
	b.reset_practice_scene()
	if not check(numbers.entries.is_empty() and field.combat_numbers_visible,"Reset leaves stale numbers or changes the toggle"):return
	print("COMBAT NUMBERS PASSED: 3/button toggle, guards, actual cancel/full cast costs, actual physical damage on immortal target, actor anchors, floating/fading/lifetime, bounded spam, disabled silence and reset cleanup")
	quit()
