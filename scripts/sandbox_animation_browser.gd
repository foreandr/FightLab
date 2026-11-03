extends VBoxContainer
## Metadata index with real screenshots generated only for the visible page.
const Index=preload("res://scripts/animation_store_index.gd")
const Library=preload("res://scripts/animation_store_library.gd")
const Types=preload("res://scripts/animation_store_types.gd")
const PAGE_SIZE:=9
var host:Control
var records:Array[Dictionary]=[]
var matches_:Array[Dictionary]=[]
var page:=0
var ready_catalog:=false
var details_path:=""
var detail_loads:=0
var worker:Thread
var closing:=false
var search:LineEdit
var air_buttons:Dictionary={}
var selected_air:="Grounded"
var type_buttons:Dictionary={}
var selected_type:="Movement"
var selected_id:=""
var grid:GridContainer
var status:Label
var selection:Label
var previous:Button
var next:Button
var page_label:Label
var confirm:Button
var debounce:Timer
var thumbnails:Node
var combat_filter=preload("res://scripts/combat_animation_filter.gd").new()
var spell_selector:OptionButton
var spell_records:Array[Dictionary]=[]
func setup(editor:Control)->void:
 host=editor;size_flags_horizontal=Control.SIZE_EXPAND_FILL;size_flags_vertical=Control.SIZE_EXPAND_FILL;add_theme_constant_override("separation",6)
 thumbnails=preload("res://scripts/animation_thumbnail_renderer.gd").new();add_child(thumbnails)
 theme=host.theme.duplicate(true);theme.default_font_size=11
 for type_ in ["Button","OptionButton","LineEdit","SpinBox"]:
  for state in ["normal","hover","pressed","focus","read_only"]:
   if theme.has_stylebox(state,type_):
    var style:StyleBox=theme.get_stylebox(state,type_).duplicate()
    for side in [SIDE_TOP,SIDE_BOTTOM]:style.set_content_margin(side,3)
    theme.set_stylebox(state,type_,style)
 host.menu_label(self,"Choose an animation",16)
 search=LineEdit.new();search.placeholder_text="Search names, tags or author:…";search.add_theme_color_override("font_placeholder_color",Color("806d4d"));add_child(search)
 debounce=Timer.new();debounce.one_shot=true;debounce.wait_time=0.2;add_child(debounce)
 search.text_changed.connect(func(_value):debounce.start());debounce.timeout.connect(apply_filters)
 var tabs:=HBoxContainer.new();add_child(tabs)
 for pair in [["Movement","Movement"],["Idle","Idle"],["Arm","Arms"],["Leg","Legs"],["Head","Head"]]:
  var kind:String=pair[0];var tab:Button=host.button(tabs,pair[1],func():set_type(kind));tab.toggle_mode=true;tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;type_buttons[kind]=tab
 var row:=HBoxContainer.new();add_child(row)
 var group:=ButtonGroup.new();group.allow_unpress=false
 for state in ["Grounded","Airborne"]:
  var radio:=CheckBox.new();radio.text="Ground" if state=="Grounded" else "Air"
  radio.name="Sandbox"+state;radio.button_group=group;radio.focus_mode=Control.FOCUS_ALL
  radio.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(radio);air_buttons[state]=radio
  radio.pressed.connect(func():set_air(state))
  radio.set_pressed_no_signal(state==selected_air)
 status=host.menu_label(self,"Opening animation index…",12)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
 grid=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);scroll.add_child(grid)
 var paging:=HBoxContainer.new();add_child(paging)
 previous=host.button(paging,"← Prev",func():turn_page(-1))
 page_label=host.menu_label(paging,"",12);page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 next=host.button(paging,"Next →",func():turn_page(1))
 selection=host.menu_label(self,"Click an animation to preview it",12);selection.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 confirm=host.button(self,"Confirm",confirm_selection);confirm.disabled=true;host.spell_builder.demo_confirm_button=confirm
 build_test_controls()
 for control in find_children("*","Button",true,false):control.custom_minimum_size.y=24
 call_deferred("load_catalog")
