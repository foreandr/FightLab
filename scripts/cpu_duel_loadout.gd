extends RefCounted
## Small reusable authored loadout. Every cost/effect uses the shared spell rules.
const Rules=preload("res://scripts/combat_spell_rules.gd")
static func build()->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for move in [["Jab","ual1/Punch_Jab","hand_l","Arm",1.05],["Cross","ual1/Punch_Cross","hand_r","Arm",1.10],["Kick","boxing/front_kick_r","foot_r","Leg",1.45],["Knee","battle/knee","calf_r","Leg",1.05]]:
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
 # Short telegraphed shield cast, ordinary shared strength/lifetime and parry rules.
 var shield:Dictionary=Rules.author(Rules.self_barrier_base(),1.0,0.3,false)
 shield["id"]="cpu_shield";shield["name"]="Timed shield"
 result.append({"kind":"shield","title":"Timed shield","range":0.0,"duration":1.0,"spec":shield,"profile":{"clip":"duel/shield_raise_brace","step":"Brace Block","source_duration":1.0,"duration":1.0,"attack_bone":"hand_r","animation_type":"Arm"}})
 return result
