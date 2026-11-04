extends SceneTree
const Character = preload("res://scripts/story_character.gd")
const Prepared = preload("res://scripts/prepared_character_preview.gd")
const Reviewed = preload("res://scripts/curated_wardrobe.gd")
func _initialize(): call_deferred("run")
func run():
	var library=root.get_node("WardrobeLibrary")
	library.request()
	while not library.loaded: await process_frame
	assert(library.archive_total>23000,"Raw archive must remain available")
	assert(library.total>=90 and library.total<=100)
	for entries in library.slots.values():
		for item in entries:
			assert(not Reviewed.item(item.value).is_empty())
			for image_path in item.preview_images.values(): assert(FileAccess.file_exists(image_path))
	var a=Character.new();a.prepared_preview_enabled=true;root.add_child(a)
	var b=Character.new();b.prepared_preview_enabled=true;root.add_child(b)
	var profile={"body":"Masculine","hair":"Short","wardrobe_shirt":"Peasant","wardrobe_arms":"Peasant","wardrobe_pants":"Peasant","wardrobe_boots":"Peasant"}
	a.set_profile(profile);b.set_profile(profile)
	assert(Prepared.hits>0)
	assert(a.skeleton!=b.skeleton)
	assert(a.animator.get_animation_library("ual1")!=b.animator.get_animation_library("ual1"))
	assert(a.animator.get_animation("ual1/Punch_Jab")==b.animator.get_animation("ual1/Punch_Jab"),"Immutable clips should be reused")
	a.animator.play("ual1/Punch_Jab",0);a.animator.advance(0);a.animator.seek(0.25,true);a.animator.pause()
	b.animator.play("ual1/Idle",0);b.animator.advance(0);b.animator.seek(0.1,true);b.animator.pause()
	var hand=a.skeleton.find_bone("hand_l")
	assert(a.skeleton.get_bone_global_pose(hand).origin.distance_to(b.skeleton.get_bone_global_pose(hand).origin)>0.02,"Cached rigs must animate independently")
	var original=b.model.find_child("*Body*",true,false)
	assert(a.set_wardrobe_size("wardrobe_shirt",1.25))
	assert(not b.profile.has("top_size"),"Changing one preview must not edit another profile")
	var times=[]
	for i in 15:
		var start=Time.get_ticks_usec();b.set_profile(profile);times.append((Time.get_ticks_usec()-start)/1000.0)
	for i in 12:
		var variant=profile.duplicate();variant.hair_color=Color(float(i)/12.0,0.1,0.2);b.set_profile(variant)
	assert(Prepared.scenes.size()<=8)
	assert(Character.wardrobe_mesh_cache.size()<=96 and Character.head_mesh_cache.size()<=32)
	print("CURATED WARDROBE PASS: reviewed=",library.total," raw=",library.archive_total," independent animation, live size, bounded caches; warm_ms=",times)
	a.queue_free();b.queue_free();await process_frame
	quit()
