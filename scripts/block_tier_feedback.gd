extends Label3D
## Brief actor-owned block feedback shared by every combat mode.
var age:=1.0
const LIFETIME:=0.75
static func show_for(actor:Node3D,tier:int)->void:
 var label=actor.get_node_or_null("BlockTierFeedback")
 if not is_instance_valid(label):
  label=load("res://scripts/block_tier_feedback.gd").new();label.name="BlockTierFeedback";actor.add_child(label)
 label.age=0.0;label.visible=true;label.set_process(true)
 label.text=["","BLOCK","PERFECT","DIRECTIONAL PERFECT"][clampi(tier,0,3)]
 label.modulate=preload("res://scripts/self_barrier.gd").TIER_COLORS[clampi(tier-1,0,2)]
func _ready()->void:
 font=preload("res://assets/fonts/game_font.tres")
 billboard=BaseMaterial3D.BILLBOARD_ENABLED;no_depth_test=true
 font_size=24;pixel_size=0.007;outline_size=5;outline_modulate=Color("15202a")
func _process(delta:float)->void:
 age+=delta
 if age>=LIFETIME:visible=false;set_process(false);return
 global_position=get_parent().overhead_tag_position()+Vector3.UP*(0.65+age*0.3)
 modulate.a=1.0-smoothstep(0.25,LIFETIME,age)