func build_test_controls()->void:
 var builder=host.spell_builder
 builder.sandbox_testing=true
 spell_selector=OptionButton.new();spell_selector.name="SandboxSpell";spell_selector.focus_mode=Control.FOCUS_ALL
 spell_selector.add_item("Animation only")
 spell_records.append({})
 var definition=preload("res://scripts/spell_definition.gd")
 for effect in ["None","Fire"]:
  var record:Dictionary=definition.make(effect,"Projectile",{"size":0.5,"speed":0.5} if effect=="None" else {"size":0.33,"speed":0.34,"effect":0.33},{})
  record["name"]="Physical projectile" if effect=="None" else "Fire projectile"
  spell_selector.add_item(record.name);spell_records.append(record)
 for record in builder.saved_spells.entries():spell_selector.add_item(record.name);spell_records.append(record)
 add_child(spell_selector);move_child(spell_selector,search.get_index()+1)
 spell_selector.item_selected.connect(select_spell)
 # Reuse the exact authoring controls and their existing signals/calculations.
 var timing:=VBoxContainer.new();timing.name="SandboxCasting"
 var sidebar=builder.spell_sections.Mana.get_parent();sidebar.add_child(timing);sidebar.move_child(timing,0)
 var length_row:=HBoxContainer.new();timing.add_child(length_row)
 var label:Label=host.menu_label(length_row,"Animation length",14);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 builder.get_meta("cast_length_input").reparent(length_row)
 builder.get_meta("cast_timeline").reparent(timing)
 builder.get_meta("cast_timeline").custom_minimum_size.y=98
 builder.spell_sections.Casting.hide()
 confirm.text="Test animation + spell"
 refresh_sidebar()
func refresh_sidebar()->void:
 var builder=host.spell_builder
 for title in ["Mana","Power balance","Results"]:builder.spell_sections[title].visible=builder.sandbox_spell_selected
func select_spell(index:int)->void:
 var builder=host.spell_builder
 if builder.cast_committed():spell_selector.select(int(spell_selector.get_meta("previous",0)));return
 builder.stop_preview_controls(true)
 builder.sandbox_spell_selected=index>0
 if index>0:builder.apply_spell_record(spell_records[index],false)
 spell_selector.set_meta("previous",index)
 builder.refresh_demo_choices();builder.refresh_demo_timing();builder.refresh_projectile_allocation()
 refresh_sidebar()
func load_catalog()->void:
 var used:Dictionary={};var clips:Dictionary={}
 var local:Array=preload("res://scripts/animation_recipe_library.gd").load_custom_motion("")
 local.append_array(host.store_library.taken.values())
 for entry in local:add_record(entry,"Your library",used,clips)
 for entry in preload("res://scripts/animation_catalog.gd").entries():add_record(entry,"Built-in",used,clips)
 for clip in host.actor.player.get_animation_list():
  if clips.has(clip) or str(clip).ends_with("RESET"):continue
  add_record({"title":str(clip).get_slice("/",1).replace("_"," "),"clip":clip,"step":"Imported Motion","store_raw":true,"duration":host.actor.player.get_animation(clip).length},"Built-in",used,clips)
 var source:AnimationLibrary=load("res://assets/combat/animations/UAL2_Standard.glb")
 if source!=null:
  for name_ in source.get_animation_list():
   if name_=="RESET" or clips.has("ual2/"+name_):continue
   add_record({"title":name_.replace("_"," "),"clip":"store_preview/"+name_,"source_animation":name_,"step":"Imported Motion","store_raw":true,"duration":source.get_animation(name_).length},"Built-in",used,clips)
 apply_filters()
 status.text="%d ready · opening community index…"%records.size()
 worker=Thread.new()
 var error:=worker.start(func():
  var cached:=Index.load_cache(Index.cache_path())
  return Index.build_cache(Index.cache_path()) if cached.is_empty() else cached)
 if error==OK:
  while not closing and worker!=null and worker.is_alive():await get_tree().process_frame
  if closing:return
  var data:Variant=worker.wait_to_finish()
  if data is Dictionary:
   details_path=str(data.get("details_path",""))
   for entry in data.get("records",[]):
    if not host.store_library.blocked.has(Library.key(entry)):add_record(entry,"Community",used,clips)
 worker=null
 records.sort_custom(func(a,b):
  if a._origin_rank!=b._origin_rank:return int(a._origin_rank)<int(b._origin_rank)
  return str(a.title).naturalnocasecmp_to(str(b.title))<0)
 ready_catalog=true;apply_filters()
