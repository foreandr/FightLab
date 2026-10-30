extends Control
## Compatibility redirect: Story now opens straight to the chapter book.

func _ready() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/story_opponents.tscn")
