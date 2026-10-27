extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:await physics_frame
func check_tag(fighter: CharacterBody3D,name_: String) -> Node3D:
	var tag:=fighter.get_node_or_null("OverheadHealthTag")
	check(tag!=null and tag.visible,"Every visible fighter must keep its overhead tag: "+name_)
	if tag==null:return null
	check(tag.display_name.contains(name_),"Overhead tag must identify the character: "+name_)
	check(tag.get_node("CurrentHealth").text.contains("HP"),"Overhead tag must display current and maximum HP")
	check(tag.get_node("HealthFill") is MeshInstance3D,"Overhead tag must include a graphical health bar")
	return tag
func run() -> void:
	var fight=load("res://scenes/main.tscn").instantiate()
	root.add_child(fight)
	await frames(4)
	check(fight.fighters.size()==3,"Free-for-all must retain all three fighters")
	var first: Node3D=check_tag(fight.fighters[0],"FIRE")
	var second: Node3D=check_tag(fight.fighters[1],"ICE")
	var third: Node3D=check_tag(fight.fighters[2],"STORM")
	var initial: Vector3=first.global_position
	fight.fighters[0].health=fight.fighters[0].MAX_HEALTH/2
	fight.fighters[0].position.x+=1
	await frames(2)
	check(first.get_node("CurrentHealth").text.contains("80 / 160"),"HP text must update as health changes")
	check(first.get_node("HealthFill").mesh.size.x>0.60 and first.get_node("HealthFill").mesh.size.x<0.66,"Health bar must shrink with health")
	check(first.global_position.x>initial.x+0.8,"Overhead labels must follow fighter movement")
	fight.fighters[0].health=0
	await frames(2)
	check(first.visible and first.get_node("CurrentHealth").text.contains("0 / 160"),"Healthbars must remain visible after knockout")
	check(second.visible and third.visible,"Every living fighter must retain its name and bar")
	fight.fighters[0].health=160
	fight.queue_free()
	await frames(2)
	var create=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(create)
	await frames(4)
	check_tag(create.actor,"FIRE")
	check_tag(create.target,"STORM")
	check(not create.field.fighters[1].get_node("OverheadHealthTag").visible,"Hidden preview mannequins must keep their tags hidden with them")
	paused=false
	create.queue_free()
	await frames(2)
	if failures.is_empty():print("PASS: persistent floating names and HP bars on all three fight mannequins and both visible Create preview fighters; changing HP and knockout remain visible")
	quit(0 if failures.is_empty() else 1)
