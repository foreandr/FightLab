extends Node3D
## Review-only animation arena. Ratings never alter gameplay or delete source assets.
const BASE := "res://assets/combat/animations/"
const SOURCES := {
	"ual1":{"file":"UAL1_Standard.glb","author":"Quaternius / online","url":"https://quaternius.itch.io/universal-animation-library"},
	"ual2":{"file":"UAL2_Standard.glb","author":"Quaternius / online","url":"https://quaternius.itch.io/universal-animation-library-2"},
	"editor":{"file":"editor_attacks.res","author":"FightLab / custom authored","url":""},
	"duel":{"file":"duel.res","author":"FightLab / custom authored","url":""},
	"boxing":{"file":"boxing.res","author":"FightLab / custom authored","url":""},
	"spells":{"file":"spells.res","author":"FightLab / custom authored","url":""},
}
var store := preload("res://scripts/pavlov_store.gd").new()
var candidates: Array[Dictionary]=[]
var queue: Array[Dictionary]=[]
var current: Dictionary={}
var index := 0
var animator: AnimationPlayer
var camera: Camera3D
var heading: Label
var details: Label
var status: Label
var counts: Label
var filter: OptionButton
var category: OptionButton
var good_button: Button
var bad_button: Button
var pause_button: Button
var camera_angle := 0.5
var camera_controls := preload("res://scripts/sandbox_camera.gd").new()
var camera_dragging := false
var speed := 1.0
var slow_button: Button
var sync_elapsed := 0.0

func _process(delta: float) -> void:
	if camera_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):camera_dragging=false
	if not _camera_text_editing():
		var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S)))
		_move_camera(direction,delta,Input.is_physical_key_pressed(KEY_SHIFT))
	sync_elapsed+=delta
	if sync_elapsed<1.0:return
	sync_elapsed=0.0
	var path := store.directory+"/reviews.cfg"
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)==store.revision:return
	var selected_id: String=str(current.get("id",""))
	store.load_reviews()
	_rebuild_queue()
	for n in range(queue.size()):
		if queue[n].id==selected_id:
			_open(n)
			break

func _ready() -> void:
	get_tree().paused=false
	Engine.time_scale=1.0
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	store.load_reviews()
	_build_arena()
	_build_ui()
	_build_candidates()
	_rebuild_queue()

func _build_arena() -> void:
	var environment := WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("18232e")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE
	environment.environment.ambient_light_energy=0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-45,-35,0)
	light.light_energy=1.2
	add_child(light)
	var floor := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius=5
	mesh.bottom_radius=5
	mesh.height=0.12
	floor.mesh=mesh
	floor.position.y=-0.06
	var material := StandardMaterial3D.new()
	material.albedo_color=Color("6e746b")
	floor.material_override=material
	add_child(floor)
	var model=(load("res://assets/characters/base/Superhero_Male_FullBody.gltf") as PackedScene).instantiate()
	add_child(model)
	for node in model.find_children("*","MeshInstance3D",true,false):
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color=Color("d6c3a4")
		node.material_override=fallback
	animator=AnimationPlayer.new()
	model.add_child(animator)
	animator.animation_finished.connect(func(_clip):animator.play("preview/clip"))
	camera=Camera3D.new()
	camera.current=true
	camera.fov=40
	add_child(camera)
	_update_camera()

func _update_camera() -> void:
	if not camera_controls.manual:
		camera.position=Vector3(sin(camera_angle)*5.4,2.4,cos(camera_angle)*5.4)
		camera.look_at(Vector3(0,1.0,0))
		camera_controls.capture_view(camera,camera.position.distance_to(Vector3(0,1.0,0)))
	camera_controls.yaw=camera_angle
	camera_controls.apply(camera)

func _camera_text_editing() -> bool:
	return get_viewport().gui_get_focus_owner() is LineEdit or (filter!=null and filter.get_popup().visible) or (category!=null and category.get_popup().visible)

