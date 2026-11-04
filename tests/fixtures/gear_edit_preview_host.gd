extends "res://scripts/story_loadout.gd"
# Exercise the actual edit UI without reading/writing the player's save file.
func _ready():
 profile={"name":"Transition test","body":"Masculine","skin":"Dark","skin_color":Color("925438"),"wardrobe_shirt":"Peasant","wardrobe_pants":"Peasant","wardrobe_arms":"Peasant","wardrobe_boots":"Peasant"}
 _ensure_slots()
 _build_ui()
