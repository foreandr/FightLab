extends SceneTree
func _initialize():set_meta("ai_learning_enabled",false);call_deferred("run")
func run():
 var rules=load("res://scripts/combat_spell_rules.gd")
 var charge=load("res://scripts/cast_charge_rules.gd")
 var last:=0.0
 for seconds in [0.0,0.34,0.68,1.0]:
  var base:Dictionary=rules.touch_base(["hand_r"])
  base["cast_charge_time"]=seconds
  var spec:Dictionary=rules.author(base,1.0,0.3,true)
  assert(spec.damage>last and is_equal_approx(spec.stamina_cost,10.0*float(charge.sample(seconds).stamina_multiplier)))
  assert(spec.cast_charge_tier==charge.sample(seconds).tier)
  last=spec.damage
 var previous_stamina:=0.0
 for time in [0.0,0.4,0.75]:
  var base:Dictionary=rules.touch_base(["hand_r"]);base.cast_charge_time=time;base.cast_charge_reference_duration=0.33
  var priced:Dictionary=rules.author(base,lerpf(0.33,0.75,minf(time,1.0)),0.3,true)
  assert(priced.stamina_cost>previous_stamina,"Lengthening a fast native clip made higher charge cheaper")
  previous_stamina=priced.stamina_cost
 var calibrated:Dictionary=rules.touch_base(["hand_r"]);calibrated.cast_charge_time=0.0;calibrated.cast_charge_damage_reference_duration=1.0
 assert(is_equal_approx(rules.author(calibrated,0.33,0.3,true).damage,10.0),"Native clip speed changed the tap benchmark")
 calibrated.cast_charge_time=1.1
 assert(is_equal_approx(rules.author(calibrated,0.75,0.3,true).damage,20.0))
 var tap:Dictionary=rules.author(rules.touch_base(["hand_r"]),0.7,0.3,true)
 var tired_base:Dictionary=rules.touch_base(["hand_r"]);tired_base.cast_charge_time=charge.TIRED_AT
 var tired:Dictionary=rules.author(tired_base,1.6,0.3,true)
 assert(tired.damage>0 and tired.damage<tap.damage and tired.stamina_cost>0 and tired.stamina_cost<tap.stamina_cost)
 assert(charge.sample(0.95).stamina_multiplier>1.0 and charge.sample(0.95).stamina_multiplier<=1.15)
 assert(charge.sample(1.12).stamina_multiplier==1.0)
 assert(charge.sample(1.12).tier==3 and charge.sample(1.12).multiplier==2.0)
 assert(charge.sample(1.5).tier==4 and charge.sample(1.6).multiplier<charge.sample(1.5).multiplier)
 assert(charge.sample(10.0).multiplier==charge.sample(charge.TIRED_AT).multiplier)
 var definition=load("res://scripts/spell_definition.gd")
 var record:Dictionary=definition.make("None","Touch",{"size":0.5,"speed":0.5},{})
 var composed:Dictionary=definition.compile(record,{"duration":1.0,"group":"Attack","attack_bone":"hand_r"},{"release":0.3,"hold_seconds":1.0,"charge_reference_duration":1.0})
 assert(composed.damage==20.0 and composed.stamina_cost<10.0001,"Reusable definition ignored the shared charge law")
 print("CHARGE CURVE PASS: tap, good, better, perfect plateau, red weakening below tap, nonzero exhausted floor, universal definition binding")
 quit()
