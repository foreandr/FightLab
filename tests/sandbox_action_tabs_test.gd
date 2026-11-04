extends SceneTree
const Types=preload("res://scripts/animation_store_types.gd")
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 assert(Types.is_airborne({"title":"DiveKick"}))
 assert(Types.is_airborne({"title":"Flying Knee"}))
 assert(not Types.is_airborne({"title":"Chair Punch"}))
 assert(Types.is_grab({"title":"Muay Thai Knee Clinch"}))
 assert(not Types.is_grab({"title":"Throw fireball"}))
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var b=current_scene.animation_browser
 while not b.ready_catalog:await process_frame
 assert(b.type_buttons.keys().size()==8)
 assert(b.find_child("SandboxGrounded",true,false)==null and b.find_child("SandboxAirborne",true,false)==null)
 var airborne:=0;var grabs:=0
 for entry in b.records:
  if Types.is_airborne(entry):airborne+=1;assert(entry._section=="Air")
  if Types.is_grab(entry):grabs+=1;assert(entry._grab)
 b.set_type("Air");assert(b.matches_.size()==airborne and airborne>0)
 b.set_type("Grabs");assert(b.matches_.size()==grabs and grabs>0)
 for kind in ["Movement","Idle","Arm","Leg","Head"]:
  b.set_type(kind)
  for entry in b.matches_:assert(entry.air_state!="Airborne" and not entry._grab and not entry._crouch)
 b.set_type("Crouch");assert(not b.matches_.is_empty())
 var crouches:int=b.matches_.size()
 for entry in b.matches_:assert(Types.is_crouch(entry))
 var row:Container=b.type_buttons.Air.get_parent()
 await process_frame
 assert(row.size.x<=b.size.x+1,"Category tabs overflow sidebar")
 while b.thumbnails.busy or not b.thumbnails.jobs.is_empty():await process_frame
 print("ACTION TABS PASS: ",airborne," airborne records in Air; ",grabs," grab/clinch/grapple records in Grabs; ",crouches," crouch records; no air toggle, no sidebar overflow, regular sections exclude air/grabs")
 quit()
