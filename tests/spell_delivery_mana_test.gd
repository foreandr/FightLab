extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize():
 var factors={"Projectile":1.0,"Beam":1.0,"Targeted":1.25,"Touch":0.5,"Barrier":0.5}
 for type in factors:
  var multiplier:float=factors[type]
  var raw={"mana":10.0,"delivery_type":type}
  assert(is_equal_approx(Rules.mana_cost(raw),10.0*multiplier))
  assert(is_equal_approx(Rules.mana_cost({"mana_percent":10.0,"delivery_type":type},200.0),20.0*multiplier))
  for element in ["None","Fire"]:
   var base:=Rules.allocate(Rules.projectile_base(element),{"size":0.3,"speed":0.3,"effect":0.4} if element=="Fire" else {"size":0.5,"speed":0.5},element,1.0)
   var normal:=base.duplicate(true);normal.delivery_type="Projectile"
   base.delivery_type=type
   for duration in [0.5,1.0,4.0,12.0]:
    var expected:=Rules.authored_stats(normal,duration,0.3,true)
    var stats:=Rules.authored_stats(base,duration,0.3,true)
    var authored:=Rules.author(base,duration,0.3,true)
    assert(is_equal_approx(stats.mana,float(expected.mana)*multiplier))
    assert(is_equal_approx(Rules.mana_cost(authored),stats.mana))
    assert(is_equal_approx(Rules.mana_cost(authored.duplicate(true)),stats.mana),"Reloaded spell applied type multiplier twice")
    for field in ["stamina","physical_damage","radius","velocity","burn_dps","amplifier"]:
     assert(is_equal_approx(float(stats[field]),float(expected[field])),"Type pricing changed "+field)
 # Exercise the real Touch authoring base, not only a projectile with its type changed.
 for element in ["None","Fire"]:
  for duration in [0.5,1.0,1.5,4.0,12.0]:
   for release in [0.05,0.3,0.55]:
    var projectile:=Rules.author(Rules.projectile_base(element),duration,release,true)
    for contacts in [["hand_r"],["hand_l","hand_r"]]:
     var touch:=Rules.author(Rules.touch_base(contacts,element),duration,release,true)
     assert(is_equal_approx(Rules.mana_cost(touch),Rules.mana_cost(projectile)*0.5),"Actual Touch base lost its half-price mana rule")
     assert(is_equal_approx(Rules.mana_cost(touch.duplicate(true)),Rules.mana_cost(projectile)*0.5),"Touch reload discounted mana twice")
 assert(Rules.mana_cost({"mana":10.0})==10.0)
 assert(Rules.mana_cost({"mana":10.0,"delivery_type":"Unknown"})==10.0)
 print("DELIVERY MANA PASS: 100/100/125/50/50 percent, direct and authored costs, percentage capacity, once-only pricing after reload, shared effects/timing transfer, unchanged stamina/damage/burn/motion")
 quit()
