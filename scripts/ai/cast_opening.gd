extends RefCounted
## Observable space/time budget, not knowledge of the opponent's next decision.
static func seconds(actor:CharacterBody3D)->float:
 var enemy:CharacterBody3D=actor.rival
 var gap:float=maxf(0.0,actor.flat_distance()-1.5)
 # Allow a reaction plus a fast ground rush; don't assume a stationary enemy stays still.
 var opening:=0.20+gap/8.2
 if enemy.mode=="cast" and actor.arena.combat().cast_committed(enemy):
  opening+=maxf(0.0,enemy.mode_length-enemy.cast_time)/maxf(0.1,enemy.cast_speed_multiplier())
 elif enemy.mode=="getup":opening+=maxf(0.0,enemy.mode_length-enemy.mode_time)
 if actor.arena.has_method("time_remaining"):opening=minf(opening,actor.arena.time_remaining())
 return opening
static func safety(actor:CharacterBody3D,item:Dictionary)->float:
 var release:=float(item.duration)*float(item.spec.release)/maxf(0.1,actor.parry_cast_haste.multiplier())
 return smoothstep(release*0.45,release*1.15,seconds(actor))