func _move_camera(direction: Vector3, delta: float, fast := false) -> void:
	if direction.is_zero_approx():return
	camera_controls.move(direction,delta,fast)
	camera_controls.apply(camera)

func _orbit_camera(relative: Vector2) -> void:
	camera_controls.orbit(relative)
	camera_angle=camera_controls.yaw
	camera_controls.apply(camera)

func _zoom_camera(steps: float) -> void:
	camera_controls.zoom(steps)
	camera_controls.apply(camera)

func _reset_camera() -> void:
	camera_controls.manual=false
	camera_angle=0.5
	_update_camera()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_MIDDLE and not event.pressed:
		camera_dragging=false
	elif event is InputEventMouseMotion and camera_dragging:
		_orbit_camera(event.relative)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_MIDDLE:
			camera_dragging=true
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			_zoom_camera(1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1)
		else:return
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:camera_dragging=false

func _build_candidates() -> void:
	DirAccess.make_dir_recursive_absolute(store.directory+"/clips")
	for source_id in SOURCES:
		var source: Dictionary=SOURCES[source_id]
		var library := load(BASE+str(source.file)) as AnimationLibrary
		if library == null:continue
		for clip_name in library.get_animation_list():
			if clip_name in ["RESET","A_TPose"]:continue
			var animation := library.get_animation(clip_name)
			_add_candidate(animation,str(source_id)+" / "+clip_name,source,_category(clip_name))
	# Authored experiments stay separate from their imported baselines.
	var experiments := [
		["ual1","Spell_Simple_Shoot","Spell cast · stronger torso follow-through","spine_02",Vector3.UP,18.0,"Spellcasting"],
		["ual2","OverhandThrow","Overhand throw · torso wind-up","spine_02",Vector3.UP,-22.0,"Throwing"],
		["ual1","Sprint","Sprint · forward drive","spine_01",Vector3.RIGHT,8.0,"Sprinting"],
	]
	for experiment in experiments:
		var source: Dictionary=SOURCES[experiment[0]]
		var library := load(BASE+str(source.file)) as AnimationLibrary
		if library==null or not library.has_animation(experiment[1]):continue
		var animation := library.get_animation(experiment[1]).duplicate(true) as Animation
		var changed := false
		for track in range(animation.get_track_count()):
			if animation.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
			if not str(animation.track_get_path(track)).ends_with(":"+str(experiment[3])):continue
			for key in range(animation.track_get_key_count(track)):
				var time := animation.track_get_key_time(track,key)
				var envelope := sin(PI*time/maxf(animation.length,0.01))
				if experiment[6]=="Sprinting":envelope=1.0
				var rotation: Quaternion=animation.track_get_key_value(track,key)
				animation.track_set_key_value(track,key,rotation*Quaternion(experiment[4],deg_to_rad(experiment[5])*envelope))
				changed=true
		if changed:
			_add_candidate(animation,experiment[2],{"author":"FightLab / authored variant of "+experiment[0]+" / "+experiment[1],"url":source.url},experiment[6])
	# Recover previously reviewed candidates even when upstream files change.
	for id in store.records:
		if not candidates.any(func(entry):return entry.id==id):
			candidates.append(store.records[id].duplicate(true))
	candidates.sort_custom(func(a,b):return ("0" if a.category=="Spellcasting" else "1")+a.title < ("0" if b.category=="Spellcasting" else "1")+b.title)

func _category(clip: String) -> String:
	var lower := clip.to_lower()
	for pair in [["Spellcasting",["cast","spell","magic","palm"]],["Sprinting",["sprint"]],["Jogging",["jog"]],["Running",["run"]],["Walking",["walk"]],["Punching",["punch","jab","cross","hook","uppercut","elbow"]],["Kicking",["kick","knee","stomp","sweep"]],["Throwing",["throw"]],["Blocking",["block","guard","shield","brace"]]]:
		for word in pair[1]:
			if lower.contains(word):return pair[0]
	return "Other"

