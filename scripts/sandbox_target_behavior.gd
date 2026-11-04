extends Node
## Sandbox chooses intent; the existing CPU brain, actor and combat runtime fight.
const MODES:=["Passive","Repeat left punch","Repeat left-punch fireball","Fight me"]
const Movement=preload("res://scripts/character_movement.gd")
var screen:Control
var unit:CharacterBody3D
var behavior:="Passive"
var clock:=0.0
var brain:RefCounted
var menu:PopupMenu
var attacks_started:=0

func setup(owner_screen:Control)->void:
 screen=owner_screen;unit=screen.target
 menu=PopupMenu.new();menu.name="SandboxTargetBehavior";menu.theme=screen.theme
 menu.add_theme_stylebox_override("panel",screen.theme.get_stylebox("panel","PanelContainer"))
 for index in MODES.size():menu.add_radio_check_item(MODES[index],index)
 menu.id_pressed.connect(func(index:int):set_behavior(MODES[index]))
 screen.add_child(menu)
 screen.spell_builder.reset_scene_button.pressed.connect(func():set_behavior("Passive"))

func open_at(pointer:Vector2)->void:
 for index in MODES.size():menu.set_item_checked(index,MODES[index]==behavior)
 menu.popup(Rect2i(Vector2i(pointer),Vector2i(280,0)))

func set_behavior(value:String)->void:
 if value not in MODES:return
 behavior=value;clock=1.75;brain=null
 unit.rival=screen.actor;unit.brain_enabled=false;unit.editor_pose_locked=false
 unit.practice_return_enabled=false;unit.practice_face_rival=true
 if not unit.arena.combat().cast_committed(unit):
  unit.practice_projectile_spec={};unit.practice_spell_animation={}
  unit.arena.combat().interrupt_cast_attempt(unit)
  if not unit.combat_reaction_active():unit.mode="idle"
 if behavior=="Fight me":
  brain=preload("res://scripts/cpu_duel_brain.gd").new()
  brain.setup(unit,screen.field,int(Time.get_ticks_usec()),0.65)
 if is_instance_valid(menu):menu.hide()

func fireball()->bool:
 var rules=preload("res://scripts/combat_spell_rules.gd")
 var base:Dictionary=rules.allocate(rules.projectile_base("Fire"),{"size":0.3,"speed":0.5,"effect":0.2},"Fire",1.0)
 var spec:Dictionary=rules.author(base,1.0,0.3,true)
 spec.id="sandbox_practice_fireball";spec.name="Practice left-punch fireball";spec.hand="hand_l"
 var origin:Vector3=screen.field.fighter_hand(unit,"hand_l")
 spec.aim_direction=(screen.actor.bone_point("spine_03")-origin).normalized()
 return unit.start_authored_cast(spec,{"title":"Left jab","clip":"ual1/Punch_Jab","step":"Punch","store_raw":true,"duration":1.0,"attack_bone":"hand_l","animation_type":"Arm"},screen.actor)

func step(delta:float)->void:
 if not is_instance_valid(unit) or unit.health<=0:return
 var target=screen.actor
 if not is_instance_valid(target):return
 unit.rival=target
 if behavior=="Passive" or target.health<=0:
  if not unit.combat_reaction_active() and unit.mode not in ["cast","punch"]:
   unit.mode="idle";unit.set_cast_movement(Vector3.ZERO)
  return
 if behavior=="Fight me":
  brain.step(delta)
  return
 if unit.combat_reaction_active():return
 var toward:Vector3=target.global_position-unit.global_position;toward.y=0.0
 Movement.turn(unit,toward.normalized(),delta)
 if unit.mode=="cast":
  var origin:Vector3=screen.field.fighter_hand(unit,"hand_l")
  unit.current_spell.aim_direction=(target.bone_point("spine_03")-origin).normalized()
 clock+=delta
 if unit.mode in ["cast","punch"]:return
 if behavior=="Repeat left punch" and toward.length()>0.88:
  unit.mode="approach";unit.mode_time=0.0;unit.mode_length=0.2
  return
 unit.mode="idle"
 var interval:=1.2 if behavior=="Repeat left punch" else 2.0
 if clock<interval:return
 var started:bool=unit.start_left_jab(toward.normalized()) if behavior=="Repeat left punch" else fireball()
 if started:clock=0.0;attacks_started+=1

func _physics_process(delta:float)->void:step(delta)
