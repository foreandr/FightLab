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
var type_buttons:Dictionary={}
var selected_type:="Movement"
var selected_id:=""
var sort_mode:=0
var sort_descending:=false
var sort_choice:OptionButton
var sort_direction:Button
var preferences_path:="user://sandbox_animation_browser.cfg"
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
var spell_catalog:VBoxContainer
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
 var tabs:=GridContainer.new();tabs.columns=3;add_child(tabs)
 for pair in [["Movement","Movement"],["Idle","Idle"],["Arm","Arms"],["Leg","Legs"],["Head","Head"],["Air","Air"],["Grabs","Grabs"],["Crouch","Crouch"],["Recovery","Recovery"]]:
  var kind:String=pair[0];var tab:Button=host.button(tabs,pair[1],func():set_type(kind));tab.toggle_mode=true;tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;type_buttons[kind]=tab
 load_preferences()
 var sort_row:=HBoxContainer.new();sort_row.add_theme_constant_override("separation",6);add_child(sort_row)
 sort_choice=OptionButton.new();sort_choice.name="AnimationSort";sort_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for title in ["Alphabetical","Min time","Max time"]:sort_choice.add_item(title)
 sort_choice.select(sort_mode);sort_choice.item_selected.connect(set_sort);sort_row.add_child(sort_choice)
 sort_direction=host.button(sort_row,"↓" if sort_descending else "↑",toggle_sort_direction)
 sort_direction.name="AnimationSortDirection";sort_direction.tooltip_text="Reverse sort direction"
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
 builder.stop_preview_controls(true)
 builder.demo_choice_selected=false
 builder.demo_duration=1.5;builder.casting_animation["duration"]=1.5
 builder.projectile_preview_button.pressed.disconnect(builder.play_projectile_once)
 builder.projectile_preview_button.button_down.connect(func():builder.cast_input_buffer.press(builder,"selected"))
 builder.projectile_preview_button.button_up.connect(func():builder.cast_input_buffer.release(builder,"selected"))
 builder.projectile_preview_button.tooltip_text="Hold to wind up; release to cast. Charge timing follows the animation's duration range."
 # Reuse the exact authoring controls and their existing signals/calculations.
 var timing:=VBoxContainer.new();timing.name="SandboxCasting"
 var sidebar=builder.spell_sections.Mana.get_parent();sidebar.add_child(timing);sidebar.move_child(timing,0)
 var length_row:=HBoxContainer.new();timing.add_child(length_row)
 var label:Label=host.menu_label(length_row,"Animation length",14);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 builder.get_meta("cast_length_input").reparent(length_row)
 builder.get_meta("cast_timeline").reparent(timing)
 builder.get_meta("cast_timeline").custom_minimum_size.y=98
 builder.spell_sections.Casting.hide()
 # Reuse the existing wizard; only its presentation moves to the RHS.
 for screen in [builder.delivery_screen,builder.barrier_screen,builder.projectile_screen,builder.touch_authoring]:
  screen.reparent(sidebar);sidebar.move_child(screen,timing.get_index()+1)
 var old_scroll=builder.projectile_scroll
 builder.projectile_scroll=null;old_scroll.queue_free()
 builder.delivery_demo_label.hide()
 builder.delivery_choices.Projectile.text=builder.delivery_choices.Projectile.text.trim_suffix(" · Default")
 builder.preview_delivery_type="";builder.delivery_type="";builder.delivery_choice_selected=false
 builder.show_creation_step("delivery")
 confirm.hide()

 builder.sandbox_spell_selected=false
 builder.refresh_demo_choices();builder.refresh_demo_timing();builder.get_meta("cast_timeline").fit_time();refresh_sidebar()
 spell_catalog=preload("res://scripts/sandbox_spell_catalog.gd").new()
 spell_catalog.setup(builder,sidebar)