func add_record(entry:Dictionary,origin:String,used:Dictionary,clips:Dictionary)->void:
 if origin!="Your library" and not combat_filter.accepts(entry):return
 var id:=Library.key(entry)
 if used.has(id):return
 used[id]=true;clips[str(entry.get("clip",""))]=true
 var copy:=entry.duplicate();copy["_origin"]=origin;copy["_id"]=id;copy["_origin_rank"]=["Your library","Built-in","Community"].find(origin)
 copy["store_animation_type"]=str(entry.store_animation_type) if entry.has("store_animation_type") else Types.kind(entry)
 copy["_section"]="Idle" if Types.is_idle(copy) else copy.store_animation_type
 if not copy.has("air_state"):
  var words:=" "+str(entry.get("title",""))+" "+str(entry.get("kind",""))
  copy["air_state"]="Airborne" if ["jump","flip","air","twist","fly","leap","fall","cartwheel"].any(func(h):return words.to_lower().contains(h)) else "Grounded"
 copy["_search"]=(str(entry.get("title",""))+" "+str(entry.get("tags",[]))+" "+str(entry.get("store_creator",entry.get("creator_name","")))+" "+str(entry.get("category",""))).to_lower()
 records.append(copy)
func set_type(kind:String)->void:
 if not type_buttons.has(kind):return
 selected_type=kind;apply_filters()
func set_air(state:String)->void:
 if not air_buttons.has(state):return
 selected_air=state;apply_filters()
func apply_filters()->void:
 page=0;matches_.clear()
 var query:=search.text.strip_edges().to_lower()
 for entry in records:
  if entry._section!=selected_type:continue
  if str(entry.get("air_state","Grounded"))!=selected_air:continue
  if not query.is_empty():
   if ":" in query or '"' in query:
    if not Library.matches(entry,query):continue
   else:
    var found:=true
    for term in query.split(" ",false):
     if term.begins_with("-"):
      if str(entry._search).contains(term.substr(1)):found=false;break
     elif not str(entry._search).contains(term):found=false;break
    if not found:continue
  matches_.append(entry)
 for kind in type_buttons:type_buttons[kind].set_pressed_no_signal(kind==selected_type)
 for state in air_buttons:air_buttons[state].set_pressed_no_signal(state==selected_air)
 show_page()
func turn_page(direction:int)->void:
 page=clampi(page+direction,0,maxi(0,ceili(matches_.size()/float(PAGE_SIZE))-1));show_page()
func show_page()->void:
 var visible_entries:Array=[];var cards:Array=[]
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 status.text="%d animations · %d matching"%[records.size(),matches_.size()]
 for index in range(page*PAGE_SIZE,mini(matches_.size(),(page+1)*PAGE_SIZE)):
  var entry:Dictionary=matches_[index]
  var card:Button=preload("res://scripts/asset_preview_card.gd").create("Animation"+str(index),str(entry.title),null,str(entry.title)+"\n"+entry.store_animation_type+" · "+entry._origin+"\n"+str(entry.get("store_creator","")))
  card.custom_minimum_size.y=86
  card.find_child("PreviewImage",true,false).custom_minimum_size.y=52
  grid.add_child(card);card.set_pressed_no_signal(entry._id==selected_id)
  visible_entries.append(entry);cards.append(card)
  card.pressed.connect(func():select_animation(entry))
 var pages:=maxi(1,ceili(matches_.size()/float(PAGE_SIZE)))
 page_label.text="%d / %d"%[page+1,pages];previous.disabled=page==0;next.disabled=page+1>=pages
 thumbnails.request_page(visible_entries,cards,details_path)
func select_animation(record:Dictionary)->bool:
 if host.spell_builder.cast_committed():return false
 var entry:=record.duplicate(true)
 if entry.has("_detail_offset"):
  entry=Index.load_entry(details_path,int(entry._detail_offset),int(entry._detail_size));detail_loads+=1
 if entry.is_empty():selection.text="Animation data unavailable";return false
 entry["sandbox_animation"]=true;entry["demo_choice"]="sandbox"
 entry["animation_type"]=str(record.store_animation_type)
 entry["sandbox_offensive"]=record._section!="Idle" and (str(record.get("group","Motion"))=="Attack" or record.store_animation_type in ["Arm","Leg","Head"])
 entry=preload("res://scripts/animation_jump_motion.gd").with_airborne_takeoff(entry)
 if not host.spell_builder.choose_demo_animation(entry,false):selection.text="Could not load "+str(record.title);show_page();return false
 selected_id=str(record._id);selection.text=str(record.title);confirm.disabled=false
 host.spell_builder.play_demo_preview();show_page();refresh_sidebar()
 return true
func confirm_selection()->void:
 if host.spell_builder.demo_choice_selected and not host.spell_builder.casting_animation.is_empty():host.spell_builder.play_projectile_once()
func _process(_delta:float)->void:
 if is_instance_valid(host) and not selected_id.is_empty() and not host.spell_builder.demo_choice_selected:
  selected_id="";selection.text="Click an animation to preview it";show_page()
func _exit_tree()->void:
 closing=true
 if worker!=null and worker.is_started():worker.wait_to_finish()
 worker=null
