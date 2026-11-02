extends RefCounted
## Local, named reusable definitions. Preview workspace state is saved separately.
const Definition=preload("res://scripts/spell_definition.gd")
var directory:="user://spells"
func entries()->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 if not DirAccess.dir_exists_absolute(directory):return result
 for file in DirAccess.get_files_at(directory):
  if not file.ends_with(".cfg"):continue
  var cfg:=ConfigFile.new()
  if cfg.load(directory.path_join(file))!=OK:continue
  var record:Dictionary=cfg.get_value("spell","definition",{})
  if Definition.error(record).is_empty() and record.has("id") and record.has("name"):result.append(record)
 result.sort_custom(func(a:Dictionary,b:Dictionary):return str(a.name).naturalnocasecmp_to(str(b.name))<0)
 return result
func save(name:String,definition:Dictionary,limiter_enabled:=true)->Dictionary:
 if not limiter_enabled:return {"ok":false,"error":"Turn Limiter on to save"}
 var title:=name.strip_edges()
 if title.is_empty():return {"ok":false,"error":"Give your spell a name"}
 if title.length()>64:return {"ok":false,"error":"Use a name of 64 characters or fewer"}
 var message:=Definition.error(definition)
 if not message.is_empty():return {"ok":false,"error":message}
 var existing:Array[Dictionary]=entries()
 var used:Dictionary={}
 for item in existing:used[str(item.name).to_lower()]=true
 var unique:=title;var index:=1
 while used.has(unique.to_lower()):
  var suffix:=" (%d)"%index
  unique=title.left(64-suffix.length())+suffix
  index+=1
 var record:=definition.duplicate(true)
 record["id"]=Crypto.new().generate_random_bytes(16).hex_encode()
 record["name"]=unique
 record["provenance"]=Definition.credit(record,unique)
 if DirAccess.make_dir_recursive_absolute(directory)!=OK:return {"ok":false,"error":"Could not open your spell folder"}
 var cfg:=ConfigFile.new();cfg.set_value("spell","definition",record)
 var target:=directory.path_join(record.id+".cfg")
 var temporary:=target+".tmp"
 if cfg.save(temporary)!=OK:return {"ok":false,"error":"Could not save spell"}
 if DirAccess.rename_absolute(temporary,target)!=OK:return {"ok":false,"error":"Could not finish saving spell"}
 return {"ok":true,"record":record}
func find(id:String)->Dictionary:
 for record in entries():
  if record.id==id:return record
 return {}
