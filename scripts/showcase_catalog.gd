extends RefCounted
## Review cases call the same actions and collision paths as the live fight.
static func cases() -> Array[Dictionary]:
	var list: Array[Dictionary]=[]
	for spell in [["fireball","Fireball",0,0],["cinder_slash","Cinder Slash",0,1],["freezing_ray","Freezing Ray",1,1]]:
		var id: String=spell[0]
		var name_: String=spell[1]
		var base: Dictionary={"team":spell[2],"spell":spell[3],"kind":"spell","group":"Offense","expect":"contact"}
		add(list,id+"_ground",name_+" — Ground Cast",base)
		add(list,id+"_jump",name_+" — Jump Cast",base,{"air":true,"duration":4.5})
		add(list,id+"_charged",name_+" — Charged Cast",base,{"charged":true,"duration":6.5})
		add(list,id+"_palm_block",name_+" — Against Palm Shield",base,{"block":"palm","expect":"block"})
		add(list,id+"_brace_block",name_+" — Against Brace Shield",base,{"block":"brace","expect":"block"})
		add(list,id+"_guard_break",name_+" — Charged Guard Break",base,{"charged":true,"block":"brace","weak_guard":true,"expect":"guard_break","duration":7.0})
	for air in [false,true]:
		add(list,"armor_"+("jump" if air else "ground"),"Glacial Armor — "+("Jump Cast" if air else "Ground Cast"),{"team":1,"spell":0,"kind":"spell","group":"Defense","expect":"armor","air":air})
	add(list,"armor_fireball","Glacial Armor — Fireball Impact",{"team":1,"kind":"armor_impact","incoming":"fireball","group":"Defense","expect":"armor_hit","duration":5.0})
	add(list,"armor_punch","Glacial Armor — Punch Impact",{"team":1,"kind":"armor_impact","incoming":"punch","distance":0.78,"group":"Defense","expect":"armor_hit"})
	for air in [false,true]:
		add(list,"overdrive_"+("jump" if air else "ground"),"Overdrive — "+("Jump Cast" if air else "Ground Cast"),{"team":2,"spell":0,"kind":"spell","group":"Buff","expect":"aura","air":air})
	add(list,"overdrive_run","Overdrive — Powered Sprint",{"team":2,"kind":"overdrive_run","distance":20.0,"group":"Buff / Movement","expect":"aura","duration":5.0})
	add(list,"flash_ground","Flash Step — Charge, Dash, Knee",{"team":2,"spell":1,"kind":"spell","group":"Offense","expect":"contact","distance":5.0})
	add(list,"flash_jump","Flash Step — Jump, Charge, Knee",{"team":2,"spell":1,"kind":"spell","group":"Offense","expect":"contact","air":true,"distance":5.0})
	add(list,"flash_block","Flash Step — Knee Against Shield",{"team":2,"spell":1,"kind":"spell","group":"Offense / Defense","expect":"block","block":"brace","distance":5.0})
	add(list,"flash_overdrive","Overdrive into Flash Step Knee",{"team":2,"kind":"powered_flash","group":"Buff / Combo","expect":"contact","distance":5.0,"duration":5.5})
	for move in [[0,"Left Jab",0.78],[1,"Right Cross",0.60],[4,"Left Hook",0.60],[2,"Front Kick",1.15],[5,"Roundhouse Kick",1.15],[3,"Knee",0.78]]:
		add(list,"melee_"+str(move[0]),move[1]+" — Unblocked",{"team":0,"kind":"melee","move":move[0],"distance":move[2],"group":"Physical","expect":"contact","plain":true})
	for move in [[0,"Jab","palm",0.78],[2,"Front Kick","brace",1.15],[3,"Knee","palm",0.78]]:
		add(list,"blocked_melee_"+str(move[0]),move[1]+" — Against Shield",{"team":0,"kind":"melee","move":move[0],"distance":move[3],"block":move[2],"group":"Physical / Defense","expect":"block","plain":true})
	add(list,"uppercut","Charged Uppercut — Launch and Recovery",{"team":0,"kind":"uppercut","distance":0.78,"group":"Physical / Ragdoll","expect":"contact","duration":8.5})
	add(list,"uppercut_block","Charged Uppercut — Guard Break",{"team":0,"kind":"uppercut","distance":0.78,"block":"brace","weak_guard":true,"group":"Physical / Defense","expect":"guard_break","duration":8.5})
	add(list,"fire_kick","Fire-Augmented Front Kick",{"team":0,"kind":"melee","move":2,"distance":1.15,"group":"Elemental Melee","expect":"contact"})
	add(list,"ice_knee","Ice-Augmented Knee",{"team":1,"kind":"melee","move":3,"distance":0.78,"group":"Elemental Melee","expect":"contact"})
	for style in ["palm","brace"]:
		add(list,"shield_"+style,style.capitalize()+" Shield — Raise, Hold, Lower",{"team":0,"kind":"shield","style":style,"group":"Defense","expect":"shield"})
	for move in [["run","Run Around Target"],["approach","Walk Forward"],["retreat","Walk Backward"],["strafe_left","Strafe Left"],["strafe_right","Strafe Right"],["dodge_back","Quick Backward Dodge"],["roll_back","Backward Roll"],["flip","Backflip"]]:
		add(list,"movement_"+move[0],move[1],{"team":0,"kind":"movement","movement":move[0],"group":"Movement","expect":"movement"})
	add(list,"death_fireball","Lethal Fireball — Directional Ragdoll",{"team":0,"spell":0,"kind":"spell","lethal":true,"charged":true,"group":"Death / Physics","expect":"death","duration":7.0})
	add(list,"death_punch","Lethal Jab — Physical Ragdoll",{"team":0,"kind":"melee","move":0,"distance":0.78,"plain":true,"lethal":true,"group":"Death / Physics","expect":"death","duration":5.0})
	return list

static func add(list: Array[Dictionary],id: String,title: String,base: Dictionary,options: Dictionary={}) -> void:
	var entry: Dictionary={"id":id,"title":title,"duration":4.2,"distance":4.4,"team":0,"kind":"spell","group":"Offense","expect":"action"}
	entry.merge(base,true)
	entry.merge(options,true)
	list.append(entry)
