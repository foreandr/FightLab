extends SceneTree
var lab: Node3D
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func run() -> void:
	lab=load("res://scenes/combat_sandbox.tscn").instantiate()
	root.add_child(lab)
	lab.camera_input_enabled=false
	for attack in lab.sequence.ATTACKS:
		lab.set_chain(["Jump",attack,"Land"])
		check(lab.chosen_steps()==["Jump",attack,"Land"],"Airborne attack must stay selectable: "+attack)
		lab.run_setup()
		var attacked_in_air:=false
		for i in 240:
			await physics_frame
			if lab.sequence.history.has(attack) and not lab.actor.is_on_floor():attacked_in_air=true
		check(attacked_in_air,"Attack must begin before landing: "+attack)
		check(lab.sequence.status=="Combo complete" and lab.actor.is_on_floor(),"Air attack must finish and land: "+attack)
	for attack in ["Spell Throw","Slash Throw","Punch","Knee"]:
		lab.set_chain(["Jump","Twist",attack,"Land"])
		lab.run_setup()
		var overlapped:=false
		var released_during_turn:=false
		var anticipation:=false
		var arm_motion:=0.0
		var previous:=Quaternion.IDENTITY
		var samples:=0
		for i in 240:
			await physics_frame
			var f=lab.actor
			if f.twist_age>=0 and f.twist_age<f.TWIST_DELAY:
				anticipation=true
				check(absf(f.model.rotation.y)<0.001,"Twist must hold its anticipation pose")
			if f.twist_age>=f.TWIST_DELAY and f.twist_age<f.TWIST_DELAY+f.TWIST_DURATION and f.mode in ["cast","punch"]:
				overlapped=true
				var pose: Quaternion=f.skeleton.get_bone_pose_rotation(f.bones["upperarm_r"])
				if samples>0:arm_motion+=previous.angle_to(pose)
				previous=pose
				samples+=1
				if f.mode=="cast" and f.did_release:released_during_turn=true
		check(anticipation and overlapped and arm_motion>0.1,"Twist must anticipate and overlap a moving attack pose: "+attack)
		if attack in ["Spell Throw","Slash Throw"]:check(released_during_turn,"Projectile must release during the actual turn: "+attack)
		check(lab.sequence.status=="Combo complete" and lab.actor.is_on_floor() and lab.actor.twist_age<0,"Overlap must complete without hovering: "+attack)
	lab.set_chain(["Jump","Twist","Spell Throw"])
	lab.run_setup()
	while lab.actor.twist_age<0:await physics_frame
	lab.reset_setup()
	check(lab.actor.twist_age<0 and is_zero_approx(lab.actor.model.rotation.y),"Reset must remove the twist layer")
	paused=false
	lab.queue_free()
	await physics_frame
	if failures.is_empty():print("PASS: all nine airborne attacks, delayed slower twist, concurrent cast/melee poses, real projectile release during spin, gravity and reset")
	quit(0 if failures.is_empty() else 1)
