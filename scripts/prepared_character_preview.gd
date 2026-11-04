extends RefCounted
## A bounded RAM cache of finished preview rigs. Never used by combat actors.
const Key=preload("res://scripts/character_appearance_key.gd")
static var scenes: Dictionary={}
static var order: Array[String]=[]
static var hits:=0
static var builds:=0
static func get_scene(profile: Dictionary) -> PackedScene:
	var key:=Key.make(profile)
	if scenes.has(key): hits+=1;return scenes[key]
	return null
static func store(profile: Dictionary,model: Node3D) -> void:
	var key:=Key.make(profile)
	if scenes.has(key):return
	# Imported nodes and dynamically fitted clothes must all belong to this rig.
	for node in model.find_children("*","",true,false):node.owner=model
	var packed:=PackedScene.new()
	if packed.pack(model)!=OK:return
	while order.size()>=8: scenes.erase(order.pop_front())
	scenes[key]=packed;order.append(key);builds+=1
