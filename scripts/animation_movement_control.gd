extends VBoxContainer
## Required animation declaration, shared by authoring, demo and import controls.
signal value_changed(value:String)
const Type=preload("res://scripts/animation_cast_type.gd")
var menu:OptionButton
var note:Label
var composition:Label
func _init() -> void:
 name="AnimationType"
 add_theme_constant_override("separation",4)
 var caption:=Label.new()
 caption.text="Animation type"
 caption.add_theme_font_size_override("font_size",15)
 add_child(caption)
 menu=OptionButton.new()
 menu.name="AnimationTypeChoice"
 menu.add_item("Choose type…")
 menu.set_item_disabled(0,true)
 for type_ in Type.TYPES:menu.add_item(type_)
 menu.focus_mode=Control.FOCUS_ALL
 add_child(menu)
 note=Label.new()
 note.add_theme_font_size_override("font_size",13)
 note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(note)
 composition=Label.new()
 composition.add_theme_font_size_override("font_size",13)
 composition.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(composition)
 composition.hide()
 menu.item_selected.connect(func(index:int):
  var type_:String=Type.TYPES[index-1]
  set_value(type_)
  value_changed.emit(type_))
 set_value("")
func set_value(type_:String) -> void:
 type_=Type.normalize(type_)
 menu.select(Type.TYPES.find(type_)+1)
 note.text=Type.description(type_)

func set_components(profile:Dictionary) -> void:
 var types:=Type.component_types(profile)
 composition.text="Composition: "+" + ".join(types)
 composition.visible=types.size()>1
