extends RefCounted
## Shared, portable revision graph for animations and spells. Parent nodes are
## merged by ID, never nested repeatedly or discarded when a new author edits.
static func creator_name() -> String:
	return "foreandr"

static func source(entry:Dictionary,asset_type:="animation") -> Dictionary:
	if entry.get("provenance",{}) is Dictionary and not entry.get("provenance",{}).is_empty():return entry.provenance.duplicate(true)
	var clip:=str(entry.get("clip",entry.get("id",entry.get("name","local"))))
	if entry.has("source_animation"):clip="ual2/"+str(entry.source_animation)
	var source_id:="source:"+(asset_type+"|"+clip+"|"+str(entry.get("mirrored",false))+"|"+str(entry.get("path",""))).sha256_text()
	var citations:Array=[]
	var author:=""
	if clip.begins_with("ual1/") or clip.begins_with("ual2/"):
		author="Quaternius"
		citations.append({"author":"Quaternius","url":"https://quaternius.itch.io/universal-animation-library"+("-2" if clip.begins_with("ual2/") else ""),"license":"CC0 1.0","clip":clip})
	else:
		citations.append({"source":"FightLab project assets","clip":clip,"credits_file":"res://assets/combat/licenses/UPSTREAM-CREDITS.md","author":"Unspecified; consult source credits"})
	var node:Dictionary={"id":source_id,"asset_type":asset_type,"operation":"original source","title":entry.get("source_title",entry.get("title",entry.get("name",clip))),"author":author,"parents":[],"citations":citations}
	if entry.has("parent_path") or entry.has("based_on"):node["legacy_parent_reference"]=entry.get("based_on",{"name":entry.get("parent_name",""),"path":entry.get("parent_path","")})
	return {"schema":1,"head":source_id,"nodes":{source_id:node}}

static func derive(parents:Array,asset_type:String,title:String,author:String,operation:="modified") -> Dictionary:
	var nodes:Dictionary={}
	var parent_ids:Array=[]
	for parent in parents:
		if not parent is Dictionary:continue
		for key in parent.get("nodes",{}):nodes[key]=parent.nodes[key].duplicate(true)
		var head:=str(parent.get("head",""))
		if not head.is_empty() and head not in parent_ids:parent_ids.append(head)
	var id:="revision:"+Crypto.new().generate_random_bytes(16).hex_encode()
	nodes[id]={"id":id,"asset_type":asset_type,"operation":operation,"title":title,"author":author,"created_utc":Time.get_datetime_string_from_system(true),"parents":parent_ids,"citations":[]}
	return {"schema":1,"head":id,"nodes":nodes}

static func inspect_text(metadata:Dictionary) -> String:
	var lines:PackedStringArray=[]
	lines.append("Source and contributor history\n")
	for node in metadata.get("nodes",{}).values():
		lines.append("%s — %s\nBy: %s\nRevision: %s\nParents: %s"%[node.get("title","Asset"),node.get("operation",""),str(node.get("author","")).strip_edges() if not str(node.get("author","")).strip_edges().is_empty() else "Creator name not set",node.get("id",""),str(node.get("parents",[]))])
		for citation in node.get("citations",[]):lines.append("Source: "+JSON.stringify(citation))
		lines.append("")
	return "\n".join(lines)
