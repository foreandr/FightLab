extends SceneTree
## Run headlessly at any time to refresh the resumable acquisition report.
const ROOT:="res://assets/animations/community"
func _initialize():
	var catalog=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"/catalog.json"))
	var validation=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"/validation.json")) if FileAccess.file_exists(ROOT+"/validation.json") else {}
	var sources:Dictionary={}
	var tags:Dictionary={}
	var licenses:Dictionary={}
	var categories:Dictionary={}
	var air_states:Dictionary={}
	for entry in catalog.get("entries",[]):
		var source:=str(entry.source_name)
		sources[source]=int(sources.get(source,0))+1
		var license_:=str(entry.license)
		licenses[license_]=int(licenses.get(license_,0))+1
		var category:=str(entry.get("category","Misc"))
		categories[category]=int(categories.get(category,0))+1
		var air_state:=str(entry.get("air_state","Unknown"))
		air_states[air_state]=int(air_states.get(air_state,0))+1
		for tag in entry.get("tags",[]):tags[str(tag)]=int(tags.get(str(tag),0))+1
	var indexed:=int(catalog.get("distinct_count",0))
	var verified:=int(validation.get("verified_cached",0))
	var failed_count:int=validation.get("failed",[]).size()
	var report={"goal":25000,"distinct_indexed":indexed,"verified_cached":verified,"failed_validation":failed_count,"validation_complete":bool(validation.get("complete",false)),"pending_validation":maxi(0,indexed-verified-failed_count),"validation":validation,"sources":sources,"categories":categories,"air_states":air_states,"tags":tags,"licenses":licenses,"rejected_files":catalog.get("rejected",[]),"shop_page_size":100,"updated_utc":Time.get_datetime_string_from_system(true),"counting_rule":"One original downloaded clip per source-file SHA-256. Alternate formats, mirrored copies and newly invented cuts are not counted.","resume_index":"Godot --headless --path . --script res://scripts/index_community_animations.gd","resume_validation":"Godot --headless --path . --script res://scripts/bake_community_animations.gd","refresh_report":"Godot --headless --path . --script res://scripts/community_animation_report.gd","raw_files":"res://assets/animations/community/raw","cache":"user://community_animations","catalog":"res://assets/animations/community/catalog.json","notes":["Classification and airborne state are inferred from source names and folders; review individual clips before using them in a finished game.","Bandai Namco and InterHuman entries are noncommercial. Filter with commercial:yes to restrict the shop to entries marked as commercially usable.","InterHuman contains original recorded two-person actor tracks, not generated InterGen outputs. Its source prohibits dataset redistribution.","HDM05's published coordinate conversion normalizes root translation; these entries carry pose-only and in-place tags.","Original source files remain preserved. Rejected and failed clips are excluded from the usable count.","Large downloaded files and local caches are excluded from Git; importer code, source URLs and source terms are tracked."]}
	var file:=FileAccess.open(ROOT+"/progress.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("COMMUNITY REPORT: ",report.distinct_indexed," distinct indexed; ",sources.size()," sources; validation ",validation.get("verified_cached",0))
	quit()
