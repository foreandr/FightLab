extends CanvasLayer
## Semantic keyboard control and automation. Never moves the operating-system pointer.
var panel: PanelContainer
var search: LineEdit
var results: ItemList
var value_edit: LineEdit
var hint: Label
var entries: Array[Dictionary]=[]
var shown: Array[Dictionary]=[]
var carried: Dictionary={}
var previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var previous_pause := false
var dirty := true
var refresh_elapsed := 0.0

func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 layer=120
 panel=PanelContainer.new()
 var style := StyleBoxFlat.new()
 style.bg_color=Color("15202b")
 style.border_color=Color("668ba5")
 style.set_border_width_all(2)
 style.set_corner_radius_all(8)
 style.content_margin_left=18
 style.content_margin_right=18
 style.content_margin_top=16
 style.content_margin_bottom=16
 panel.add_theme_stylebox_override("panel",style)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 panel.offset_left=70
 panel.offset_top=50
 panel.offset_right=-70
 panel.offset_bottom=-50
 add_child(panel)
 var column := VBoxContainer.new()
 panel.add_child(column)
 var title := Label.new()
 title.text="KEYBOARD ACTIONS · F10 / Esc closes"
 title.add_theme_font_size_override("font_size",24)
 column.add_child(title)
 search=LineEdit.new()
 search.placeholder_text="Type an action name; Up/Down selects, Enter runs"
 search.text_changed.connect(func(_text):_filter())
 search.gui_input.connect(_search_key)
 column.add_child(search)
 results=ItemList.new()
 results.size_flags_vertical=Control.SIZE_EXPAND_FILL
 results.item_activated.connect(func(index):_choose(index))
 results.item_selected.connect(func(_index):value_edit.text="")
 column.add_child(results)
 value_edit=LineEdit.new()
 value_edit.placeholder_text="New value for settings / text / color (#RRGGBB); Enter applies"
 value_edit.text_submitted.connect(func(_text):_choose(results.get_selected_items()[0] if results.is_anything_selected() else 0,true))
 column.add_child(value_edit)
 hint=Label.new()
 hint.text="Tab / Shift+Tab moves between fields. Pick up an item, then search for a compatible Place action."
 hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(hint)
 panel.hide()
 get_tree().tree_changed.connect(func():dirty=true)

func _process(delta: float) -> void:
 refresh_elapsed+=delta
 if dirty and refresh_elapsed>0.15:
  dirty=false
  refresh_elapsed=0
  _prepare(get_tree().root)

func _prepare(node: Node) -> void:
 if node==self:return
 if node is BaseButton or node is Slider or node is SpinBox or node is LineEdit or node is TextEdit or node is ItemList or node is Tree or node is TabBar:
  node.focus_mode=Control.FOCUS_ALL
 for child in node.get_children():_prepare(child)

func _input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_F10:
  if panel.visible:_close()
  else:_open()
  get_viewport().set_input_as_handled()
 elif panel.visible and event.keycode==KEY_ESCAPE:
  _close()
  get_viewport().set_input_as_handled()

func _open() -> void:
 previous_pause=get_tree().paused
 get_tree().paused=true
 previous_mouse_mode=Input.mouse_mode
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 list_actions()
 panel.show()
 search.text=""
 value_edit.text=""
 _filter()
 search.grab_focus()

func _close() -> void:
 panel.hide()
 get_tree().paused=previous_pause
 Input.mouse_mode=previous_mouse_mode

