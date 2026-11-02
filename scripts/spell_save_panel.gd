extends VBoxContainer
signal save_requested(name:String)
signal back_requested
var name_input:LineEdit
var save_button:Button
var status:Label
func setup(book_theme:Theme)->void:
 theme=book_theme;add_theme_constant_override("separation",8)
 var title:=Label.new();title.text="Save spell";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_size_override("font_size",26);add_child(title)
 name_input=LineEdit.new();name_input.name="SpellName";name_input.placeholder_text="Spell name";name_input.max_length=64;add_child(name_input)
 save_button=Button.new();save_button.name="SaveNamedSpell";save_button.text="Save";add_child(save_button)
 save_button.pressed.connect(func():save_requested.emit(name_input.text))
 name_input.text_submitted.connect(func(_text:String):
  if not save_button.disabled:save_requested.emit(name_input.text))
 status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(status)
 var back:=Button.new();back.text="← Back";add_child(back);back.pressed.connect(func():back_requested.emit())
 name_input.text_changed.connect(func(value:String):save_button.disabled=value.strip_edges().is_empty())
 save_button.disabled=true
func refresh(can_save:bool)->void:
 name_input.editable=can_save
 save_button.disabled=not can_save or name_input.text.strip_edges().is_empty()
 if not can_save:status.text="Turn Limiter on to save"
 elif status.text=="Turn Limiter on to save":status.text=""
