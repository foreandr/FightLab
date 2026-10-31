extends RefCounted
var path:="user://animation_favorites.cfg"
var favorites:Dictionary={}
var sort_mode:=0
var manual_orders:Dictionary={}

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

func ordered(entries:Array,scope:String="") -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for entry in entries:
		if sort_mode==2 and not has(entry):continue
		result.append(entry)
	if sort_mode==3:
		var order:Array=manual_orders.get(scope,[])
		result.sort_custom(func(a:Dictionary,b:Dictionary):
			var a_index:=order.find(key(a))
			var b_index:=order.find(key(b))
			if a_index<0 and b_index>=0:return false
			if b_index<0 and a_index>=0:return true
			if a_index>=0 and b_index>=0 and a_index!=b_index:return a_index<b_index
			return str(a.get("title","" )).naturalnocasecmp_to(str(b.get("title","")))<0)
	else:
		result.sort_custom(func(a:Dictionary,b:Dictionary):
			if sort_mode!=1 and has(a)!=has(b):return has(a)
			return str(a.title).naturalnocasecmp_to(str(b.title))<0)
	return result

func reorder(entries:Array,scope:String,source_key:String,target_key:String) -> bool:
	if source_key==target_key:return false
	var ordered_keys:Array=[]
	for entry in entries:ordered_keys.append(key(entry))
	var from_index:=ordered_keys.find(source_key)
	var to_index:=ordered_keys.find(target_key)
	if from_index<0 or to_index<0:return false
	ordered_keys.remove_at(from_index)
	ordered_keys.insert(to_index,source_key)
	manual_orders[scope]=ordered_keys
	sort_mode=3
	save()
	return true

func load_state() -> void:
	if path.is_empty():return
	var cfg:=ConfigFile.new()
	if cfg.load(path)!=OK:return
	var ids=cfg.get_value("library","favorites",[])
	if ids is Array:
		for id in ids:favorites[str(id)]=true
	sort_mode=clampi(int(cfg.get_value("library","sort",0)),0,3)
	var orders=cfg.get_value("library","manual_orders",{})
	if orders is Dictionary:manual_orders=orders.duplicate(true)

func save() -> void:
	if path.is_empty():return
	var cfg:=ConfigFile.new()
	cfg.set_value("library","favorites",favorites.keys())
	cfg.set_value("library","sort",sort_mode)
	cfg.set_value("library","manual_orders",manual_orders)
	cfg.save(path)
