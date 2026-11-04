extends SceneTree
const Pose=preload("res://scripts/spell_cast_motion.gd")
const Locomotion=preload("res://scripts/creation_locomotion.gd")
const Type=preload("res://scripts/animation_cast_type.gd")
var b
var a
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func space(pressed:bool):
 var event:=InputEventKey.new();event.keycode=KEY_SPACE;event.physical_keycode=KEY_SPACE;event.pressed=pressed
 b._input(event)
func step(delta:float):
 a.tick(delta);b.move_caster(delta,Vector2.ZERO,false);b.process_demo_preview(delta)
func settle():
 b.stop_preview_controls(true);b.playing=false
 for i in 140:step(0.016)
 assert(a.is_on_floor())
func hop(hold:float)->Vector2:
 settle();a.stamina=100
 var spent:float=a.stamina_spent;var ground:float=a.position.y;var peak:=0.0;var air:=false
 space(true);assert(a.mode=="takeoff")
 # Key repeats cannot spend again or restart takeoff.
 var cost:float=a.stamina_spent;space(true);assert(a.stamina_spent==cost)
 for i in 150:
  if float(i)*0.016>=hold:space(false)
  step(0.016);peak=maxf(peak,a.position.y-ground)
  if not a.is_on_floor():air=true
  if air and a.is_on_floor():break
 assert(air and a.is_on_floor(),"Space jump failed to leave floor and land")
 return Vector2(peak,a.stamina_spent-spent)
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;b=s.spell_builder;a=s.actor
 while not s.animation_browser.ready_catalog:await process_frame
 s.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 a.practice_god_mode=false
 var short:=hop(0.0);var full:=hop(0.5)
 assert(full.x>short.x and full.y>short.y)
 assert(is_equal_approx(short.y,4.0) and is_equal_approx(full.y,12.0))
 settle();space(true)
 for i in 15:step(0.016)
 assert(not a.is_on_floor())
 var entry:Dictionary={"title":"Backfist","clip":"fight/backfist","step":"Imported Motion","store_raw":true,"duration":1.0,"source_duration":1.0,"animation_type":"Arm","sandbox_animation":true}
 b.demo_duration=1.0;assert(b.choose_demo_animation(entry,false));b.play_demo_preview();b.process_demo_preview(0.1)
 assert(b.playing and not a.is_on_floor(),"Starting cast canceled jump")
 var before:Array[Transform3D]=Pose.capture(a)
 assert(Locomotion.jump_pose(a,true))
 for i in a.skeleton.get_bone_count():
  if not Locomotion.is_locomotion_bone(a.skeleton,i):assert(a.skeleton.get_bone_pose(i).is_equal_approx(before[i]),"Jump overwrote casting upper body")
 assert(not Type.owns_legs({"animation_type":"Movement","delivery_type":"Projectile"}))
 assert(Type.owns_legs({"animation_type":"Movement","delivery_type":"Touch"}))
 space(false);settle()
 b.play_demo_preview();b.process_demo_preview(0.1);space(true)
 assert(b.playing and a.mode=="takeoff","Jump canceled a running preview")
 for i in 15:step(0.016)
 assert(b.playing and not a.is_on_floor(),"Preview prevented shared jump takeoff")
 space(false);settle();a.stamina=3;space(true);assert(a.mode!="takeoff")
 while s.animation_browser.thumbnails.busy or not s.animation_browser.thumbnails.jobs.is_empty():await process_frame
 print("SANDBOX JUMP PASS: Space tap/hold height and 4/12 stamina, duplicate/low-stamina rejection, landing, cast in air, upper body preserved, Touch-only movement ownership unchanged")
 quit()
