extends RefCounted
var path:="user://animation_favorites.cfg"
var favorites:Dictionary={}
var sort_mode:=0

static func key(entry:Dictionary) -> String:
	if not str(entry.get("path","")).is_empty():return "saved:"+str(entry.path)
	return "%s|%s|%s|%s|%s"%[entry.get("group",""),entry.get("category",""),entry.get("step",""),entry.get("clip",""),entry.get("mirrored",false)]

func has(entry:Dictionary) -> bool:
	return favorites.has(key(entry))

func toggle(entry:Dictionary) -> void:
	var id:=key(entry)
	if favorites.has(id):favorites.erase(id)
	else:favorites[id]=true
	save()

func ordered(entries:Array) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for entry in entries:
		if sort_mode==2 and not has(entry):continue
		result.append(entry)
	result.sort_custom(func(a:Dictionary,b:Dictionary):
		if sort_mode!=1 and has(a)!=has(b):return has(a)
		return str(a.title).naturalnocasecmp_to(str(b.title))<0)
	return result

func load_state() -> void:
	if path.is_empty():return
	var cfg:=ConfigFile.new()
	if cfg.load(path)!=OK:return
	var ids=cfg.get_value("library","favorites",[])
	if ids is Array:
		for id in ids:favorites[str(id)]=true
	sort_mode=clampi(int(cfg.get_value("library","sort",0)),0,2)

func save() -> void:
	if path.is_empty():return
	var cfg:=ConfigFile.new()
	cfg.set_value("library","favorites",favorites.keys())
	cfg.set_value("library","sort",sort_mode)
	cfg.save(path)
