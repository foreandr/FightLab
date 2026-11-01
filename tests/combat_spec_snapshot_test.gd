extends SceneTree
const Credits=preload("res://scripts/asset_provenance.gd")
const Spec=preload("res://scripts/combat_spec.gd")
const Rules=preload("res://scripts/combat_spell_rules.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var graph:=Credits.source({"title":"Original","clip":"source"},"spell")
 var nodes:Dictionary=graph.nodes
 for index in 500:
  nodes[str(index)]={"author":"foreandr","parents":["source"],"citations":[{"url":"https://example.com/"+str(index)}]}
 var original:=JSON.stringify(graph)
 var frozen:=Credits.snapshot(graph)
 assert(frozen.is_read_only() and frozen.nodes.is_read_only())
 assert(frozen.nodes["100"].parents.is_read_only() and frozen.nodes["100"].citations[0].is_read_only())
 assert(JSON.stringify(frozen)==original and not graph.is_read_only())
 var base:=Rules.allocate(Rules.projectile_base("Fire"),{"size":0.34,"speed":0.33,"effect":0.33},"Fire",1.0)
 base.provenance=frozen;base.appearance={"nested":{"values":[1,2,3]}}
 for index in 50:
  var authored:=Rules.author(base,1.0,0.3,true)
  var copy:=Spec.copy(authored)
  assert(is_same(copy.provenance,frozen))
  copy.appearance.nested.values[0]=99
  assert(base.appearance.nested.values[0]==1 and authored.appearance.nested.values[0]==1)
  var momentum:=Rules.Momentum.projectile(copy,Vector3(7,0,0),Vector3.FORWARD,10,10)
  assert(is_same(momentum.spec.provenance,frozen))
  assert(JSON.stringify(momentum.spec.provenance)==original)
 var mutable_copy:=Spec.copy({"provenance":graph})
 mutable_copy.provenance.nodes["100"].author="Different"
 assert(graph.nodes["100"].author=="foreandr")
 var derived:=Credits.derive([frozen],"spell","Edited","foreandr")
 assert(derived.nodes.size()==frozen.nodes.size()+1 and JSON.stringify(frozen)==original)
 print("COMBAT SPEC SNAPSHOT PASS: all 501 credit nodes and nested citations preserved, immutable sharing, editable gameplay isolation, mutable legacy inputs still copied, derivation preserved")
 quit()
