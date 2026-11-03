extends VBoxContainer
## Metadata index with real screenshots generated only for the visible page.
const Index=preload("res://scripts/animation_store_index.gd")
const Library=preload("res://scripts/animation_store_library.gd")
const Types=preload("res://scripts/animation_store_types.gd")
const PAGE_SIZE:=12
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
var source_filter:OptionButton
var air_filter:OptionButton
var type_buttons:Dictionary={}
var selected_type:="All"
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
func setup(editor:Control)->void:
 host=editor;size_flags_horizontal=Control.SIZE_EXPAND_FILL;size_flags_vertical=Control.SIZE_EXPAND_FILL;add_theme_constant_override("separation",6)
 thumbnails=preload("res://scripts/animation_thumbnail_renderer.gd").new();add_child(thumbnails)
 host.menu_label(self,"Choose an animation",20)
 search=LineEdit.new();search.placeholder_text="Search names, tags or author:…";search.add_theme_color_override("font_placeholder_color",Color("806d4d"));add_child(search)
 debounce=Timer.new();debounce.one_shot=true;debounce.wait_time=0.2;add_child(debounce)
 search.text_changed.connect(func(_value):debounce.start());debounce.timeout.connect(apply_filters)
 var tabs:=HBoxContainer.new();add_child(tabs)
 for pair in [["All","All"],["Movement","Movement"],["Arm","Arms"],["Leg","Legs"],["Head","Head"]]:
  var kind:String=pair[0];var tab:Button=host.button(tabs,pair[1],func():set_type(kind));tab.toggle_mode=true;tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;type_buttons[kind]=tab
 var row:=HBoxContainer.new();add_child(row)
 source_filter=OptionButton.new();source_filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for text_ in ["All animations","Your library","Built-in","Community"]:source_filter.add_item(text_)
 row.add_child(source_filter);source_filter.item_selected.connect(func(_i):apply_filters())
 air_filter=OptionButton.new()
 for text_ in ["Air + ground","Airborne","Grounded"]:air_filter.add_item(text_)
 row.add_child(air_filter);air_filter.item_selected.connect(func(_i):apply_filters())
 status=host.menu_label(self,"Opening animation index…",12)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
 grid=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);scroll.add_child(grid)
 var paging:=HBoxContainer.new();add_child(paging)
 previous=host.button(paging,"← Prev",func():turn_page(-1))
 page_label=host.menu_label(paging,"",12);page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 next=host.button(paging,"Next →",func():turn_page(1))
 selection=host.menu_label(self,"Click an animation to preview it",12);selection.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 confirm=host.button(self,"Confirm",confirm_selection);confirm.disabled=true;host.spell_builder.demo_confirm_button=confirm
 call_deferred("load_catalog")
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
 if not copy.has("air_state"):
  var words:=" "+str(entry.get("title",""))+" "+str(entry.get("kind",""))
  copy["air_state"]="Airborne" if ["jump","flip","air","twist","fly","leap","fall","cartwheel"].any(func(h):return words.to_lower().contains(h)) else "Grounded"
 copy["_search"]=(str(entry.get("title",""))+" "+str(entry.get("tags",[]))+" "+str(entry.get("store_creator",entry.get("creator_name","")))+" "+str(entry.get("category",""))).to_lower()
 records.append(copy)
func set_type(kind:String)->void:
 selected_type=kind;apply_filters()
func apply_filters()->void:
 page=0;matches_.clear()
 var query:=search.text.strip_edges().to_lower()
 for entry in records:
  if selected_type!="All" and entry.store_animation_type!=selected_type:continue
  if source_filter.selected>0 and entry._origin!=source_filter.get_item_text(source_filter.selected):continue
  if air_filter.selected>0 and str(entry.get("air_state","Grounded"))!=air_filter.get_item_text(air_filter.selected):continue
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
 entry["sandbox_offensive"]=record.store_animation_type in ["Arm","Leg","Head"]
 if not host.spell_builder.choose_demo_animation(entry,false):selection.text="Could not load "+str(record.title);show_page();return false
 selected_id=str(record._id);selection.text=str(record.title);confirm.disabled=false
 host.spell_builder.play_demo_preview();show_page()
 return true
func confirm_selection()->void:
 if host.spell_builder.demo_choice_selected and not host.spell_builder.casting_animation.is_empty():host.spell_builder.show_creation_step("delivery")
func _process(_delta:float)->void:
 if is_instance_valid(host) and not selected_id.is_empty() and not host.spell_builder.demo_choice_selected:
  selected_id="";selection.text="Click an animation to preview it";show_page()
func _exit_tree()->void:
 closing=true
 if worker!=null and worker.is_started():worker.wait_to_finish()
 worker=null
