extends SceneTree
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> bool:
	if ok:return true
	push_error("COMBAT HITBOXES FAILED: "+message)
	quit(1)
	return false
func run() -> void:
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.preview_preferences_path="user://logs/combat_hitbox_preferences.cfg"
	b.open_projectile_workspace()
	b.playing=false;b.clear_shots()
	b.set_preview_hitboxes(false)
	var field=editor.field
	var actor=editor.actor
	var collider:CollisionShape3D=b.practice_human.targets[0][0].get_child(0)
	var dummy_shape:CollisionShape3D=b.editor.target.practice_dummy_visual.hurtboxes[0].get_child(0)
	var original_radius:float=collider.shape.radius
	var layer:int=collider.get_parent().collision_layer
	var key:=InputEventKey.new();key.physical_keycode=KEY_2;key.pressed=true
	b._input(key)
	if not check(b.preview_hitboxes and field.character_hitbox_overlays.enabled,"2 does not enable receive hitboxes"):return
	var self_outline:MeshInstance3D=collider.get_node_or_null("ReceiveHitbox")
	var dummy_outline:MeshInstance3D=dummy_shape.get_node_or_null("ReceiveHitbox")
	if not check(is_instance_valid(self_outline) and self_outline.visible and is_instance_valid(dummy_outline) and dummy_outline.visible,"Human/dummy receiving outlines missing"):return
	var inactive_shape:CollisionShape3D=actor.targets[0][0].get_child(0)
	if inactive_shape.get_parent().collision_layer==0:
		if not check(not inactive_shape.has_node("ReceiveHitbox"),"Inactive receiving shape is drawn as active"):return
	var human_shape:CollisionShape3D=b.practice_human.targets[0][0].get_child(0)
	if not check(human_shape.has_node("ReceiveHitbox"),"Human receiving outline missing"):return
	if not check(self_outline.mesh.get_aabb().size.distance_to(Vector3(original_radius*2,collider.shape.height,original_radius*2))<0.001,"Receive outline does not match collision dimensions"):return
	var before:Vector3=dummy_outline.global_position
	dummy_shape.position+=Vector3.RIGHT*0.2
	if not check(dummy_outline.global_position.distance_to(before)>0.19,"Receiving hitbox does not follow shape"):return
	dummy_shape.position-=Vector3.RIGHT*0.2
	collider.shape.radius=original_radius*1.1
	field.character_hitbox_overlays.refresh()
	if not check(self_outline.mesh.get_aabb().size.distance_to(Vector3(collider.shape.radius*2,collider.shape.height,collider.shape.radius*2))<0.001,"Changed shape not reflected in overlay"):return
	collider.shape.radius=original_radius
	field.spawn_projectile(actor,{"id":"outline_test","effect":"orb","hand":"hand_r","damage":10.0,"aim_direction":Vector3.BACK},Vector3(0,2,0))
	var shot:Dictionary=field.shots.back()
	if not check(is_instance_valid(shot.hitbox_outline) and shot.hitbox_outline.visible,"Send hitbox not enabled with receive hitboxes"):return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://logs/combat_hitboxes.png")
	b._input(key)
	if not check(not b.preview_hitboxes and not self_outline.visible and not dummy_outline.visible and not shot.hitbox_outline.visible,"2 does not hide both sets"):return
	if not check(is_equal_approx(float(collider.shape.radius),original_radius) and collider.get_parent().collision_layer==layer and not collider.disabled,"Toggle changed gameplay collisions"):return
	print("COMBAT HITBOXES PASSED: 2 toggles sending and receiving shapes together, dummy/human, inactive shapes hidden, exact geometry, transform/shape updates, no collision changes")
	quit()
