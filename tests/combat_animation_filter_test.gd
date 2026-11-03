extends SceneTree
func _initialize():
 var policy=preload("res://scripts/combat_animation_filter.gd").new()
 assert(policy.terms.size()>=2000)
 for title in ["Block Crouch","LeftCross","Roundhouse_Kick_03","Headbutt","sword_parry_and_riposte","Muay Thai Knee Clinch","falling hit reaction","self mend"]:
  assert(policy.accepts({"title":title}),"Combat move rejected: "+title)
 for title in ["cowboy angry walking shooting","Chicken Walk","ClumsyWalk","CoolWalk","Conversation","Female1 D6 CartWheel","Sprint loop","Walk backwards","Backflip Copy","crossing the street","shopping cart","arm raise","head turn","desk work","dance ballet","washing dishes","Interaction 00453","neutral t pose"]:
  assert(not policy.accepts({"title":title,"tags":["punch"],"category":"Block"}),"Irrelevant move accepted: "+title)
 var data={"nodes":[{"name":"Hips","parent":-1},{"name":"LeftLeg","parent":0},{"name":"LeftShin","parent":1},{"name":"LeftFoot","parent":2},{"name":"Spine1","parent":0},{"name":"Spine2","parent":4},{"name":"Chest","parent":5}]}
 var mapping=preload("res://scripts/community_bvh.gd").mapping(data)
 assert(mapping.thigh_l==1 and mapping.calf_l==2 and mapping.spine_01==4 and mapping.spine_02==5)
 print("COMBAT FILTER PASS: ",policy.terms.size()," terms, word boundaries, camel case, metadata false positives, alternate leg rig")
 quit()
