extends RefCounted
const ELEMENTS=["Fire","Ice","Lightning","Wind","Water","Earth"]
const COLORS={"Fire":Color("ff7138"),"Ice":Color("76dcff"),"Lightning":Color("fff253"),"Wind":Color("b4ffe2"),"Water":Color("258de0"),"Earth":Color("9c8059")}
const MIN_RADIUS:=0.1
const MAX_RADIUS:=2.0
const TEST_RADIUS:=30.0
const MIN_POTENCY:=0.25
const MAX_POTENCY:=4.0
const MIN_VELOCITY:=1.0
const MAX_VELOCITY:=50.0
const DEFAULT_VELOCITY:=14.0
static func size_share(radius:float) -> float:
	return clampf(log(maxf(MIN_RADIUS,radius)/MIN_RADIUS)/log(MAX_RADIUS/MIN_RADIUS),0,1)
static func potency_share(potency:float) -> float:
	return clampf((potency-MIN_POTENCY)/(MAX_POTENCY-MIN_POTENCY),0,1)
static func velocity_share(velocity:float) -> float:
	return clampf((velocity-MIN_VELOCITY)/(MAX_VELOCITY-MIN_VELOCITY),0,1)
static func budget_used(radius:float,potency:float,velocity:float=MIN_VELOCITY) -> float:
	return size_share(radius)+potency_share(potency)+velocity_share(velocity)
static func mana_percent(radius:float,potency:float,velocity:float=MIN_VELOCITY) -> float:
	return 5.0+95.0*clampf(budget_used(radius,potency,velocity),0,1)
static func mana_cost(radius:float,potency:float=1.0,capacity:float=100.0,velocity:float=MIN_VELOCITY) -> float:
	return capacity*mana_percent(radius,potency,velocity)/100.0
static func spec(element:String,radius:float,potency:float=1.0,testing:bool=false,velocity:float=DEFAULT_VELOCITY) -> Dictionary:
	radius=clampf(radius,MIN_RADIUS,TEST_RADIUS if testing else MAX_RADIUS)
	velocity=clampf(velocity,MIN_VELOCITY,MAX_VELOCITY)
	return {"id":"practice_"+element.to_lower(),"name":element+" projectile","animation":"palm_fireball","effect":"orb","hand":"hand_r","release":0.25,"projectile_element":element,"projectile_radius":radius,"projectile_velocity":velocity,"potency":potency,"testing_only":testing and radius>MAX_RADIUS,"mana_percent":mana_percent(radius,potency,velocity),"mana":mana_cost(radius,potency,100.0,velocity),"damage":12.0,"mass":(85.0*potency if element=="Wind" else 18.0)+radius*8.0}
static func visual(element:String,radius:float,appearance:Dictionary={}) -> MeshInstance3D:
	return preload("res://scripts/spell_appearance.gd").visual(element,radius,appearance)

static func allocate(radius:float,potency:float,velocity:float,edited:String,include_velocity:bool=true) -> Dictionary:
	var shares:Dictionary={"radius":size_share(radius),"potency":potency_share(potency)}
	if include_velocity:shares["velocity"]=velocity_share(velocity)
	var fixed:float=float(shares.get(edited,0.0))
	var others:=0.0
	for key in shares:
		if key!=edited:others+=float(shares[key])
	if fixed+others>1.0 and others>0:
		var scale:float=maxf(0,1.0-fixed)/others
		for key in shares:
			if key!=edited:shares[key]*=scale
		if edited!="radius":radius=MIN_RADIUS*pow(MAX_RADIUS/MIN_RADIUS,float(shares.radius))
		if edited!="potency":potency=MIN_POTENCY+float(shares.potency)*(MAX_POTENCY-MIN_POTENCY)
		if include_velocity and edited!="velocity":velocity=MIN_VELOCITY+float(shares.velocity)*(MAX_VELOCITY-MIN_VELOCITY)
	return {"radius":radius,"potency":potency,"velocity":velocity}