func refresh_sidebar()->void:
 var builder=host.spell_builder
 builder.spell_sections.Mana.show()
 for title in ["Power balance","Results"]:builder.spell_sections[title].visible=builder.spell_delivery_type() not in ["Barrier","Touch"]
 for title in ["Mana","Power balance","Results"]:
  builder.spell_sections[title].modulate.a=1.0 if builder.sandbox_spell_selected else 0.45
 for key in builder.allocation_sliders:builder.allocation_sliders[key].editable=builder.sandbox_spell_selected
 builder.total_power_slider.editable=builder.sandbox_spell_selected
 if not builder.sandbox_spell_selected:
  for label in [builder.demo_mana_cost_label,builder.demo_stamina_label,builder.demo_damage_label,builder.demo_amplifier_label,builder.demo_size_bonus_label,builder.demo_speed_bonus_label,builder.demo_burn_label]:label.text="—"
  builder.demo_ragdoll_label.text="—"
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
 load_default_pair()
func load_default_pair()->void:
 for entry in records:
  if str(entry.title).to_lower().replace(" ","").replace("_","")=="meleehook":
   selected_type=str(entry._section);apply_filters()
   select_animation(entry)
   var index:=matches_.find(entry)
   if index>=0:page=floori(index/float(PAGE_SIZE));show_page()
   break
 for record in spell_catalog.records:
  if record.delivery_type=="Touch" and str(record.name).nocasecmp_to("Physical Touch")==0:
   spell_catalog.set_type("Touch");spell_catalog.select_spell(str(record.id));break
 host.spell_builder.stop_preview_controls(true)

func add_record(entry:Dictionary,origin:String,used:Dictionary,clips:Dictionary)->void:
 if Types.is_recovery(entry) and str(entry.get("clip",""))!=preload("res://scripts/recovery_animation.gd").CLIP:return
 if not combat_filter.accepts(entry) and not (origin=="Built-in" and (Types.is_crouch(entry) or Types.is_recovery(entry)) and not combat_filter.excluded(entry)):return
 var id:=Library.key(entry)
 if used.has(id):return
 used[id]=true;clips[str(entry.get("clip",""))]=true
 var copy:=entry.duplicate();copy["_origin"]=origin;copy["_id"]=id;copy["_origin_rank"]=["Your library","Built-in","Community"].find(origin)
 copy["store_animation_type"]=str(entry.store_animation_type) if entry.has("store_animation_type") else Types.kind(entry)
 copy["_grab"]=Types.is_grab(copy)
 copy["_crouch"]=Types.is_crouch(copy)
 copy["_recovery"]=Types.is_recovery(copy)
 copy["air_state"]="Airborne" if Types.is_airborne(copy) else "Grounded"
 copy["_section"]="Recovery" if copy._recovery else ("Air" if copy.air_state=="Airborne" else ("Crouch" if copy._crouch else ("Grabs" if copy._grab else ("Idle" if Types.is_idle(copy) else copy.store_animation_type))))
 var limits:=preload("res://scripts/animation_charge_timing.gd").duration_range(preload("res://scripts/animation_jump_motion.gd").with_airborne_takeoff(copy))
 copy["_duration_min"]=limits.x;copy["_duration_max"]=limits.y
 copy["_search"]=(str(entry.get("title",""))+" "+str(entry.get("tags",[]))+" "+str(entry.get("store_creator",entry.get("creator_name","")))+" "+str(entry.get("category",""))).to_lower()
 records.append(copy)
func set_type(kind:String)->void:
 if not type_buttons.has(kind):return
 selected_type=kind;apply_filters()
func apply_filters()->void:
 page=0;matches_.clear()
 var query:=search.text.strip_edges().to_lower()
 for entry in records:
  if selected_type=="Crouch":
   if not entry._crouch:continue
  elif selected_type=="Grabs":
   if not entry._grab:continue
  elif entry._section!=selected_type:continue
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
 matches_.sort_custom(compare_entries)
 for kind in type_buttons:type_buttons[kind].set_pressed_no_signal(kind==selected_type)
 show_page()
func load_preferences()->void:
 var cfg:=ConfigFile.new()
 if cfg.load(preferences_path)!=OK:return
 sort_mode=clampi(int(cfg.get_value("browser","sort",0)),0,2)
 sort_descending=bool(cfg.get_value("browser","descending",false))
