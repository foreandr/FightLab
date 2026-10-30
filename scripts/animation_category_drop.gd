extends Button
var editor
var group:="Motion"
var category:="Idle"
func _can_drop_data(_point:Vector2,data:Variant) -> bool:
	return data is Dictionary and data.get("entry",{}) is Dictionary and (bool(data.get("store_origin",false)) or data.entry.has("store_asset_id"))
func _drop_data(_point:Vector2,data:Variant) -> void:
	editor.take_store_animation(data.entry,group,category)
