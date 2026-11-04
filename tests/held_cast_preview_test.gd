extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 change_scene_to_file("res://scenes/sandbox.tscn");await process_frame;await process_frame
 var s=current_scene;var b=s.spell_builder;var browser=s.animation_browser
 while not browser.ready_catalog:await process_frame
 assert(not browser.confirm.visible and b.projectile_preview_button.get_parent().get_node("PracticeRightJab").visible)
 var jab_key:=InputEventKey.new();jab_key.physical_keycode=KEY_4;jab_key.pressed=true
 b._input(jab_key);assert(s.actor.mode!="punch","Removed Jab shortcut remains active")
 s.field.set_physics_process(false);b.set_process(false);b.set_physics_process(false)
 var entry:Dictionary={}
 for record in browser.records:
  if record._origin=="Built-in" and record.clip=="fight/backfist":entry=record;break
 assert(browser.select_animation(entry))
 b.stop_preview_controls(true)
 b.casting_animation.source_duration=1.0;b.casting_animation.min_duration=0.7;b.casting_animation.max_duration=1.6
 b.choose_delivery_type("Projectile");b.confirm_delivery_type()
 b.stop_preview_controls(true);b.clear_shots()
 for i in 30:b.move_caster(0.016,Vector2.ZERO,false)
 assert(s.actor.is_on_floor())
 assert(not s.field.combat().can_start_cast(s.actor,{"requires_air":true,"stamina_cost":0}))
 s.actor.position.y+=2.0;b.move_caster(0.016,Vector2.ZERO,false)
 assert(s.field.combat().can_start_cast(s.actor,{"requires_air":true,"stamina_cost":0}))
 for i in 120:b.move_caster(0.016,Vector2.ZERO,false)
 s.actor.stamina=100;s.actor.mana=100
 root.grab_focus();await process_frame
 var timeline=b.get_meta("cast_timeline")
 assert(not timeline.release_handle.visible,"Held casts still expose a late release grip")
 var before:float=b.release_fraction
 timeline.set_at_position("release",timeline.time_x(0.55))
 assert(is_equal_approx(b.release_fraction,before),"Hidden release grip still edits timing")
 b.release_fraction=0.55 # A saved late cast setting must not extend the held punch.
 b.held_cast.begin(b);assert(b.held_cast.active)
 var shots:int=s.field.shot_serial
 b.process_demo_preview(0.5)
 assert(is_equal_approx(b.demo_duration,1.15))
 assert(b.held_cast.feedback.tier==1)
 assert(not b.held_cast.feedback.overlays.is_empty(),"Charge has no body barrier shell")
 assert(not s.actor.self_barrier.active(),"Charge accidentally granted a shield")
 assert(s.field.shot_serial==shots and not b.released,"Emitted during hold")
 b.process_demo_preview(0.2);assert(b.held_cast.feedback.tier==2)
 b.process_demo_preview(0.3);assert(b.held_cast.feedback.tier==3)
 var cue_count:int=s.field.audio.played.get("charge_3",0)
 b.process_demo_preview(0.5)
 assert(s.field.audio.played.get("charge_3",0)==cue_count,"Full charge cue repeated while held")
 for tier in [1,2,3]:assert(s.field.audio.played.get("charge_"+str(tier),0)>0)
 assert(s.field.audio.streams.charge_1.data!=s.field.audio.streams.charge_2.data and s.field.audio.streams.charge_2.data!=s.field.audio.streams.charge_3.data)
 assert(is_equal_approx(b.demo_duration,1.6),"Exceeded animation maximum")
 assert(s.field.shot_serial==shots)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://work/charge_body_shell.png")
 var cost:float=b.demo_preview_spec().stamina_cost
 assert(b.elapsed/b.cast_duration()<0.035,"Holding advanced past anticipation")
 var held_time:float=b.elapsed
 b.held_cast.release(b)
 assert(is_equal_approx(b.elapsed,held_time),"Key-up skipped the strike wind-up")
 b.process_demo_preview(0.001)
 assert(not b.released,"Key-up teleported directly to emission")
 for i in 15:b.process_demo_preview(0.01)
 assert(not b.held_cast.feedback.holding)
 b.held_cast.feedback._process(0.2)
 assert(is_zero_approx(b.held_cast.feedback.fade),"Charge glow did not fade on release")
 assert(b.released and s.field.shot_serial==shots+1)
 assert(is_equal_approx(s.actor.stamina,100.0-cost),"Final duration did not set shared stamina cost")
 b.process_demo_preview(1.1);assert(not b.playing)
 b.stop_preview_controls(true);s.actor.stamina=100;s.actor.mana=100
 b.held_cast.begin(b);b.process_demo_preview(0.4);b.interrupt_preview_cast()
 assert(s.actor.stamina<100 and s.field.shot_serial==shots+1,"Interrupted charge was free or emitted")
 while browser.thumbnails.busy or not browser.thumbnails.jobs.is_empty():await process_frame
 print("HELD CAST PASS: per-animation min/max, no emission while held, one release, shared costs, canceled stamina, grounded Dive Kick rejection/airborne authorization")
 quit()
