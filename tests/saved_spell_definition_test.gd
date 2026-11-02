extends SceneTree
const Definition=preload("res://scripts/spell_definition.gd")
const Library=preload("res://scripts/saved_spell_library.gd")
const Fire=preload("res://assets/spells/fire/library.gd")
func _initialize():call_deferred("run")
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run():
 var library:=Library.new();library.directory="user://logs/spell_definition_test_"+Crypto.new().generate_random_bytes(4).hex_encode()
 var look:=Fire.selection(Fire.styles()[0].id,"lentikula_fire_4")
 var definition:=Definition.make("Fire","Projectile",{"size":0.2,"speed":0.3,"effect":0.5},look)
 if not check(Definition.error(definition).is_empty(),"Valid definition rejected"):return
 var one:=library.save("Test flame",definition)
 var two:=library.save("Test flame",definition)
 if not check(one.ok and two.ok and two.record.name=="Test flame (1)" and one.record.id!=two.record.id,"Duplicate name overwrote spell"):return
 var reopened:=Library.new();reopened.directory=library.directory
 var saved:=reopened.find(one.record.id)
 if not check(saved==one.record and reopened.entries().size()==2,"Named spell does not survive disk reload"):return
 for key in ["total_power","duration","animation_duration","casting_animation","release","hand","mana","stamina_cost","damage","spell_amplifier","projectile_radius","projectile_velocity"]:
  if not check(not saved.has(key),"Saved calculated/demo/binding field: "+key):return
 if not check(saved.appearance.keys().size()==2 and saved.appearance.sound_id=="lentikula_fire_4" and saved.allocation==definition.allocation,"Lost asset IDs or distribution"):return
 var history:=preload("res://scripts/asset_provenance.gd").inspect_text(saved.provenance)
 if not check(history.contains("lentikula") and history.contains("foreandr") and history.contains("https://"),"Spell loses artist/author source history"):return
 var blocked:=library.save("Unrestricted",definition,false)
 if not check(not blocked.ok and library.entries().size()==2,"Limiter-off spell can be saved"):return
 var bad:=definition.duplicate(true);bad["total_power"]=0.1
 if not check(not library.save("Derived",bad).ok,"Saved definition accepts total power"):return
 if not check(not library.save(" ",definition).ok,"Blank spell name allowed"):return
 var a:=Definition.compile(saved,{"duration":1.0,"group":"Attack","animation_type":"Arm"},{"release":0.4,"hand":"hand_l"})
 var b:=Definition.compile(saved,{"duration":2.0,"group":"Attack","animation_type":"Arm"},{"release":0.2,"hand":"hand_r"})
 if not check(a.animation_duration==1.0 and b.animation_duration==2.0 and a.stamina_cost!=b.stamina_cost and a.mana!=b.mana and a.release==0.4 and a.hand=="hand_l","Spell freezes demo timing/costs or emitter instead of animation binding"):return
 if not check(a.appearance.fire_style_id==saved.appearance.fire_style_id and b.sound_id==saved.appearance.sound_id,"Compiling loses Fire styles/sounds"):return
 if not check(Definition.compile(saved,{},{}).is_empty(),"Missing animation duration silently invented"):return
 var plain:=Definition.make("None","Projectile",{"size":0.5,"speed":0.5},{})
 var plain_cast:=Definition.compile(plain,{"duration":1.0,"group":"Attack"},{"release":0.3})
 if not check(Definition.error(plain).is_empty() and plain.appearance.is_empty() and is_equal_approx(plain_cast.physical_damage,10.0),"Elementless reusable spell loses neutral benchmark"):return
 var world=preload("res://scripts/combat_world.gd").new();root.add_child(world);world.set_physics_process(false);world.round_active=true
 var actor:CharacterBody3D=world.spawn_combatant(0,Vector3.ZERO);actor.practice_god_mode=true
 if not check(world.combat().release(actor,b,actor.bone_point(b.hand)) and world.shots.back().spec.spell_definition_id==saved.id and world.audio.played.get(saved.appearance.sound_id,0)==1,"Reusable saved definition cannot cast through shared combat"):return
 for record in library.entries():DirAccess.remove_absolute(library.directory.path_join(record.id+".cfg"))
 DirAccess.remove_absolute(library.directory)
 print("SAVED SPELL DEFINITION PASS: local reload; unique names; no power/demo/timing/cost fields; asset credits; limiter guard; animation-derived compile and actual shared cast")
 quit()
