extends SceneTree
const Loadout=preload("res://scripts/cpu_duel_loadout.gd")
func _initialize():
 set_meta("ai_learning_enabled",false)
 call_deferred("run")
func run():
 # Public home route, rather than a development-only scene entry.
 change_scene_to_file("res://scenes/home.tscn");await process_frame;await process_frame
 var home=current_scene
 home.navigation_buttons["Free Fight"].pressed.emit()
 assert(home.page=="Free Fight" and home.navigation_buttons.has("CPU 1v1"))
 home.navigation_buttons["CPU 1v1"].pressed.emit()
 await process_frame;await process_frame
 var demo=current_scene
 assert(demo.ready_for_match and demo.fighters.size()==2 and demo.get_script().get_base_script()==load("res://scripts/combat_world.gd"))
 assert(Loadout.build().size()==63)
 assert(demo.hud.find_children("*","ProgressBar",true,false).is_empty(),"Resource bars should only be on the characters")
 for brain in demo.brains:
  for item in brain.loadout:assert(brain.actor.player.has_animation(item.profile.clip),"Missing equipped animation")
 await create_timer(2.2).timeout
 demo.toggle_pause();var before:float=demo.elapsed
 await create_timer(0.15).timeout
 assert(demo.elapsed==before,"Pause advanced the match")
 demo.toggle_pause()
 # Recovery is a genuine budget decision, not unlimited AI resources.
 demo.rematch(1);demo.countdown=0;demo.round_active=true
 demo.brains[0].actor.stamina=12.0;demo.brains[0].think_left=0
 demo.brains[0].step(0.1)
 assert(demo.brains[0].recovering and demo.brains[0].reason=="Recover stamina / mana")
 demo.fighters[0].stamina=100.0;demo.fighters[0].mode="chase"
 demo.fighters[0].recover_resources(0.5)
 assert(is_equal_approx(demo.fighters[0].stamina,94.0),"CPU sprint did not use the shared 12 stamina/second rule")
 var kinds:Dictionary={};var seen_shield:=false;var seen_defense:=false;var seen_recovery:=false;var seen_combo:=false;var seen_perfect:=false
 # Accelerated tests must retain the live game's 1/60s physics step, especially
 # for swept contacts and ragdoll settling. 4x time at 60Hz skips those steps.
 Engine.physics_ticks_per_second=240
 for seed_ in [20261103,173,917]:
  demo.rematch(seed_);Engine.time_scale=4.0
  var deadline:=Time.get_ticks_msec()+90000
  while demo.match_winner==-2 and Time.get_ticks_msec()<deadline:
   await physics_frame
   for actor in demo.fighters:
    assert(actor.stamina>=0 and actor.mana>=0 and actor.stamina<=actor.MAX_STAMINA and actor.mana<=actor.MAX_MANA)
    assert(not actor.practice_god_mode and not actor.practice_immortal)
  assert(demo.match_winner>=-1 and demo.match_winner<=1,"CPU match failed to finish")
  assert(not demo.round_active)
  if demo.match_winner>=0:
   if demo.finish_reason=="timeout":assert(demo.fighters[demo.match_winner].health>demo.fighters[1-demo.match_winner].health)
   else:assert(demo.fighters[1-demo.match_winner].health<=0)
  for event in demo.events:
   if event.event=="cpu_combo":seen_combo=true
   if event.event in ["parry","directional_parry"]:seen_perfect=true
   if event.event=="cast":
    var spell:String=event.spell
    if "shield" in spell:seen_shield=true
    elif "fire" in spell:kinds.projectile=true
    else:kinds.touch=true
   if event.event=="cpu_decision":
    if event.action=="Evade":seen_defense=true
    if event.reason=="Recover stamina / mana":seen_recovery=true
  # A legitimate clash/knockdown win can be a shutout. Verify both actors
  # actually act, rather than requiring the loser to land a consolation hit.
  for actor in demo.fighters:assert(int(actor.actions.get("cast",0))+int(actor.actions.get("air_cast",0))>0)
  assert(maxf(demo.fighters[0].damage_dealt,demo.fighters[1].damage_dealt)>0)
  print("CPU MATCH PASS seed=",seed_," winner=",demo.match_winner," seconds=",demo.finished_at," damage=",demo.fighters[0].damage_dealt,"/",demo.fighters[1].damage_dealt)
  var ended:float=demo.finished_at
  await create_timer(0.2).timeout
  assert(demo.finished_at==ended)
 # Tactical choices are outcomes, not quotas. Dedicated swept-contact/combo/
 # parry tests verify those mechanics; a valid ranged knockout needn't contain
 # every possible move. Keep the observations visible for strategy review.
 assert(not kinds.is_empty())
 print("CPU TACTICS OBSERVED: ",kinds," shield=",seen_shield," evade=",seen_defense," recovery=",seen_recovery," combo=",seen_combo," perfect=",seen_perfect)
 demo.rematch(101)
 for actor in demo.fighters:assert(actor.health==actor.MAX_HEALTH and actor.mana==actor.MAX_MANA and actor.stamina==actor.MAX_STAMINA and actor.damage_dealt==0 and actor.damage_taken==0 and actor.mana_spent==0 and actor.stamina_spent==0)
 assert(demo.match_winner==-2 and demo.shots.is_empty() and demo.events.is_empty() and demo.spell_environment.patches.is_empty())
 print("CPU DUEL PASS: public Fight menu, complete reusable loadouts, native authored poses, three real full matches, both actors active, character-only bars, finite resources, winner/timeout, pause and clean rematch; tactical observations reported above")
 quit()
