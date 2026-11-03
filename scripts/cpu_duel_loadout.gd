extends RefCounted
## Reusable authored repertoire. Every cost/effect uses the shared spell rules.
const Rules=preload("res://scripts/combat_spell_rules.gd")
static func build()->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for move in [["Left punch","ual1/Punch_Jab","hand_l","Arm",0.98],["Right punch","ual1/Punch_Cross","hand_r","Arm",0.95],["Kick","boxing/front_kick_r","foot_r","Leg",1.20],["Knee","battle/knee","calf_r","Leg",0.62]]:
  for seconds in [0.55,1.0,1.5]:
   var base:Dictionary=Rules.touch_base([move[2]])
   base["animation_type"]=move[3]
   var spec:Dictionary=Rules.author(base,seconds,0.22,true)
   spec["id"]="cpu_"+str(move[0]).to_lower()+"_"+str(seconds)
   spec["name"]="%s · %.2f s"%[move[0],seconds]
   result.append({"kind":"melee","title":spec.name,"range":move[4],"duration":seconds,"spec":spec,"profile":{"clip":move[1],"step":move[0],"store_raw":true,"duration":seconds,"attack_bone":move[2],"animation_type":move[3]}})
 for mix in [["Quick fireball",0.18,0.65,0.17,0.65],["Balanced fireball",0.34,0.40,0.26,1.0],["Large fireball",0.63,0.19,0.18,1.5]]:
  var base:Dictionary=Rules.allocate(Rules.projectile_base("Fire"),{"size":mix[1],"speed":mix[2],"effect":mix[3]},"Fire",1.0)
  var spec:Dictionary=Rules.author(base,float(mix[4]),0.3,true)
  spec["id"]="cpu_fire_"+str(result.size());spec["name"]=mix[0]
  result.append({"kind":"projectile","title":mix[0],"range":18.0,"duration":mix[4],"spec":spec,"profile":{"clip":"ual1/Punch_Jab","step":"Punch","store_raw":true,"duration":mix[4],"attack_bone":"hand_l","animation_type":"Arm"}})
 # Preserve the original action IDs above so existing learned policies remain useful.
 # New choices are distinct source motions, not just renamed versions of the jab.
 for move in [
  ["Left hook","boxing/hook_l","hand_l","Arm",1.15,0.85],
  ["Right hook","boxing/hook_r","hand_r","Arm",1.15,0.85],
  ["Uppercut","battle/uppercut","hand_r","Arm",1.05,0.9],
  ["Backfist","fight/backfist","hand_r","Arm",1.15,0.75],
  ["Elbow","editor_attacks/elbow","lowerarm_r","Arm",0.68,0.7],
  ["Body slash","editor_attacks/body_slash","hand_r","Arm",1.2,0.8],
  ["Crouch jab","fight/crouch_jab","hand_l","Arm",1.0,0.65],
  ["Chain punch","fight/chain_punch_short","hand_r","Arm",1.1,0.85],
  ["Rushing hook","fight/rushing_hook","hand_r","Arm",1.25,1.0],
  ["Rising uppercut","fight/rising_uppercut","hand_r","Movement",1.1,1.15],
  ["Lariat","fight/lariat","lowerarm_r","Movement",1.2,1.1],
  ["Left front kick","boxing/front_kick_l","foot_l","Leg",1.5,0.9],
  ["Left high kick","boxing/high_kick_l","foot_l","Leg",1.45,1.0],
  ["Right high kick","boxing/high_kick_r","foot_r","Leg",1.45,1.0],
  ["Axe kick","fight/axe_kick","foot_r","Leg",1.3,1.2],
  ["Sweep","fight/sweep","foot_r","Leg",1.4,1.0],
  ["Spinning sweep","fight/spin_sweep","foot_r","Movement",1.5,1.2],
  ["Spinning back kick","fight/spin_back_kick","foot_r","Movement",1.5,1.15],
  ["Tornado kick","fight/tornado_kick","foot_r","Movement",1.5,1.3],
  ["Hurricane kicks","fight/hurricane_kicks","foot_r","Movement",1.5,1.5],
  ["Rising kick","fight/rising_kick","foot_r","Movement",1.4,1.1],
  ["Slide kick","fight/slide_kick","foot_r","Movement",1.5,1.0],
  ["Headbutt","cpu_sources/headbutt","Head","Head",0.9,0.8]
 ]:
  result.append(touch_move(move))
 # Elemental contact still uses only its declared limb and the shared burn rules.
 for move in [
  ["Flame left jab","ual1/Punch_Jab","hand_l","Arm",1.05,0.65],
  ["Flame right cross","ual1/Punch_Cross","hand_r","Arm",1.10,0.7],
  ["Flame left hook","boxing/hook_l","hand_l","Arm",1.15,1.0],
  ["Flame right hook","boxing/hook_r","hand_r","Arm",1.15,1.0],
  ["Flame elbow","editor_attacks/elbow","lowerarm_r","Arm",0.68,0.9],
  ["Flame high kick","boxing/high_kick_r","foot_r","Leg",1.45,1.1],
  ["Flame knee","battle/knee","calf_r","Leg",0.62,0.9]
 ]:
  result.append(touch_move(move,"Fire"))
 for cast in [
  ["Palm fireball","spells/palm_fireball","hand_r",0.8,0.30,0.50,0.20],
  ["Offhand spark","spells/offhand_spark","hand_l",0.6,0.15,0.65,0.20],
  ["Twin push fireball","spells/twin_push","hand_r",1.1,0.45,0.35,0.20],
  ["Overhead fire cleave","spells/overhead_cleave","hand_r",1.25,0.30,0.45,0.25],
  ["Cleaving flame flick","spells/cleaving_flick","hand_r",0.7,0.15,0.60,0.25],
  ["Sun spear","spells/sun_spear","hand_r",1.4,0.12,0.70,0.18],
  ["Solar fireball","spells/solar_nova","hand_r",1.6,0.65,0.15,0.20],
  ["Ground sigil fireball","spells/ground_sigil","hand_r",1.3,0.40,0.25,0.35]
 ]:
  var base:Dictionary=Rules.allocate(Rules.projectile_base("Fire"),{"size":cast[4],"speed":cast[5],"effect":cast[6]},"Fire",1.0)
  var spec:Dictionary=Rules.author(base,float(cast[3]),0.3,true)
  spec.id="cpu_cast_"+str(cast[0]).to_snake_case();spec.name=cast[0]
  result.append({"kind":"projectile","title":cast[0],"range":18.0,"duration":cast[3],"spec":spec,"profile":{"clip":cast[1],"step":cast[0],"store_raw":true,"duration":cast[3],"attack_bone":cast[2],"animation_type":"Arm"}})
 # Quicker shield animation, priced by the same rules as any authored cast.
 var shield:Dictionary=Rules.author(Rules.self_barrier_base(),0.5,0.3,false)
 shield["id"]="cpu_shield";shield["name"]="Timed shield"
 result.append({"kind":"shield","title":"Timed shield","range":0.0,"duration":0.5,"spec":shield,"profile":{"clip":"duel/shield_raise_brace","step":"Brace Block","source_duration":1.0,"duration":0.5,"attack_bone":"hand_r","animation_type":"Arm"}})
 return result

