extends SceneTree
## Recoverable removal from the active library. Original sources stay local.
const ROOT="res://assets/animations/community"
const Filter=preload("res://scripts/combat_animation_filter.gd")
func _initialize():call_deferred("run")
func run():
 var policy:=Filter.new()
 var manifest:=ROOT+"/catalog.json"
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(manifest))
 var archive:=ROOT+"/quarantine/noncombat-"+Time.get_datetime_string_from_system(true).replace(":","-")
 DirAccess.make_dir_recursive_absolute(archive)
 assert(DirAccess.copy_absolute(manifest,archive+"/catalog-before.json")==OK,"Cannot back up catalog")
 var kept:Array=[];var rejected:Array=[];var sources:Dictionary={}
 for entry in data.entries:
  var evidence:=policy.matches(entry)
  if not policy.accepts(entry):
   rejected.append({"entry":entry,"reason":"Not explicitly combat; generic locomotion/acrobatic/style material does not qualify"})
  else:
   entry["combat_keyword_matches"]=evidence
   kept.append(entry)
   sources[entry.source_name]=int(sources.get(entry.source_name,0))+1
 var record:=FileAccess.open(archive+"/removed.json",FileAccess.WRITE)
 record.store_string(JSON.stringify({"entries":rejected,"raw_sources_preserved":true}));record.close()
 var report={"before":data.entries.size(),"retained":kept.size(),"removed":rejected.size(),"vocabulary":policy.terms.size(),"strict_combat_terms":policy.combat_terms.size(),"sources":sources,"backup":archive,"method":"Explicit combat evidence only; generic movement, acrobatics and character-style gestures excluded"}
 data.entries=kept;data.distinct_count=kept.size();data.combat_curation=report
 var output:=FileAccess.open(manifest+".pending",FileAccess.WRITE);output.store_string(JSON.stringify(data));output.close()
 assert(DirAccess.rename_absolute(ProjectSettings.globalize_path(manifest+".pending"),ProjectSettings.globalize_path(manifest))==OK)
 var report_file:=FileAccess.open("res://work/combat_curation_report.json",FileAccess.WRITE);report_file.store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit()
