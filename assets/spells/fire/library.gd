extends RefCounted
## Element-owned assets: every delivery type uses this exact same library.
const Burning=preload("res://assets/spells/fire/burning.gd")
const ELEMENT:="Fire"
const Styles=preload("res://assets/spells/fire/styles.gd")
const Sounds=preload("res://assets/spells/fire/sounds.gd")
const STYLE_TITLE:="Fire · Styles"
const SOUND_TITLE:="Fire · Sounds"
static func styles()->Array[Dictionary]:
 return Styles.entries()
static func sounds()->Array:
 return Sounds.ENTRIES.duplicate(true)
static func appearance(style_id:String,base:Dictionary={})->Dictionary:
 return Styles.look(style_id,base)
static func sound(id:String="")->String:
 return id if not Sounds.find(id).is_empty() else Sounds.DEFAULT_ID
static func selection(style_id:String,sound_id:String="",base:Dictionary={})->Dictionary:
 var look:=appearance(style_id,base)
 look["sound_id"]=sound(sound_id)
 return look
