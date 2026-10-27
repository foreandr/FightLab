extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var total=[0,0,0]
 var runs=[]
 for trial in 3:
  var field=load("res://scenes/main.tscn").instantiate()
  root.add_child(field)
  for f in field.fighters:
   f.rng.seed=27531+f.team*1381+trial*1777
  for i in 10800:
   await physics_frame
  var row={"seed_offset":trial*1777,"wins":field.wins.duplicate(),"knees":field.fighters[2].actions.get("knee",0),"kicks":field.fighters[2].actions.get("front_kick",0)+field.fighters[2].actions.get("round_kick",0)}
  runs.append(row)
  for team in 3:
   total[team]+=field.wins[team]
  field.audio.stop_all()
  field.queue_free()
  for i in 3:
   await physics_frame
 print("BALANCE ",JSON.stringify({"wins":total,"runs":runs}))
 await create_timer(0.2).timeout
 quit()