static func touch_move(move:Array,element:String="None")->Dictionary:
 var base:Dictionary=Rules.touch_base([move[2]],element)
 if element=="Fire":base=Rules.allocate(base,{"size":0.15,"speed":0.55,"effect":0.30},"Fire",1.0)
 base.animation_type=move[3]
 var seconds:=float(move[5])
 var spec:Dictionary=Rules.author(base,seconds,0.22,true)
 spec.id="cpu_touch_"+str(move[0]).to_snake_case();spec.name=move[0]
 var result:Dictionary={"kind":"melee","title":move[0],"range":move[4],"duration":seconds,"spec":spec,"profile":{"clip":move[1],"step":move[0],"store_raw":true,"duration":seconds,"attack_bone":move[2],"animation_type":move[3]}}
 if str(move[1]).begins_with("boxing/hook_"):
  result.profile["combo_link_progress"]=0.68
  result.profile["contact_progress"]=0.44
  result.profile["preserve_arm_arc"]=true
  result["range"]=0.80
 return result

static func prepare(actor:Node)->void:
 # Register the existing authored headbutt once per actor, never per cast.
 if not actor.player.has_animation_library("cpu_sources"):
  var library:=AnimationLibrary.new()
  library.add_animation("headbutt",preload("res://assets/animations/demos/headbutt.res"))
  actor.player.add_animation_library("cpu_sources",library)
 var contacts:Dictionary={}
 for item in build():
  assert(actor.player.has_animation(item.profile.clip),"Missing CPU source: "+str(item.profile.clip))
  for bone in item.spec.get("touch_contacts",[]):contacts[str(bone)]=true
 for bone in contacts:actor.ensure_touch_contact_visual().ensure_region(bone)
