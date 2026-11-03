extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
var world:Node
var a:CharacterBody3D
var b:CharacterBody3D
func _initialize():
 set_meta("ai_learning_enabled",false);set_meta("cpu_training_view",true)
 call_deferred("run")
func reset()->void:
 world.clear_battle_effects();world.spell_environment.reset_environment();world.events.clear();world.projectile_clash_count=0
 for actor in [a,b]:
  actor.reset_fighter(Vector3(-12 if actor==a else 12,0,-8));actor.brain_enabled=false;actor.guard_energy=0;actor.velocity=Vector3.ZERO;actor.damage_taken=0;actor.damage_dealt=0
 world.round_active=true
func shot(caster:CharacterBody3D,damage:float,origin:Vector3,velocity:Vector3,element:String="None",potency:float=0.0)->Dictionary:
 var spec:=Rules.projectile_base(element,0.15,potency)
 spec.damage=damage;spec.potency=potency;spec.aim_direction=velocity.normalized()
 world.spawn_projectile(caster,spec,origin)
 var result:Dictionary=world.shots.back();result.velocity=velocity;return result
func run():
 change_scene_to_file("res://scenes/cpu_duel.tscn");await process_frame;await process_frame
 world=current_scene;world.set_physics_process(false);a=world.fighters[0];b=world.fighters[1]
 reset()
 shot(a,50,Vector3(-2,2,0),Vector3.RIGHT*40,"Fire",3)
 shot(b,50,Vector3(2,2,0),Vector3.LEFT*40,"Fire",3)
 world.step_shots(0.1)
 assert(world.shots.is_empty() and world.projectile_clash_count==1,"Equal fast projectiles tunneled or survived")
 assert(a.health==a.MAX_HEALTH and b.health==b.MAX_HEALTH and world.spell_environment.patches.is_empty(),"Air clash caused phantom damage or ground fire")
 for reverse in [false,true]:
  reset()
  var strong:=shot(a,60,Vector3(-2,2,0),Vector3.RIGHT*20,"Fire",3)
  strong.spec["charge"]=0.9
  var original:Dictionary=strong.spec
  var mass:float=strong.mass
  shot(b,40,Vector3(2,2,0),Vector3.LEFT*20)
  if reverse:world.shots.reverse()
  world.step_shots(0.2)
  assert(world.shots.size()==1 and world.shots[0].id==strong.id)
  assert(is_equal_approx(strong.spec.damage,20) and is_equal_approx(strong.spec.potency,1.0) and is_equal_approx(strong.mass,mass/3.0))
  assert(is_equal_approx(strong.spec.charge,0.3))
  assert(strong.velocity==Vector3.RIGHT*20 and is_equal_approx(strong.radius,0.15))
  assert(original.damage==60 and original.potency==3 and strong.node.position.is_equal_approx(Vector3(2,2,0)),"Clash mutated original spec or failed to continue flight")
 reset()
 var chain:=shot(a,100,Vector3(-3,2,0),Vector3.RIGHT*20,"Fire",4)
 shot(b,40,Vector3(0,2,0),Vector3.ZERO);shot(b,50,Vector3(2,2,0),Vector3.ZERO)
 world.step_shots(0.3)
 assert(world.projectile_clash_count==2 and world.shots.size()==1 and is_equal_approx(chain.spec.damage,10) and is_equal_approx(chain.spec.potency,0.4),"Multiple clashes were not resolved chronologically")
 reset()
 shot(a,50,Vector3(-2,2,0),Vector3.RIGHT*20);shot(a,50,Vector3(2,2,0),Vector3.LEFT*20)
 world.step_shots(0.2);assert(world.shots.size()==2 and world.projectile_clash_count==0,"Friendly shots canceled")
 reset()
 shot(a,50,Vector3(-2,2,0),Vector3.RIGHT*20);shot(b,50,Vector3(2,2.5,0),Vector3.LEFT*20)
 world.step_shots(0.2);assert(world.shots.size()==2 and world.projectile_clash_count==0,"Near misses collided")
 reset()
 var wall:=StaticBody3D.new();wall.position=Vector3(-0.8,2,0)
 var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(0.15,3,3);collision.shape=box;wall.add_child(collision);world.add_child(wall)
 await physics_frame
 shot(a,50,Vector3(-2,2,0),Vector3.RIGHT*20);shot(b,50,Vector3(2,2,0),Vector3.LEFT*20)
 world.step_shots(0.2);assert(world.projectile_clash_count==0,"Projectiles clashed through an earlier wall impact")
 wall.queue_free();await physics_frame
 reset()
 b.global_position=world.surface_placement(Vector3(-0.9,0,0));b.invulnerability=0;b.update_targets()
 var body_y:float=b.bone_point("pelvis").y+0.05
 shot(a,50,Vector3(-2,body_y,0),Vector3.RIGHT*20);shot(b,50,Vector3(2,body_y,0),Vector3.LEFT*20)
 world.step_shots(0.2)
 assert(world.projectile_clash_count==0 and is_equal_approx(b.damage_taken,50),"A later clash canceled an earlier body hit")
 reset()
 await physics_frame;await physics_frame
 b.global_position=world.surface_placement(Vector3(4,0,0));b.invulnerability=0;b.tick(0.0);b.update_targets()
 var y:float=b.bone_point("pelvis").y+0.05
 shot(a,60,Vector3(-2,y,0),Vector3.RIGHT*20,"Fire",3);shot(b,40,Vector3(0,y,0),Vector3.LEFT*20)
 world.step_shots(0.1);assert(world.shots.size()==1)
 world.step_shots(0.25)
 assert(is_equal_approx(b.damage_taken,20) and b.burn_time>0 and is_equal_approx(b.burn_damage,preload("res://scripts/burn_rules.gd").TICK_DAMAGE),"Survivor did not deliver residual damage and reduced burn")
 reset()
 var water:=shot(a,60,Vector3(0,2,0),Vector3.DOWN,"Water",3)
 preload("res://scripts/projectile_clashes.gd").reduce(water,20,60)
 world.spell_environment.projectile_step(water,Vector3(0,1,0),Vector3.ZERO,true)
 assert(is_equal_approx(world.spell_environment.water_volume,(4.0/3.0*PI*pow(0.15,3))/3.0),"Residual water kept full volume")
 print("PROJECTILE CLASH PASS: 50/50 cancel, 60/40 leaves 20 and proportional effect/force, fast sweeps, array order, chained collisions, friendly/near misses, earlier wall/body precedence, real residual damage/burn and no phantom floor fire")
 quit()
