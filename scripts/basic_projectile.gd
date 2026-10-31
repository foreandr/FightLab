extends RefCounted
const ELEMENTS=["Fire","Ice","Lightning","Wind","Water","Earth"]
const COLORS={"Fire":Color("ff7138"),"Ice":Color("76dcff"),"Lightning":Color("fff253"),"Wind":Color("b4ffe2"),"Water":Color("258de0"),"Earth":Color("9c8059")}
const MIN_RADIUS:=0.1
const MAX_RADIUS:=2.0
const TEST_RADIUS:=30.0
const MIN_POTENCY:=0.25
const MAX_POTENCY:=4.0
const MIN_VELOCITY:=1.0
# The former 30% allocation (1 + 49 * 0.3) is now the full base-speed budget.
const MAX_VELOCITY:=15.7
const DEFAULT_VELOCITY:=14.0
const CAST_RADIUS_SCALE:=1.0/3.0
const AIM_DISTANCE:=20.0

static func resolved_motion(spec:Dictionary) -> Dictionary:
	if spec.get("unrestricted_preview",false):
		return {"radius":maxf(0.0001,float(spec.projectile_radius)),"speed":maxf(0.0,float(spec.projectile_velocity))}
	var charge:=clampf(float(spec.get("charge",0.0)),0.0,1.0)
	var speed:float=(14.0 if spec.effect=="orb" else 17.0)*(1.0+charge*0.7)
	if spec.has("projectile_velocity"):speed=clampf(float(spec.projectile_velocity),1.0,50.0)
	var radius:float=(0.16 if spec.effect=="orb" else 0.13)*(1.0+charge*0.9)
	if spec.has("projectile_radius"):radius=clampf(float(spec.projectile_radius),0.1,30.0 if spec.get("testing_only",false) else 2.0)
	if spec.has("base_projectile_radius") and spec.has("base_projectile_velocity"):
		var amp:=maxf(1.0,float(spec.get("spell_amplifier",1.0)))
		var scale:=maxf(0.001,float(spec.get("projectile_radius_scale",1.0)))
		radius=clampf(float(spec.base_projectile_radius),0.1*scale,(30.0 if spec.get("testing_only",false) else 2.0)*scale)*amp
		speed=clampf(float(spec.base_projectile_velocity),1.0,50.0)*amp
	return {"radius":radius,"speed":speed}

static func lifetime(distance:float,radius:float,speed:float) -> float:
	return clampf((distance+radius*2.0)/maxf(0.001,speed)+2.0,2.2,90.0)
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
