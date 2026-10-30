extends RefCounted
const PAIRS={
 "Fire":{"Water":"Evaporates water into steam.","Ice":"Melts solid ice back into water.","Wind":"Wind amplifies flames and burn damage.","Lightning":"No elemental reaction.","Earth":"Leaves briefly burning ground around earth; touching it burns."},
 "Water":{"Fire":"Extinguishes flames; fire evaporates it into steam.","Ice":"Freezes into solid, breakable ice.","Wind":"No direct water reaction; wind moves floating debris.","Lightning":"Conducts electricity and stuns everyone touching it.","Earth":"Collects around walls; broken earth debris can float."},
 "Ice":{"Fire":"Melts back into water.","Water":"Freezes the affected water solid through its depth.","Wind":"No elemental reaction; strong impacts can break ice.","Lightning":"No elemental reaction; impact damage can break ice.","Earth":"No elemental reaction; collisions can break ice."},
 "Wind":{"Fire":"Amplifies flames and burning ground.","Water":"No direct water reaction; moves floating debris.","Ice":"No elemental reaction; impact damage can break ice.","Lightning":"No elemental reaction.","Earth":"Throws debris from broken earth walls."},
 "Lightning":{"Fire":"No elemental reaction.","Water":"Electrifies water, stunning enemies, allies and caster, even underwater.","Ice":"No elemental reaction; impact damage can break ice.","Wind":"No elemental reaction.","Earth":"No elemental reaction; impact damage can break walls."},
 "Earth":{"Fire":"Fire leaves burning ground around the wall.","Water":"Water collects around walls; broken debris can float.","Ice":"No elemental reaction; collisions can break ice.","Wind":"Wind throws debris after the wall breaks.","Lightning":"No elemental reaction; impact damage can break walls."}}
static func tooltip(element:String) -> String:
 var text:String=element
 for other in ["Fire","Water","Ice","Wind","Lightning","Earth"]:
  if other!=element:text+="\n- "+other+": "+str(PAIRS[element][other])
 return text
