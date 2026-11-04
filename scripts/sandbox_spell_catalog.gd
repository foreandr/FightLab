extends VBoxContainer
const CyberStyle=preload("res://scripts/ui_design.gd")
## Browse named definitions; the shared builder/runtime still bind and execute them.
const TYPES:=["Projectile","Beam","Targeted","Touch","Barrier"]
const PAGE_SIZE:=9
var builder:Node
var records:Array[Dictionary]=[]
var matches_:Array[Dictionary]=[]
var selected_type:="Projectile"
var selected_id:=""
var page:=0
var type_buttons:Dictionary={}
var search:LineEdit
var grid:GridContainer
var status:Label
var empty_label:Label
var selection:Label
var previous:Button
var next:Button
var page_label:Label
var hidden_workspace:Control
func setup(owner_builder:Node,content:VBoxContainer)->void:
 builder=owner_builder;name="SandboxSpellCatalogue"
 hidden_workspace=content.get_parent();hidden_workspace.hide()
 builder.demo_timing_panel.add_child(self)
 add_theme_constant_override("separation",6)
 builder.editor.menu_label(self,"Choose a saved spell",18)
 var row:=HBoxContainer.new();add_child(row)
 search=LineEdit.new();search.placeholder_text="Search saved spells…";search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(search)
 search.add_theme_color_override("font_placeholder_color",CyberStyle.MUTED)
 search.text_changed.connect(func(_text:String):filter_records())
 var refresh:Button=builder.editor.button(row,"↻",reload_catalog);refresh.tooltip_text="Refresh saved spells";refresh.focus_mode=Control.FOCUS_ALL
 var tabs:=GridContainer.new();tabs.columns=3;add_child(tabs)
 for kind in TYPES:
  var button:Button=builder.editor.button(tabs,kind,func():set_type(kind))
  button.toggle_mode=true;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",12);type_buttons[kind]=button
 status=builder.editor.menu_label(self,"",12)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(scroll)
 var results:=VBoxContainer.new();results.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(results)
 empty_label=builder.editor.menu_label(results,"",12);empty_label.name="EmptySavedSpells"
 empty_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;empty_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 grid=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);results.add_child(grid)
 var paging:=HBoxContainer.new();add_child(paging)
 previous=builder.editor.button(paging,"← Prev",func():turn_page(-1))
 page_label=builder.editor.menu_label(paging,"",12);page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 next=builder.editor.button(paging,"Next →",func():turn_page(1))
 selection=builder.editor.menu_label(self,"Choose a spell to pair with your animation",12);selection.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 reload_catalog()
func reload_catalog()->void:
 records=builder.saved_spells.entries();filter_records()
func set_type(kind:String)->void:
 if kind not in TYPES:return
 selected_type=kind;filter_records()
func filter_records()->void:
 page=0;matches_.clear()
 var query:=search.text.strip_edges().to_lower()
 for record in records:
  if record.delivery_type==selected_type and (query.is_empty() or str(record.name).to_lower().contains(query)):matches_.append(record)
 for kind in type_buttons:type_buttons[kind].set_pressed_no_signal(kind==selected_type)
 show_page()
func turn_page(direction:int)->void:
 page=clampi(page+direction,0,maxi(0,ceili(matches_.size()/float(PAGE_SIZE))-1));show_page()
func show_page()->void:
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 status.text="%d saved · %d matching"%[records.size(),matches_.size()]
 empty_label.visible=matches_.is_empty()
 empty_label.text="No saved "+selected_type.to_lower()+" spells"
 grid.visible=not matches_.is_empty()
 for index in range(page*PAGE_SIZE,mini(matches_.size(),(page+1)*PAGE_SIZE)):
  var record:Dictionary=matches_[index]
  var fire:bool=record.element=="Fire"
  var card:Button=preload("res://scripts/asset_preview_card.gd").create("SavedSpell_"+str(record.id),str(record.name),null,str(record.name)+" · "+str(record.delivery_type),"Self shield" if record.delivery_type=="Barrier" else ("Fire" if fire else "Physical"))
  card.custom_minimum_size=Vector2(0,108)
  card.find_child("PreviewImage",true,false).custom_minimum_size.y=64
  if fire:
   var viewport:SubViewport=builder.fire_style_gallery._preview(str(record.appearance.fire_style_id))
   card.add_child(viewport);card.find_child("PreviewImage",true,false).texture=viewport.get_texture()
  else:card.find_child("PreviewImage",true,false).texture=preload("res://scripts/animation_row_icons.gd").get_icon("shield_self" if record.delivery_type=="Barrier" else ("arm" if record.delivery_type=="Touch" else "cast"))
  grid.add_child(card);card.set_pressed_no_signal(str(record.id)==selected_id)
  card.pressed.connect(func():select_spell(str(record.id)))
 var pages:=maxi(1,ceili(matches_.size()/float(PAGE_SIZE)))
 page_label.text="%d / %d"%[page+1,pages];previous.disabled=page==0;next.disabled=page+1>=pages
func select_spell(id:String)->bool:
 if builder.cast_committed():return false
 var record:Dictionary={}
 for candidate in records:
  if str(candidate.id)==id:record=candidate;break
 if record.is_empty() or not builder.apply_spell_record(record,false):return false
 builder.sandbox_spell_record=record.duplicate(true)
 builder.delivery_choice_selected=true
 builder.show_creation_step({"Touch":"touch","Barrier":"shield"}.get(str(record.delivery_type),"projectile"))
 selected_id=id;selection.text=str(record.name)
 builder.refresh_playback_controls();show_page()
 return true
func _process(_delta:float)->void:
 # Authoring widgets remain available to shared tooling, never as Sandbox pages.
 if is_instance_valid(hidden_workspace):hidden_workspace.hide()
