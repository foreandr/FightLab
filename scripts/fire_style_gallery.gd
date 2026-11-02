extends VBoxContainer
## Only the visible page owns thumbnail worlds. UPDATE_ONCE renders the actual
## shared spell visual, then keeps a static image without per-frame rendering.
signal style_chosen(id:String)
const Catalog=preload("res://assets/spells/fire/styles.gd")
const Appearance=preload("res://scripts/spell_appearance.gd")
const PAGE_SIZE:=12
var page:=0
var choices:Dictionary={}
var previews:Array[SubViewport]=[]
var grid:GridContainer
var previous_button:Button
var next_button:Button
var page_label:Label
var page_input:SpinBox
var selected_id:=""
var base_look:Dictionary={}
var columns:=4
func setup(book_theme:Theme) -> void:
 theme=book_theme
 add_theme_constant_override("separation",6)
 var heading:=HBoxContainer.new()
 add_child(heading)
 var title:=Label.new();title.text="Flame styles · %d"%Catalog.entries().size();title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 title.add_theme_font_size_override("font_size",18);heading.add_child(title)
 grid=GridContainer.new();grid.columns=columns
 grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);add_child(grid)
 var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",6);add_child(footer)
 previous_button=Button.new();previous_button.text="← Prev";previous_button.focus_mode=Control.FOCUS_ALL
 previous_button.add_theme_font_size_override("font_size",13)
 footer.add_child(previous_button);previous_button.pressed.connect(func():set_page(page-1))
 page_input=SpinBox.new();page_input.min_value=1;page_input.max_value=page_count();page_input.step=1;page_input.custom_minimum_size.x=62
 page_input.add_theme_icon_override("updown",preload("res://scripts/animation_row_icons.gd").get_icon("length_arrows"))
 page_input.add_theme_font_size_override("font_size",13);page_input.focus_mode=Control.FOCUS_ALL;page_input.tooltip_text="Page"
 footer.add_child(page_input);page_input.value_changed.connect(func(value:float):set_page(int(value)-1))
 page_label=Label.new();page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(page_label)
 next_button=Button.new();next_button.text="Next →";next_button.focus_mode=Control.FOCUS_ALL
 next_button.add_theme_font_size_override("font_size",13)
 footer.add_child(next_button);next_button.pressed.connect(func():set_page(page+1))
func page_count() -> int:return maxi(1,ceili(Catalog.entries().size()/float(PAGE_SIZE)))
func open_styles(custom:Dictionary,width:float) -> void:
 base_look=custom.duplicate(true)
 selected_id=Catalog.active_id(custom)
 columns=4 if width>=370 else 3
 grid.columns=columns
 var index:=0
 for i in Catalog.entries().size():
  if Catalog.entries()[i].id==selected_id:index=i;break
 set_page(floori(index/float(PAGE_SIZE)))
func set_page(value:int) -> void:
 page=clampi(value,0,page_count()-1)
 choices.clear();previews.clear()
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 var group:=ButtonGroup.new()
 var entries:=Catalog.entries()
 for i in range(page*PAGE_SIZE,mini((page+1)*PAGE_SIZE,entries.size())):
  var entry:Dictionary=entries[i]
  var button:=Button.new()
  button.name="FireStyle_"+str(entry.id)
  button.custom_minimum_size=Vector2(82,108)
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.focus_mode=Control.FOCUS_ALL;button.toggle_mode=true;button.button_group=group
  button.tooltip_text=str(entry.title)+("\n"+str(entry.author)+" · "+str(entry.license) if entry.has("author") else "")
  button.set_pressed_no_signal(entry.id==selected_id)
  grid.add_child(button)
  var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for side in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+side,6)
  margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(margin)
  var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;margin.add_child(column)
  var viewport:=_preview(str(entry.id));button.add_child(viewport)
  var image:=TextureRect.new();image.texture=viewport.get_texture()
  image.custom_minimum_size.y=76;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(image)
  var caption:=Label.new();caption.text=str(entry.title);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  caption.add_theme_font_size_override("font_size",11);caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;caption.clip_text=true;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(caption)
  var id:String=entry.id
  button.pressed.connect(func():style_chosen.emit(id))
  choices[id]=button;previews.append(viewport)
 previous_button.disabled=page==0;next_button.disabled=page==page_count()-1
 page_input.max_value=page_count();page_input.set_value_no_signal(page+1)
 page_label.text="/ %d"%page_count()
func _preview(id:String) -> SubViewport:
 var viewport:=SubViewport.new()
 viewport.name="Thumbnail";viewport.size=Vector2i(144,144)
 viewport.own_world_3d=true;viewport.gui_disable_input=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 var environment:=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("382b21")
 viewport.add_child(environment)
 var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=0.78;camera.position=Vector3(0.9,0.55,2)
 camera.basis=Basis.looking_at(-camera.position.normalized());camera.current=true;viewport.add_child(camera)
 var visual:=Appearance.visual("Fire",0.32,Catalog.look(id,base_look))
 if str(visual.get_meta("look",{}).get("shape",""))=="Flame":visual.material_override.set_shader_parameter("flame_preview_time",float(visual.get_meta("look",{}).get("flame_thumbnail_time",0.8)))
 viewport.add_child(visual)
 return viewport
func select_style(id:String) -> void:
 selected_id=id
 for key in choices:choices[key].set_pressed_no_signal(key==id)
func focus_selection() -> void:
 if choices.has(selected_id):choices[selected_id].grab_focus()
 elif not choices.is_empty():choices.values()[0].grab_focus()
