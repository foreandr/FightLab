extends RefCounted
## Commit to a useful resource reserve, then change an unproductive attack plan.
var banking := false
var bank_time := 0.0
var stamina_target := 0.0
var mana_target := 0.0
var quiet_time := 0.0
var progress_damage := 0.0
var last_attack := ""
var last_attack_damage := 0.0
var repeats := 0
var cooldown := 0.0
var avoid_flash := 0.0
var plan := ""
var replans := 0

func reset(f: CharacterBody3D) -> void:
	banking=false
	bank_time=0
	quiet_time=0
	progress_damage=f.damage_dealt
	last_attack_damage=f.damage_dealt
	last_attack=""
	repeats=0
	cooldown=0
	avoid_flash=0
	plan=""

func tick(f: CharacterBody3D,delta: float) -> void:
	cooldown=maxf(0,cooldown-delta)
	avoid_flash=maxf(0,avoid_flash-delta)
	if not f.arena.round_active or f.health<=0:
		return
	quiet_time+=delta
	if f.damage_dealt>progress_damage+0.5:
		quiet_time=0
		repeats=0
		progress_damage=f.damage_dealt
	if banking:
		bank_time+=delta

func attack(f: CharacterBody3D,key: String) -> void:
	repeats=repeats+1 if key==last_attack and f.damage_dealt-last_attack_damage<0.5 else 1
	last_attack=key
	last_attack_damage=f.damage_dealt

func select(f: CharacterBody3D) -> bool:
	if not banking:
		var stalled: bool=cooldown<=0 and ((repeats>=3 and quiet_time>3) or quiet_time>12)
		var tired: bool=f.stamina<16 or (f.catching_breath and f.stamina<60)
		if not stalled and not tired:
			return false
		banking=true
		bank_time=0
		stamina_target=65 if stalled else 60
		mana_target=([28.0,40.0,27.0][f.team] if stalled else 0.0)
		plan="change_attack" if stalled else ""
		f.arena.events.append({"time":f.arena.elapsed,"event":"bank_resources","team":f.team,"reason":"stalled" if stalled else "stamina","stamina_target":stamina_target,"mana_target":mana_target})
	if (f.stamina<stamina_target or f.mana<mana_target) and bank_time<8:
		f.start_recovery()
		return true
	banking=false
	f.catching_breath=false
	cooldown=6
	quiet_time=0
	repeats=0
	if plan.is_empty():
		return false
	plan=""
	replans+=1
	f.arena.events.append({"time":f.arena.elapsed,"event":"adapt_tactic","team":f.team,"previous":last_attack,"stamina":f.stamina,"mana":f.mana})
	if f.team==2:
		avoid_flash=5
		if f.haste_time<=0 and f.mana>=18:
			f.spell_cursor=0
			f.start_cast(false)
		elif f.flat_distance()<1.5 and f.stamina>=32:
			f.start_uppercut()
		else:
			f.mode="chase"
			f.mode_time=0
			f.mode_length=0.6
	else:
		f.spell_cursor=(1 if last_attack=="fireball" else 0) if f.team==0 else 1
		var spec: Dictionary=f.arena.KITS[f.team][f.spell_cursor]
		if f.mana>=f.arena.mana_cost(spec):
			f.charge_requested=1
			f.start_cast(false)
		else:
			f.set_close_combat(true)
			if f.stamina<18:
				f.start_footwork("retreat")
			else:
				f.mode="chase"
				f.mode_time=0
				f.mode_length=0.6
	return true