func save_preferences()->void:
 var cfg:=ConfigFile.new();cfg.set_value("browser","sort",sort_mode);cfg.set_value("browser","descending",sort_descending);cfg.save(preferences_path)
func set_sort(mode:int)->void:
 sort_mode=clampi(mode,0,2)
 if is_instance_valid(sort_choice):sort_choice.select(sort_mode)
 if is_instance_valid(sort_direction):sort_direction.text="↓" if sort_descending else "↑"
 save_preferences();apply_filters()
func toggle_sort_direction()->void:
 sort_descending=not sort_descending
 sort_direction.text="↓" if sort_descending else "↑"
 save_preferences();apply_filters()
func compare_entries(a:Dictionary,b:Dictionary)->bool:
 var order:=0
 if sort_mode>0:
  var key:="_duration_min" if sort_mode==1 else "_duration_max"
  if float(a[key])!=float(b[key]):order=-1 if float(a[key])<float(b[key]) else 1
 if order==0:order=str(a.title).naturalnocasecmp_to(str(b.title))
 if order==0:order=str(a._id).casecmp_to(str(b._id))
 return order>0 if sort_descending else order<0
func turn_page(direction:int)->void:
 page=clampi(page+direction,0,maxi(0,ceili(matches_.size()/float(PAGE_SIZE))-1));show_page()
func show_page()->void:
 var visible_entries:Array=[];var cards:Array=[]
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 status.text="%d animations · %d matching"%[records.size(),matches_.size()]
 for index in range(page*PAGE_SIZE,mini(matches_.size(),(page+1)*PAGE_SIZE)):
  var entry:Dictionary=matches_[index]
  var limits:=Vector2(float(entry._duration_min),float(entry._duration_max))
  var card:Button=preload("res://scripts/asset_preview_card.gd").create("Animation"+str(index),str(entry.title),null,str(entry.title)+"\n"+entry.store_animation_type+" · "+entry._origin+"\n"+str(entry.get("store_creator","")),"Min %.2f s · Max %.2f s"%[limits.x,limits.y])
  card.custom_minimum_size.y=104
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
 entry["air_state"]=str(record.air_state)
 entry["animation_type"]=str(record.store_animation_type)
 entry["sandbox_offensive"]=record._section!="Idle" and (str(record.get("group","Motion"))=="Attack" or record.store_animation_type in ["Arm","Leg","Head"])
 entry=preload("res://scripts/animation_jump_motion.gd").with_airborne_takeoff(entry)
 # Ordinary library previews show the recorded pace, not a long take squeezed
 # into the previous selection's 1.5-second duration. Holding a cast overrides it.
 host.spell_builder.demo_duration=clampf(float(entry.get("source_duration",entry.get("duration",1.5))),0.1,60.0)
 var limits:=preload("res://scripts/held_cast_preview.gd").duration_range(entry)
 entry["source_duration"]=host.spell_builder.demo_duration
 entry["min_duration"]=limits.x;entry["max_duration"]=limits.y
 if not host.spell_builder.choose_demo_animation(entry,false):selection.text="Could not load "+str(record.title);show_page();return false
 selected_id=str(record._id);selection.text=str(record.title)+" · Hold: %.2f–%.2f s"%[limits.x,limits.y];confirm.disabled=false
 host.spell_builder.play_demo_preview();show_page();refresh_sidebar()
 return true
func confirm_selection()->void:
 if host.spell_builder.demo_choice_selected and not host.spell_builder.casting_animation.is_empty():host.spell_builder.play_projectile_once()
func _process(_delta:float)->void:
 if is_instance_valid(host):
  var builder=host.spell_builder
  var ready:bool=builder.previews_spell_release()
  if ready!=builder.sandbox_spell_selected:
   builder.sandbox_spell_selected=ready;refresh_sidebar()
 if is_instance_valid(host) and not selected_id.is_empty() and not host.spell_builder.demo_choice_selected:
  selected_id="";selection.text="Click an animation to preview it";show_page()
func _exit_tree()->void:
 closing=true
 if worker!=null and worker.is_started():worker.wait_to_finish()
 worker=null
