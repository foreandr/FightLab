extends SceneTree
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize():
 var base:=Rules.allocate(Rules.projectile_base("None"),{"size":0.5,"speed":0.5},"None",1.0)
 base.delivery_type="Touch"
 var single:=Rules.authored_stats(base,1.0,0.3,true)
 for contacts in [["hand_l"],["hand_l","hand_r"],["hand_l","hand_r","calf_l"]]:
  base.touch_contacts=contacts
  var expected:float=10.0*(1.0+0.25*(contacts.size()-1))
  var stats:=Rules.authored_stats(base,1.0,0.3,true)
  var spec:=Rules.author(base,1.0,0.3,true)
  assert(is_equal_approx(stats.stamina,expected) and is_equal_approx(spec.stamina_cost,expected))
  assert(spec.touch_contacts==contacts)
  for field in ["mana","physical_damage","burn_dps","amplifier","radius","velocity"]:
   assert(is_equal_approx(float(stats[field]),float(single[field])),"Contact count changed "+field)
 base.touch_contacts=["hand_l","hand_l","Head","head","mouth","foot_r","ball_r","unknown",4]
 assert(Rules.touch_contact_count(base)==3)
 base.delivery_type="Projectile"
 assert(Rules.authored_stats(base,1.0,0.3,true).stamina==10.0)
 var fire:=Rules.allocate(Rules.projectile_base("Fire"),{"size":0.0,"speed":0.0,"effect":1.0},"Fire",1.0)
 fire.delivery_type="Touch";fire.touch_contacts=["hand_l","hand_r"]
 var charged:=Rules.authored_stats(fire,1.0,0.3,true)
 assert(is_equal_approx(charged.stamina,2.5),"Effect transfer erased extra-contact stamina")
 fire.touch_contacts=["hand_l"]
 assert(is_equal_approx(charged.mana,Rules.authored_stats(fire,1.0,0.3,true).mana),"Extra stamina was transferred to mana")
 base.delivery_type="Touch";base.touch_contacts=["hand_l","hand_r"]
 for duration in [0.5,2.0,4.0]:
  assert(is_equal_approx(Rules.authored_stats(base,duration,0.3,true).stamina,Rules.physical(duration,true).stamina*1.25))
 print("TOUCH CONTACT COST PASS: 10/12.5/15 stamina, duplicate and alias deduplication, surcharge remains stamina after effect transfer, duration scaling, metadata retained, no damage/mana/amp changes")
 quit()