func _search_key(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed:return
 var selected := results.get_selected_items()[0] if results.is_anything_selected() else 0
 if event.keycode in [KEY_UP,KEY_DOWN] and not shown.is_empty():
  selected=posmod(selected+(-1 if event.keycode==KEY_UP else 1),shown.size())
  results.select(selected)
  results.ensure_current_is_visible()
  search.accept_event()
 elif event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
  _choose(selected)
  search.accept_event()

func _filter() -> void:
 results.clear()
 shown.clear()
 for entry in entries:
  if search.text.is_empty() or search.text.to_lower() in str(entry.label).to_lower():
   shown.append(entry)
   results.add_item(entry.label)
 if not shown.is_empty():results.select(0)

func _choose(index: int, apply_value := false) -> void:
 if index<0 or index>=shown.size():return
 var entry: Dictionary=shown[index]
 if entry.kind in ["range","text","color","timeline_move"] and value_edit.text.is_empty() and not apply_value:
  value_edit.grab_focus()
  return
 var result := activate(str(entry.id),value_edit.text)
 if not result.ok:
  hint.text=str(result.error)
 elif entry.kind in ["pick","drop"]:
  list_actions()
  search.text="Place" if entry.kind=="pick" else ""
  _filter()
 else:_close()

func list_actions() -> Array[Dictionary]:
 entries.clear()
 _collect(get_tree().root)
 var output: Array[Dictionary]=[]
 for entry in entries:output.append({"id":entry.id,"label":entry.label,"kind":entry.kind})
 return output

func _label(node: Node) -> String:
 var own := str(node.get("text")) if _property(node,"text") else str(node.name)
 if own.is_empty():own=str(node.name)
 var parent := node.get_parent()
 if parent!=null:
  var siblings := parent.get_children()
  for i in range(node.get_index()-1,-1,-1):
   if siblings[i] is Label and not siblings[i].text.is_empty():
    own=siblings[i].text+" / "+own
    break
 return own.replace("\n"," ").left(150)

func _property(node: Object, name_: String) -> bool:
 for property in node.get_property_list():
  if property.name==name_:return true
 return false

func _add(node: Node, kind: String, label_: String, extra: Variant=null) -> void:
 entries.append({"id":str(node.get_instance_id())+":"+kind+":"+str(entries.size()),"node":node,"kind":kind,"label":label_,"extra":extra})

func _collect(node: Node) -> void:
 if node==self:return
 if node is Window and not node.visible:return
 if node is Control:
  if not node.is_visible_in_tree():return
  var label_ := _label(node)
  if node is OptionButton:
   if not node.disabled:
    for i in node.item_count:
     if not node.is_item_disabled(i):_add(node,"option",label_+" → "+node.get_item_text(i),i)
  elif node is MenuButton:
   var popup: PopupMenu=node.get_popup()
   for i in popup.item_count:
    if not popup.is_item_disabled(i) and not popup.is_item_separator(i):_add(popup,"menu",label_+" → "+popup.get_item_text(i),popup.get_item_id(i))
  elif node is ColorPickerButton:
   if not node.disabled:_add(node,"color","Set color / "+label_)
  elif node is BaseButton:
   if not node.disabled:_add(node,"button",label_)
  elif node is Slider or node is SpinBox:
   _add(node,"range","Set value / "+label_)
  elif node is LineEdit or node is TextEdit:
   if node.editable:
    _add(node,"text","Edit / "+label_)
    _add(node,"focus","Focus text field / "+label_)
  elif node is TabContainer:
   for i in node.get_tab_count():
    if not node.is_tab_disabled(i) and not node.is_tab_hidden(i):_add(node,"tab",label_+" → "+node.get_tab_title(i),i)
  elif node is ItemList:
   for i in node.item_count:
    if not node.is_item_disabled(i):_add(node,"item",label_+" → "+node.get_item_text(i),i)
  elif node.focus_mode==Control.FOCUS_ALL:
   _add(node,"focus","Focus / "+label_)
  var payload: Dictionary={}
  if _property(node,"drag_payload") and node.get("drag_payload") is Dictionary:payload=node.get("drag_payload")
  elif _property(node,"entry") and node.get("entry") is Dictionary and not node.get("entry").is_empty():
   payload={"type":"fightlab_animation_clip","entry":node.get("entry")}
  if not payload.is_empty():_add(node,"pick","Pick up / "+label_,payload.duplicate(true))
  if not carried.is_empty() and node.has_method("_can_drop_data") and node.call("_can_drop_data",Vector2.ZERO,carried):
   _add(node,"drop","Place / "+label_)
  if _property(node,"clip_id") and _property(node,"editor"):
   _add(node,"timeline_select","Select timeline clip / "+label_)
   _add(node,"timeline_remove","Remove timeline clip / "+label_)
   _add(node,"timeline_move","Move timeline clip (TRACK,SECONDS) / "+label_)
  if node.has_method("add_point") and _property(node,"points"):_add(node,"focus","Draw with keyboard / "+label_)
 for child in node.get_children():_collect(child)

func activate(id: String, value: Variant="") -> Dictionary:
 var was_open := panel.visible
 if was_open:get_tree().paused=previous_pause
 var result := _activate_action(id,value)
 if was_open:
  previous_pause=get_tree().paused
  get_tree().paused=true
 return result

func _activate_action(id: String, value: Variant="") -> Dictionary:
 var found: Dictionary={}
 for entry in entries:
  if entry.id==id:found=entry;break
 if found.is_empty() or not is_instance_valid(found.node):return {"ok":false,"error":"Action no longer exists. List actions again."}
 var node: Node=found.node
 if node is Control and not node.is_visible_in_tree():return {"ok":false,"error":"Control is hidden."}
 if node is BaseButton and node.disabled:return {"ok":false,"error":"Control is disabled."}
 match found.kind:
  "button":
   if node is Button and node.toggle_mode:
    node.button_pressed=true if node.button_group!=null and not node.button_group.allow_unpress else not node.button_pressed
   node.emit_signal("pressed")
  "option":node.select(found.extra);node.emit_signal("item_selected",found.extra)
  "menu":node.emit_signal("id_pressed",found.extra)
  "tab":node.current_tab=found.extra
  "item":node.select(found.extra);node.emit_signal("item_selected",found.extra);node.emit_signal("item_activated",found.extra)
  "range":
   if not str(value).is_valid_float():return {"ok":false,"error":"Enter a number."}
   node.value=clampf(float(value),node.min_value,node.max_value)
  "text":
   node.text=str(value)
   if node is LineEdit:node.emit_signal("text_changed",node.text);node.emit_signal("text_submitted",node.text)
   else:node.emit_signal("text_changed")
  "color":
   if not Color.html_is_valid(str(value)):return {"ok":false,"error":"Enter a color such as #88AAFF."}
   node.color=Color.html(str(value));node.emit_signal("color_changed",node.color)
  "pick":carried=found.extra.duplicate(true)
  "drop":
   if not node.call("_can_drop_data",Vector2.ZERO,carried):return {"ok":false,"error":"This target does not accept the item."}
   node.call("_drop_data",Vector2.ZERO,carried)
   carried={}
  "timeline_select":node.editor.select_timeline_clip(node.clip_id)
  "timeline_remove":node.editor.remove_timeline_clip(node.clip_id)
  "timeline_move":
   var pieces := str(value).split(",")
   if pieces.size()!=2 or not pieces[1].strip_edges().is_valid_float():return {"ok":false,"error":"Enter TRACK,SECONDS, for example BODY,0.5."}
   var track := pieces[0].strip_edges().to_upper()
   if track not in node.editor.TIMELINE_TRACKS:return {"ok":false,"error":"Unknown timeline track."}
   node.editor.move_timeline_clip(node.clip_id,track,maxf(0,float(pieces[1])))
  "focus":node.grab_focus()
  _:return {"ok":false,"error":"Unknown action."}
 return {"ok":true,"action":found.label}

func send_key(key: String, pressed := true, ctrl := false, shift := false, alt := false) -> Dictionary:
 var aliases := {"KP_0":KEY_KP_0,"KP_1":KEY_KP_1,"KP_2":KEY_KP_2,"KP_3":KEY_KP_3,"KP_4":KEY_KP_4,"KP_5":KEY_KP_5,"KP_6":KEY_KP_6,"KP_7":KEY_KP_7,"KP_8":KEY_KP_8,"KP_9":KEY_KP_9,"KP_ENTER":KEY_KP_ENTER,"KP_ADD":KEY_KP_ADD,"KP_SUBTRACT":KEY_KP_SUBTRACT}
 var code: int=aliases.get(key.to_upper(),OS.find_keycode_from_string(key))
 if code==KEY_NONE:return {"ok":false,"error":"Unknown key: "+key}
 var event := InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=pressed
 event.ctrl_pressed=ctrl
 event.shift_pressed=shift
 event.alt_pressed=alt
 Input.parse_input_event(event)
 return {"ok":true}
