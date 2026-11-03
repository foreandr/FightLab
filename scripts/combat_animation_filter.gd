extends RefCounted
## Names and descriptions are evidence of relevance, never proof of rig quality.
const VOCABULARY="res://data/combat_animation_keywords.json"
const POLICY_VERSION:=3
const COMBAT_WORDS="punch punches punching jab jabs jabbing hook hooks hooking uppercut uppercuts backfist backfists hammerfist hammerfists haymaker haymakers elbow elbows elbowing knee knees kick kicks kicking roundhouse roundhouses sweep sweeps sweeping stomp stomps stomping headbutt headbutts headbutting lariat clothesline dropkick dropkicks teep nukite tetsui uraken tsuki zuki block blocks blocking guard guards guarding parry parries parrying deflect deflects deflecting defend defends defending defense defence counterattack counterattacks feint feints feinting dodge dodges dodging evade evades evading evasion sprawl sprawls sprawling combat fighting fight fights boxing boxer kickboxing karate wushu taekwondo taekwon aikido judo jujutsu jujitsu muaythai capoeira escrima silat kendo kenjutsu iaido fencing swordplay sparring takedown takedowns clinch clinching grapple grappling wrestle wrestling armbar choke chokes choking headlock suplex slam slams kata kumite kiai orthodox southpaw weapon weapons sword swords swordfight swordfighting slash slashes slashing thrust thrusts thrusting stab stabs stabbing spear spears staff staves quarterstaff polearm halberd glaive katana saber sabre rapier broadsword greatsword longsword dagger daggers knife knives knifing hatchet mace warhammer flail nunchaku nunchucks tonfa sickle scythe archery archer crossbow pistol pistols rifle rifles shotgun gun guns firearm firearms gunfire reload reloading grenade grenades gunshot sniper spell spells spellcast spellcasting magical mage sorcerer wizard fireball fireballs heal heals healing summon summons summoning incantation barrier barriers ward warding enchant telekinesis projectile"
var combat_terms:Dictionary={}
var terms:Dictionary={}
var tokenizer:=RegEx.new()
var camel:=RegEx.new()
func _init()->void:
 tokenizer.compile("[a-z]+")
 camel.compile("([a-z])([A-Z])")
 for term in COMBAT_WORDS.split(" ",false):combat_terms[term]=true
 for phrase in ["left cross","right cross","palm strike","body blow","body shot","hip throw","shoulder throw","arm drag","ground pound","ground and pound","martial arts","martial art","muay thai","kung fu","tai chi","tai ji","jiu jitsu","tae kwon do","self mend","force push","energy beam","bow shoot","bow aim","bow draw","bow release","hit chest","hit head","hit torso","hit reaction","shield break","guard break"]:combat_terms[phrase]=true
 var data=JSON.parse_string(FileAccess.get_file_as_string(VOCABULARY))
 if data is Dictionary:
  for term in data.get("terms",[]):terms[str(term)]=true
func matches(entry:Dictionary)->Array[String]:
 if excluded(entry):return []
 var text:=str(entry.get("title",""))+" "+str(entry.get("original_filename",""))+" "+str(entry.get("description",""))
 text=(camel.sub(text,"$1 $2",true)+" "+text).to_lower()
 var words:PackedStringArray=[]
 for found in tokenizer.search_all(text):words.append(found.get_string())
 var result:Array[String]=[]
 for start in words.size():
  var phrase:=""
  for stop in range(start,mini(start+5,words.size())):
   phrase+=(" " if stop>start else "")+words[stop]
   if combat_terms.has(phrase) and phrase not in result:result.append(phrase)
 return result
func excluded(entry:Dictionary)->bool:
 # This source's imported motions were rejected in playtesting. Identify it
 # through preserved provider credits as well as the catalog's display name.
 for field in ["source_name","store_creator","author"]:
  var provider:=str(entry.get(field,"")).to_lower()
  if provider.contains("mocapdata.com") or provider.contains("eyes japan") or provider.contains("eyes, japan"):return true
 # These collections are gait/style/acting studies, not combat captures.
 if str(entry.get("source_name","")) in ["100STYLE","Cologne Motion Capture Database","GetBVH dance library","MPI Emotional Body Expressions","InterHuman original recorded interactions","Bandai Namco Research"]:return true
 var text:=(str(entry.get("title",""))+" "+str(entry.get("original_filename",""))+" "+str(entry.get("source_name",""))).to_lower()
 for word in ["cowboy","conversation","chickenwalk","chicken walk","clumsywalk","clumsy walk","confidentwalk","confident walk","coolwalk","cool walk","farm harvest","farm plant","dance","dancing","ballet","soccer","baseball","tennis","basketball","golf"]:
  if text.contains(word):return true
 return false
func accepts(entry:Dictionary)->bool:
 if excluded(entry):return false
 # Preserve authored work, not unrelated Store downloads merely marked owned.
 if str(entry.get("path","")).begins_with("user://custom_animations/") and entry.get("frames",[]).size()>=2:return true
 # Compact Store rows retain the evidence found in the full source description.
 for evidence in entry.get("combat_keyword_matches",[]):
  if combat_terms.has(str(evidence)):return true
 return not matches(entry).is_empty()
