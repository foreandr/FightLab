extends AcceptDialog
## Frozen policy comparisons; the live learner remains separate.
var host:Node
var choices:Array[OptionButton]=[]
var status:Label
var was_paused:=false
func setup(world:Node)->void:
 host=world;title="AI models";theme=host.hud.theme
 ok_button_text="Fight selected";dialog_hide_on_ok=false
 var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",12);add_child(layout)
 for side in ["Red","Blue"]:
  var row:=HBoxContainer.new();layout.add_child(row)
  var caption:=Label.new();caption.text=side;caption.custom_minimum_size.x=60;row.add_child(caption)
  var choice:=OptionButton.new();choice.custom_minimum_size.x=390;choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  choice.fit_to_longest_item=false;choice.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  choice.add_theme_font_size_override("font_size",14);choice.get_popup().add_theme_font_size_override("font_size",14)
  row.add_child(choice);choices.append(choice)
 var actions:=HFlowContainer.new();layout.add_child(actions)
 host.button(actions,"Save current",save_current)
 host.button(actions,"Resume learning",func():host.resume_model_learning();hide())
 status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size.x=450;status.add_theme_font_size_override("font_size",14);layout.add_child(status)
 confirmed.connect(fight)
 visibility_changed.connect(func():
  if not visible and not was_paused and host.paused:host.toggle_pause())
func open()->void:
 was_paused=host.paused
 if not host.paused:host.toggle_pause()
 refresh();status.text="Saved models fight without learning. Automatic save every 10 matches."
 popup_centered(Vector2i(570,260))
func refresh()->void:
 var models:Array=host.learning_store.snapshots()
 for choice in choices:
  var previous:=str(choice.get_item_metadata(choice.selected)) if choice.item_count>0 else ""
  choice.clear();choice.add_item("Current learner · %d matches (frozen)"%int(host.learning_store.data.matches));choice.set_item_metadata(0,"")
  for model in models:
   choice.add_item("%d matches · %s · %s"%[model.matches,model.created_at.replace("T"," "),model.caption])
   choice.set_item_metadata(choice.item_count-1,model.path)
   if model.path==previous:choice.select(choice.item_count-1)
func save_current()->void:
 var result:Dictionary=host.learning_store.save_snapshot("Manual")
 status.text="Saved current model · %d matches"%int(result.matches) if not result.is_empty() else host.learning_store.snapshot_error
 refresh()
func fight()->void:
 if host.start_model_match(str(choices[0].get_item_metadata(choices[0].selected)),str(choices[1].get_item_metadata(choices[1].selected))):hide()
 else:status.text=host.learning_store.snapshot_error