func _add_candidate(animation: Animation, title: String, source: Dictionary, group: String) -> void:
	# Save once by content hash: the reviewed animation is an immutable snapshot.
	var temporary := store.directory+"/candidate-"+str(OS.get_process_id())+".tres"
	if ResourceSaver.save(animation,temporary) != OK:return
	var id := FileAccess.get_sha256(temporary)
	var path := store.directory+"/clips/"+id+".tres"
	if not FileAccess.file_exists(path):
		if DirAccess.copy_absolute(temporary,path) != OK:return
	if candidates.any(func(entry):return entry.id==id):return
	candidates.append({"id":id,"title":title,"category":group,"source":source.author,"source_url":source.url,"resource":path,"license":"CC0-1.0" if str(source.author).contains("Quaternius") else "Project asset"})

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,18)
	canvas.add_child(margin)
	margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var layout := VBoxContainer.new()
	layout.mouse_filter=Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	heading=Label.new()
	heading.clip_text=true
	heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.add_theme_font_size_override("font_size",24)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	_button(top,"Back to Dev",func():get_tree().set_meta("return_to_dev",true);get_tree().change_scene_to_file("res://scenes/home.tscn"))
	details=Label.new()
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(details)
	var tools := HBoxContainer.new()
	layout.add_child(tools)
	filter=OptionButton.new()
	for text in ["Unreviewed","Good pile","Bad pile","All"]:filter.add_item(text)
	filter.item_selected.connect(func(_selected):_rebuild_queue())
	tools.add_child(filter)
	category=OptionButton.new()
	for text in ["All categories","Spellcasting","Walking","Jogging","Running","Sprinting","Punching","Kicking","Throwing","Blocking","Other"]:category.add_item(text)
	category.item_selected.connect(func(_selected):_rebuild_queue())
	tools.add_child(category)
	_button(tools,"Turn left",func():camera_angle-=PI/4;_update_camera())
	_button(tools,"Turn right",func():camera_angle+=PI/4;_update_camera())
	_button(tools,"Reset view [F]",_reset_camera)
	pause_button=_button(tools,"Pause",_pause)
	var slow := Button.new()
	slow_button=slow
	slow.toggle_mode=true
	slow.text="Slow motion: Off"
	slow.toggled.connect(func(on):speed=0.4 if on else 1.0;animator.speed_scale=speed;slow.text="Slow motion: On" if on else "Slow motion: Off")
	tools.add_child(slow)
	counts=Label.new()
	layout.add_child(counts)
	var spacer := Control.new()
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layout.add_child(spacer)
	var keyboard_hint := Label.new()
	keyboard_hint.text="Camera: WASD move · Q/E up/down · Middle-drag rotate · Wheel / PgUp/PgDn zoom · Shift+arrows rotate · F reset\nY: good · X/N: bad · ←/→: previous/next · P: pause · T: slow · Z: undo · 1–4: piles · C: category · F10: all actions"
	keyboard_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(keyboard_hint)
	status=Label.new()
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)
	var votes := HBoxContainer.new()
	votes.alignment=BoxContainer.ALIGNMENT_CENTER
	layout.add_child(votes)
	_button(votes,"Previous",func():_open(index-1))
	bad_button=_button(votes,"✕  BAD",func():_vote("bad"))
	bad_button.modulate=Color("ff7777")
	good_button=_button(votes,"✓  GOOD",func():_vote("good"))
	good_button.modulate=Color("78ef9a")
	_button(votes,"Skip / Next",func():_open(index+1))
	_button(votes,"Undo vote",_undo)

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text=text
	button.custom_minimum_size=Vector2(100,44)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _rebuild_queue() -> void:
	queue.clear()
	var good := 0
	var bad := 0
	for entry in candidates:
		var verdict: String=str(store.records.get(entry.id,{}).get("verdict",""))
		if verdict=="good":good+=1
		if verdict=="bad":bad+=1
		if category.selected>0 and entry.category!=category.get_item_text(category.selected):continue
		if filter.selected==0 and verdict!="":continue
		if filter.selected==1 and verdict!="good":continue
		if filter.selected==2 and verdict!="bad":continue
		queue.append(entry)
	counts.text="Unreviewed: %d   |   Good: %d   |   Bad: %d" % [candidates.size()-good-bad,good,bad]
	_open(0)

