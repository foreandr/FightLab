extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 var definition=load("res://scripts/spell_definition.gd")
 var rules=load("res://scripts/combat_spell_rules.gd")
 var library=load("res://scripts/saved_spell_library.gd").new()
 library.directory="user://logs/touch_barrier_"+Crypto.new().generate_random_bytes(4).hex_encode()
 var fire=load("res://assets/spells/fire/library.gd")
 var touch:Dictionary=definition.make("None","Touch",{"size":0.5,"speed":0.5},{})
 var flame:Dictionary=definition.make("Fire","Touch",{"size":0.15,"speed":0.55,"effect":0.30},fire.selection("fire_02","fire_whoosh"))
 var shield:Dictionary=definition.make("None","Barrier",{"size":0.5,"speed":0.5},{})
 var saved:Array=[]
 for recipe in [["Physical Touch",touch],["Fire Touch",flame],["Self Barrier",shield]]:
  var result:Dictionary=library.save(recipe[0],recipe[1]);assert(result.ok)
  var record:Dictionary=library.find(result.record.id)
  assert(record.name==recipe[0] and record.metadata.creator=="foreandr")
  saved.append(record)
 assert(library.entries().size()==3)
 var animation:Dictionary={"duration":1.0,"group":"Attack","animation_type":"Arm","attack_bone":"hand_l"}
 var plain:Dictionary=definition.compile(saved[0],animation,{"release":0.3})
 assert(plain.effect=="touch" and plain.touch_contacts==["hand_l"] and is_equal_approx(plain.damage,10.0))
 var right:Dictionary=definition.compile(saved[0],animation,{"release":0.3,"hand":"hand_r"})
 assert(right.touch_contacts==["hand_r"] and plain.touch_contacts==["hand_l"])
 var dual:Dictionary=definition.compile(saved[0],animation,{"release":0.3,"contacts":["hand_l","hand_r"]})
 assert(dual.stamina_cost>plain.stamina_cost)
 var burning:Dictionary=definition.compile(saved[1],animation,{"release":0.3})
 var cpu_base:Dictionary=rules.allocate(rules.touch_base(["hand_l"],"Fire"),flame.allocation,"Fire",1.0)
 cpu_base.animation_type="Arm"
 var expected:Dictionary=rules.author(cpu_base,1.0,0.3,true)
 assert(is_equal_approx(burning.damage,expected.damage) and is_equal_approx(burning.potency,expected.potency) and is_equal_approx(burning.stamina_cost,expected.stamina_cost))
 assert(burning.appearance.fire_style_id==saved[1].appearance.fire_style_id and burning.sound_id==saved[1].appearance.sound_id)
 var block:Dictionary=definition.compile(saved[2],animation,{"release":0.3})
 assert(block.effect=="self_barrier" and block.damage==0 and is_equal_approx(block.shield_strength,10) and is_equal_approx(block.shield_duration,1) and is_equal_approx(block.mana,10))
 var bad:=shield.duplicate(true);bad.barrier.strength=NAN;assert(not definition.error(bad).is_empty())
 var world=load("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor=world.spawn_combatant(0,Vector3.ZERO);actor.practice_god_mode=true
 assert(world.combat().release(actor,plain,actor.bone_point("hand_l"),animation))
 assert(world.combat().touch_casts[actor.get_instance_id()].spec.spell_definition_id==saved[0].id)
 world.combat().finish_cast(actor)
 assert(world.combat().release(actor,block,actor.global_position,animation) and actor.self_barrier.active())
 for record in library.entries():DirAccess.remove_absolute(library.directory.path_join(record.id+".cfg"))
 DirAccess.remove_absolute(library.directory)
 world.queue_free();await process_frame
 print("SAVED TOUCH/BARRIER PASS: reload, metadata, dynamic contacts, CPU-equivalent rules, shield benchmark, actual shared runtime release")
 quit()
