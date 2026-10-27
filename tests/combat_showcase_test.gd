extends SceneTree
var showcase: Node3D
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func run() -> void:
	showcase=load("res://scenes/combat_showcase.tscn").instantiate()
	showcase.auto_advance=false
	root.add_child(showcase)
	await frames(4)
	check(showcase.catalog.size()>=50,"Showcase must cover the requested spell, defense, physical and movement variations")
	showcase.toggle_pause()
	var frozen_age: float=showcase.age
	await frames(4)
	check(is_equal_approx(frozen_age,showcase.age),"Pause must hold the showcase instead of advancing the action timer")
	showcase.toggle_pause()
	showcase.toggle_slow()
	check(Engine.time_scale<1,"Slow motion control must change simulation speed")
	showcase.toggle_slow()
	showcase.open_case(-1)
	check(showcase.current==showcase.catalog.size()-1,"Previous must wrap to the last case")
	for index in showcase.catalog.size():
		showcase.open_case(index)
		var entry: Dictionary=showcase.catalog[index]
		check(showcase.title_label.text.contains(entry.title),"The case name must stay visible on screen")
		var visible_count:=0
		for f in showcase.field.fighters:
			visible_count+=int(f.visible)
			check(not f.brain_enabled,"Showcase partners must not run autonomous attacks")
		check(visible_count==2,"Exactly two fighters must be visible in a case")
		await frames(ceili(float(entry.duration)*60)+3)
		var result: Dictionary=showcase.results[-1]
		check(result.id==entry.id,"Each case must produce its own completed contact record")
		match entry.expect:
			"contact": check(result.damage>0,entry.id+": action must really contact its passive target")
			"block": check(result.blocks>0,entry.id+": shield must really intercept/absorb the attack")
			"guard_break": check(result.guard_breaks>0,entry.id+": charged attack must really break the prepared guard")
			"armor": check(result.seen.armor,entry.id+": armor cast must activate")
			"armor_hit": check(result.seen.armor and result.actor_damage>0,entry.id+": incoming attack must really contact the armored fighter")
			"aura": check(result.seen.aura,entry.id+": Overdrive must show its actual buff aura")
			"shield": check(result.seen.shield,entry.id+": the requested shield pose must become active")
			"movement": check(result.seen.movement>0.25,entry.id+": movement must change the fighter position")
			"death": check(result.dead,entry.id+": the lethal attack must actually defeat the target")
		if entry.get("air",false):
			check(result.seen.air,entry.id+": jump variation must actually leave the ground")
		print("SHOWCASE ",JSON.stringify(result))
	if failures.is_empty():
		print("PASS: ",showcase.catalog.size()," real showcase cases, visible names, two passive-controlled actors, contacts/blocks/defenses, navigation, pause and slow motion")
	showcase.field.audio.stop_all()
	showcase.queue_free()
	await frames(3)
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
