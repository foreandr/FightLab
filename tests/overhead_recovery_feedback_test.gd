extends SceneTree
const Timing=preload("res://scripts/ragdoll_recovery_timing.gd")
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var b=s.spell_builder
 while not s.animation_browser.ready_catalog:await process_frame
 b.draft_path="user://logs/overhead_recovery_draft.cfg";b.preview_preferences_path="user://logs/overhead_recovery_preview.cfg"
 b.stop_preview_controls(true);b.set_process(false);b.set_physics_process(false);s.field.set_physics_process(false)
 var actor=s.actor;var cpu=s.target
 s.field.set_combat_numbers(true)
 actor.start_ragdoll(Vector3.BACK*200.0,actor.bone_point("spine_03"))
 actor.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.5
 await process_frame;await process_frame
 var prompt=actor.recovery_prompt
 assert(prompt.visible)
 var expected:Vector2=s.field.camera.unproject_position(actor.overhead_tag_position())-Vector2(100,155)
 assert(prompt.position.distance_to(expected)<0.01,"Recovery prompt is still fixed to screen center")
 var previous:Vector2=prompt.position
 actor.ragdoll.bodies.pelvis.position+=Vector3.RIGHT*0.5
 await process_frame;await process_frame
 assert(prompt.position.distance_to(previous)>1.0,"Prompt did not follow the ragdolled character")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/overhead_recovery_prompt.png")
 actor.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.95
 var space:=InputEventKey.new();space.physical_keycode=KEY_SPACE;space.pressed=true
 b._input(space)
 var numbers=s.field.combat_numbers
 assert(numbers.entries.back().kind=="recovery" and numbers.entries.back().label.text=="RECOVERY")
 assert(numbers.entries.back().actor.get_ref()==actor and numbers.entries.back().color==Color("70d5a8"))
 var count:int=numbers.entries.size();b._input(space)
 assert(numbers.entries.size()==count,"Repeated Space duplicated the success popup")
 await process_frame;await process_frame
 assert(not prompt.visible)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/perfect_recovery_float.png")
 cpu.stamina=100;cpu.start_ragdoll(Vector3.BACK*200.0,cpu.bone_point("spine_03"))
 cpu.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.75
 await process_frame;await process_frame
 assert(is_instance_valid(cpu.recovery_prompt) and cpu.recovery_prompt.visible,"CPU has no overhead timing indicator")
 assert(cpu.try_quick_recovery()=="Recovered")
 var entry:Dictionary=numbers.entries.back()
 assert(entry.kind=="recovery" and entry.label.text=="RECOVERY" and entry.actor.get_ref()==cpu and entry.color==Color("70d5a8"))
 var height:float=entry.label.global_position.y
 numbers._process(0.6)
 assert(entry.label.global_position.y>height and entry.label.modulate.a<1.0,"Recovery text does not use floating/fading number presentation")
 s.field.set_combat_numbers(false)
 assert(numbers.entries.is_empty())
 cpu.reset_fighter(cpu.position);cpu.start_ragdoll(Vector3.BACK*200.0,cpu.bone_point("spine_03"));cpu.recovery_timing.age=Timing.OPPORTUNITY_DELAY+Timing.WINDOW*0.95
 assert(cpu.try_quick_recovery()=="Recovered" and numbers.entries.is_empty(),"Disabled Numbers still displays recovery text")
 s.field.set_combat_numbers(true)
 s.field.show_combat_number(actor,"physical",10.0)
 s.field.show_combat_number(actor,"stamina",5.0)
 s.field.show_combat_number(actor,"physical",20.0,true)
 assert(numbers.entries[-3].label.text=="10.0 physical" and numbers.entries[-2].label.text=="−5.0 stamina" and numbers.entries[-1].label.text=="HEADSHOT 20","Recovery text changed numeric formatting")
 for i in 50:s.field.show_recovery_feedback(cpu,"Recovered")
 assert(numbers.entries.size()==numbers.MAX_LABELS,"Recovery text bypasses the bounded floating-label pool")
 s.field.set_combat_numbers(false)
 print("OVERHEAD RECOVERY PASS: immediate opportunity, player/CPU stamina prompts follow body, Space route, single recovery colored floating feedback, fade and F2 silence")
 while s.animation_browser.thumbnails.busy or not s.animation_browser.thumbnails.jobs.is_empty():await process_frame
 quit()
