extends Node
## UI adapter only: no actor, arena, camera, or combat state is modified.
const Design=preload("res://scripts/ui_design.gd")
var pending:Dictionary={}
var themed:Dictionary={}
var voices:Array[AudioStreamPlayer]=[]
var voice_index:=0
var last_click:=-1000
func _ready()->void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 get_tree().root.theme=Design.theme()
 var sound:=click_sound()
 for i in 4:
  var voice:=AudioStreamPlayer.new();voice.stream=sound;voice.volume_db=-23;voice.bus="Master";add_child(voice);voices.append(voice)
 get_tree().node_added.connect(watch)
 walk(get_tree().root)
func walk(node:Node)->void:
 watch(node)
 for child in node.get_children():walk(child)
func watch(node:Node)->void:
 if node is Label3D:
  node.set_deferred("font",Design.FONT)
 elif node is Control or node is Window:
  queue_skin(weakref(node))
  if node is Control and not node.has_meta("cyber_theme_watch"):
   node.set_meta("cyber_theme_watch",true);node.theme_changed.connect(queue_skin.bind(weakref(node)))
func queue_skin(reference:WeakRef)->void:
 var node=reference.get_ref()
 if not is_instance_valid(node) or pending.has(node.get_instance_id()):return
 pending[node.get_instance_id()]=true
 apply_skin.call_deferred(reference,node.get_instance_id())
func apply_theme(theme_:Theme)->void:
 if theme_==null or themed.has(theme_.get_instance_id()):return
 themed[theme_.get_instance_id()]=weakref(theme_)
 theme_.default_font=Design.FONT
 for type in theme_.get_type_list():
  for name_ in theme_.get_color_list(type):
   var previous:=theme_.get_color(name_,type);var next:=Design.color(previous,name_)
   if previous!=next:theme_.set_color(name_,type,next)
  for name_ in theme_.get_stylebox_list(type):
   var previous:=theme_.get_stylebox(name_,type);var next:=Design.restyle(previous)
   if previous!=next:theme_.set_stylebox(name_,type,next)
func apply_skin(reference:WeakRef,id:int)->void:
 var node=reference.get_ref()
 if not is_instance_valid(node):pending.erase(id);return
 apply_theme(node.theme)
 if node is ColorRect:node.color=Design.color(node.color)
 for property in node.get_property_list():
  var key:String=property.name
  if key.begins_with("theme_override_colors/") and node.get(key) is Color:
   var value:Color=node.get(key);var next:=Design.color(value,key)
   if next!=value:node.set(key,next)
  elif key.begins_with("theme_override_styles/"):
   var style=node.get(key)
   if style!=null:
    var next:=Design.restyle(style)
    if next!=style:node.set(key,next)
  elif key.begins_with("theme_override_fonts/") and node.get(key)!=null:
   if node.get(key) not in [Design.FONT,Design.BOLD]:node.set(key,Design.FONT)
 if node is Button and node.icon!=null and node.text.is_empty():
  for slot in ["normal","hover","pressed","disabled","focus"]:
   var style=node.get_theme_stylebox(slot)
   if style is StyleBoxFlat and style.content_margin_left>2:
    var compact:StyleBoxFlat=style.duplicate()
    for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:compact.set_content_margin(side,2)
    node.add_theme_stylebox_override(slot,compact)
 if node is PopupMenu and not node.has_meta("cyber_click"):
  node.set_meta("cyber_click",true);node.id_pressed.connect(func(_id:int):click())
 elif node is TabBar and not node.has_meta("cyber_click"):
  node.set_meta("cyber_click",true);node.tab_changed.connect(func(_tab:int):click())
 elif node is Slider and not node.has_meta("cyber_click"):
  node.set_meta("cyber_click",true);node.drag_started.connect(click)
 elif node is BaseButton and not node.has_meta("cyber_click"):
  node.set_meta("cyber_click",true);node.pressed.connect(click)
 elif node is Control and not node.has_meta("cyber_click") and not node.get_signal_connection_list("gui_input").is_empty():
  node.set_meta("cyber_click",true);node.gui_input.connect(panel_click)
 pending.erase(id)
func panel_click(event:InputEvent)->void:
 if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed) or event.is_action_pressed("ui_accept"):click()
func click()->void:
 if Time.get_ticks_msec()-last_click<20 or voices.is_empty():return
 last_click=Time.get_ticks_msec();voices[voice_index].play();voice_index=(voice_index+1)%voices.size()
static func click_sound()->AudioStreamWAV:
 var data:=PackedByteArray();var rate:=22050;var count:=int(rate*0.065);data.resize(count*2)
 for i in count:
  var t:=float(i)/rate;var envelope:=minf(1.0,t/0.002)*exp(-t*70.0)
  var sample:float=(sin(TAU*(1500.0*t-5500.0*t*t))*0.35+sin(TAU*420.0*t)*0.22)*envelope
  data.encode_s16(i*2,int(clampf(sample,-1,1)*32767))
 var sound:=AudioStreamWAV.new();sound.format=AudioStreamWAV.FORMAT_16_BITS;sound.mix_rate=rate;sound.data=data
 return sound
