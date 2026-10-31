extends Node3D
## Experimental presentation only: values come from committed costs/actual hits.
const LIFETIME:=1.4
const MAX_LABELS:=32
const COLORS={"stamina":Color("70d5a8"),"magicka":Color("71bfff"),"physical":Color("ff6969")}
var entries:Array[Dictionary]=[]
var serial:=0

func show_amount(actor:Node3D,kind:String,amount:float) -> void:
	if not is_instance_valid(actor) or not COLORS.has(kind) or amount<=0.0001:return
	while entries.size()>=MAX_LABELS:
		entries.pop_front().label.queue_free()
	var label:=Label3D.new()
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=true
	label.font_size=24
	label.pixel_size=0.0085
	label.outline_size=5
	label.modulate=COLORS[kind]
	label.outline_modulate=Color("151b22")
	label.text=("−" if kind!="physical" else "")+"%.1f %s"%[amount,kind]
	add_child(label)
	var height:=0.65 if kind=="stamina" else (0.97 if kind=="magicka" else 0.8)
	var offset:=Vector3((serial%3-1)*0.4,height,0)
	serial+=1
	var entry:Dictionary={"label":label,"actor":weakref(actor),"kind":kind,"amount":amount,"age":0.0,"offset":offset}
	entries.append(entry)
	_place(entry)
	set_process(true)

func _place(entry:Dictionary) -> void:
	var actor:Node3D=entry.actor.get_ref()
	if not is_instance_valid(actor):return
	entry.label.visible=actor.is_visible_in_tree()
	var anchor:Vector3=actor.overhead_tag_position() if actor.has_method("overhead_tag_position") else actor.global_position+Vector3.UP*2.2
	var camera:=get_viewport().get_camera_3d()
	var right:=camera.global_basis.x if is_instance_valid(camera) else Vector3.RIGHT
	entry.label.global_position=anchor+right*entry.offset.x+Vector3.UP*(entry.offset.y+float(entry.age)*0.65)

func _process(delta:float) -> void:
	for index in range(entries.size()-1,-1,-1):
		var entry:Dictionary=entries[index]
		entry.age+=delta
		if entry.age>=LIFETIME or not is_instance_valid(entry.actor.get_ref()):
			entry.label.queue_free()
			entries.remove_at(index)
			continue
		_place(entry)
		var alpha:=1.0-smoothstep(0.2,LIFETIME,float(entry.age))
		entry.label.modulate=Color(COLORS[entry.kind],alpha)
		entry.label.outline_modulate=Color(Color("151b22"),alpha)
	if entries.is_empty():set_process(false)

func clear() -> void:
	for entry in entries:entry.label.queue_free()
	entries.clear()
	set_process(false)
