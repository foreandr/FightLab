extends RefCounted
## Names and descriptions are evidence of relevance, never proof of rig quality.
const VOCABULARY="res://data/combat_animation_keywords.json"
var terms:Dictionary={}
var tokenizer:=RegEx.new()
var camel:=RegEx.new()
func _init()->void:
 tokenizer.compile("[a-z]+")
 camel.compile("([a-z])([A-Z])")
 var data=JSON.parse_string(FileAccess.get_file_as_string(VOCABULARY))
 if data is Dictionary:
  for term in data.get("terms",[]):terms[str(term)]=true
func matches(entry:Dictionary)->Array[String]:
 var text:=str(entry.get("title",""))+" "+str(entry.get("original_filename",""))+" "+str(entry.get("description",""))
 text=(camel.sub(text,"$1 $2",true)+" "+text).to_lower()
 var words:PackedStringArray=[]
 for found in tokenizer.search_all(text):words.append(found.get_string())
 var result:Array[String]=[]
 for start in words.size():
  var phrase:=""
  for stop in range(start,mini(start+5,words.size())):
   phrase+=(" " if stop>start else "")+words[stop]
   if terms.has(phrase) and phrase not in result:result.append(phrase)
 return result
func accepts(entry:Dictionary)->bool:
 # Compact Store rows retain the evidence found in the full source description.
 for evidence in entry.get("combat_keyword_matches",[]):
  if terms.has(str(evidence)):return true
 return not matches(entry).is_empty()