func _open(next: int) -> void:
	animator.stop()
	var skeleton := animator.get_parent().find_child("Skeleton3D",true,false) as Skeleton3D
	if skeleton!=null:skeleton.reset_bone_poses()
	current={}
	good_button.disabled=true
	bad_button.disabled=true
	if queue.is_empty():
		heading.text="ANIMATION PAVLOV · No animations in this pile"
		details.text="Choose another pile or category. Your votes and animations stay stored."
		return
	index=posmod(next,queue.size())
	current=queue[index]
	heading.text="%d / %d · %s" % [index+1,queue.size(),current.title]
	details.text="%s · %s · %s\nLooping preview. X rejects; the green check approves. Both keep the animation." % [current.category,current.source,str(store.records.get(current.id,{}).get("verdict","Unreviewed"))]
	var animation := load(current.resource) as Animation
	if animation==null:
		status.text="Could not load this animation. Voting disabled."
		return
	if animator.has_animation_library("preview"):animator.remove_animation_library("preview")
	var library := AnimationLibrary.new()
	library.add_animation("clip",animation.duplicate(true))
	animator.add_animation_library("preview",library)
	animator.speed_scale=speed
	animator.play("preview/clip")
	pause_button.text="Pause"
	good_button.disabled=false
	bad_button.disabled=false

func _vote(verdict: String) -> void:
	if current.is_empty() or good_button.disabled:return
	var old_index := index
	if store.vote(current,verdict)!=OK:
		status.text="Vote could not be saved. Please try again; this candidate has not changed."
		return
	status.text="Saved to the %s pile. The exact animation is preserved." % verdict
	_rebuild_queue()
	if not queue.is_empty():_open(old_index if filter.selected!=3 else old_index+1)

func _undo() -> void:
	if store.undo()==OK:
		status.text="Last vote undone."
		_rebuild_queue()
	else:status.text="No vote to undo, or the save could not be updated."

func _pause() -> void:
	if animator.is_playing():
		animator.pause()
		pause_button.text="Resume"
	else:
		animator.play()
		pause_button.text="Pause"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.shift_pressed and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
			_orbit_camera(Vector2(-15 if event.keycode==KEY_LEFT else (15 if event.keycode==KEY_RIGHT else 0),-15 if event.keycode==KEY_UP else (15 if event.keycode==KEY_DOWN else 0)))
			get_viewport().set_input_as_handled()
			return
		match event.keycode:
			KEY_Y:_vote("good")
			KEY_X,KEY_N:_vote("bad")
			KEY_LEFT:_open(index-1)
			KEY_RIGHT:_open(index+1)
			KEY_PAGEUP:_zoom_camera(1)
			KEY_PAGEDOWN:_zoom_camera(-1)
			KEY_F:_reset_camera()
			KEY_P:_pause()
			KEY_T:slow_button.button_pressed=not slow_button.button_pressed
			KEY_Z:_undo()
			KEY_1,KEY_2,KEY_3,KEY_4:
				filter.select(event.keycode-KEY_1)
				_rebuild_queue()
			KEY_C:
				category.select(posmod(category.selected+(-1 if event.shift_pressed else 1),category.item_count))
				_rebuild_queue()
			KEY_ESCAPE:
				get_tree().set_meta("return_to_dev",true)
				get_tree().change_scene_to_file("res://scenes/home.tscn")
			_:return
		get_viewport().set_input_as_handled()
