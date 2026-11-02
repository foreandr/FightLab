extends SceneTree
const Type=preload("res://scripts/animation_cast_type.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for e in preload("res://scripts/animation_catalog.gd").entries():assert(Type.declared(e))
 var library=load("res://scripts/animation_store_library.gd").new()
 assert(not library.take({"title":"Undeclared","clip":"missing"},"Motion","Downloaded"))
 var world=load("res://scripts/combat_world.gd").new()
 root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor=world.spawn_combatant(0,Vector3.ZERO)
 for kind in [Type.LEGS,Type.WHOLE_BODY]:
  var profile={"animation_type":kind}
  actor.velocity=Vector3(7,0,0);Type.begin(actor,profile)
  var a:=Type.drift(actor,profile,0.25)
  assert(a.x>0 and a.x<7 and a.z==0)
  var b:=Type.drift(actor,profile,0.25)
  actor.velocity=Vector3(7,0,0);Type.begin(actor,profile)
  assert(b.is_equal_approx(Type.drift(actor,profile,0.5)))
  assert(Type.drift(actor,profile,20).is_zero_approx())
 actor.velocity=Vector3.ZERO
 for effect in ["None","Fire"]:
  var base:=Rules.projectile_base(effect)
  base=Rules.allocate(base,{"size":0.5,"speed":0.5,"effect":0.0},effect,1.0)
  var stats:Dictionary={}
  for kind in Type.TYPES:
   base.animation_type=kind
   stats[kind]=Rules.authored_stats(base,1.0,0.3,true)
   var spec:=Rules.author(base,1.0,0.3,true)
   actor.stamina=100;actor.mana=100
   assert(world.combat().release(actor,spec,Vector3.UP))
   assert(is_equal_approx(world.shots.back().spec.damage,stats[kind].physical_damage))
  assert(is_equal_approx(stats[Type.LEGS].physical_damage,stats[Type.ARMS].physical_damage))
  assert(is_equal_approx(stats[Type.WHOLE_BODY].physical_damage,stats[Type.ARMS].physical_damage))
  assert(stats[Type.LEGS].mana==stats[Type.ARMS].mana and stats[Type.LEGS].stamina==stats[Type.ARMS].stamina)
  assert(stats[Type.LEGS].burn_dps==stats[Type.ARMS].burn_dps)
 print("ANIMATION TYPES PASS: all catalog entries declared, import rejects undeclared, world-direction momentum and timestep-independent drag, non-Touch ignores type bonuses during actual launch, no extra mana/stamina/burn scaling")
 world.queue_free();await process_frame;quit()
