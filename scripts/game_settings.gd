extends CanvasLayer
## One persistent settings service and one reusable dialog for every mode.
signal changed
const DEFAULT_MIN_DISTANCE:=2.97
const DEFAULT_MAX_DISTANCE:=20.52
const COMBAT_BUS:="Combat"
var storage_path:="user://global_settings.cfg"
var min_camera_distance:=DEFAULT_MIN_DISTANCE
var max_camera_distance:=DEFAULT_MAX_DISTANCE
var master_volume:=1.0
var combat_volume:=1.0
var muted:=false
var distance_audio:=true
var dialog:AcceptDialog
var cog:Button
var sections:TabContainer
var near_input:SpinBox
var far_input:SpinBox
var master_slider:HSlider
var combat_slider:HSlider
var mute_toggle:CheckButton
var distance_toggle:CheckButton
var opened:=false
var previous_pause:=false
var previous_mouse:=Input.MOUSE_MODE_VISIBLE
func _ready()->void:
 process_mode=Node.PROCESS_MODE_ALWAYS;layer=130
 load_settings()
 _build_ui()
 changed.connect(_refresh_ui)
func load_settings()->void:
 var cfg:=ConfigFile.new()
 if cfg.load(storage_path)==OK:
  min_camera_distance=float(cfg.get_value("camera","closest",DEFAULT_MIN_DISTANCE))
  max_camera_distance=float(cfg.get_value("camera","farthest",DEFAULT_MAX_DISTANCE))
  master_volume=float(cfg.get_value("audio","master",1.0));combat_volume=float(cfg.get_value("audio","combat",1.0))
  muted=bool(cfg.get_value("audio","muted",false));distance_audio=bool(cfg.get_value("audio","distance",true))
 _sanitize();_apply_audio();changed.emit()
func save_settings()->void:
 var cfg:=ConfigFile.new()
 cfg.set_value("camera","closest",min_camera_distance);cfg.set_value("camera","farthest",max_camera_distance)
 cfg.set_value("audio","master",master_volume);cfg.set_value("audio","combat",combat_volume)
 cfg.set_value("audio","muted",muted);cfg.set_value("audio","distance",distance_audio)
 cfg.save(storage_path)
func _sanitize()->void:
 if not is_finite(min_camera_distance):min_camera_distance=DEFAULT_MIN_DISTANCE
 if not is_finite(max_camera_distance):max_camera_distance=DEFAULT_MAX_DISTANCE
 min_camera_distance=clampf(min_camera_distance,0.25,500)
 max_camera_distance=clampf(max_camera_distance,min_camera_distance,500)
 master_volume=clampf(master_volume if is_finite(master_volume) else 1.0,0,1)
 combat_volume=clampf(combat_volume if is_finite(combat_volume) else 1.0,0,1)
func set_value(key:String,value:Variant)->void:
 match key:
  "closest":
   min_camera_distance=float(value)
   max_camera_distance=maxf(max_camera_distance,min_camera_distance)
  "farthest":
   max_camera_distance=float(value)
   min_camera_distance=minf(min_camera_distance,max_camera_distance)
  "master":master_volume=float(value)
  "combat":combat_volume=float(value)
  "muted":muted=bool(value)
  "distance":distance_audio=bool(value)
  _:return
 _sanitize();_apply_audio();save_settings();changed.emit()
func clamp_camera_distance(value:float)->float:return clampf(value,min_camera_distance,max_camera_distance)
func apply_spatial(player:AudioStreamPlayer3D,normal_range:float)->void:
 player.bus=COMBAT_BUS
 player.attenuation_model=AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE if distance_audio else AudioStreamPlayer3D.ATTENUATION_DISABLED
 player.max_distance=normal_range if distance_audio else 0.0
func _apply_audio()->void:
 var index:=AudioServer.get_bus_index(COMBAT_BUS)
 if index<0:
  AudioServer.add_bus();index=AudioServer.bus_count-1;AudioServer.set_bus_name(index,COMBAT_BUS);AudioServer.set_bus_send(index,"Master")
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(master_volume,0.0001)))
 AudioServer.set_bus_mute(0,muted or master_volume<=0)
 AudioServer.set_bus_volume_db(index,linear_to_db(maxf(combat_volume,0.0001)))
 AudioServer.set_bus_mute(index,combat_volume<=0)
func _build_ui()->void:
 var root:=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
 cog=Button.new();cog.name="UniversalSettings";cog.text="⚙";cog.tooltip_text="Settings · F9";cog.focus_mode=Control.FOCUS_ALL
 cog.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);cog.offset_left=-50;cog.offset_right=-6;cog.offset_top=6;cog.offset_bottom=48
 root.add_child(cog);cog.hide();cog.pressed.connect(toggle)
 dialog=AcceptDialog.new();dialog.name="UniversalSettingsDialog";dialog.title="Settings";dialog.ok_button_text="Close";dialog.borderless=true
 dialog.process_mode=Node.PROCESS_MODE_ALWAYS
 var book:=Theme.new();book.default_font=load("res://assets/fonts/game_font.tres");book.default_font_size=18
 for type in ["Label","Button","CheckButton","LineEdit","TabBar"]:
  for color in ["font_color","font_pressed_color","font_hover_color","font_hover_pressed_color","font_focus_color","font_uneditable_color"]:book.set_color(color,type,Color("382c1c"))
 var paper:=StyleBoxFlat.new();paper.bg_color=Color("e8ddc4");paper.border_color=Color("b49c70");paper.set_border_width_all(1);paper.set_corner_radius_all(6)
 for side in ["left","right","top","bottom"]:paper.set("content_margin_"+side,12.0)
 book.set_stylebox("panel","AcceptDialog",paper)
 book.set_stylebox("panel","TabContainer",paper)
 var button:=paper.duplicate();button.bg_color=Color("d8c7a4");book.set_stylebox("normal","Button",button)
 var hover:=button.duplicate();hover.bg_color=Color("f2e9d3");book.set_stylebox("hover","Button",hover)
 var pressed:=button.duplicate();pressed.bg_color=Color("c9af7b");book.set_stylebox("pressed","Button",pressed)
 book.set_stylebox("tab_selected","TabBar",pressed);book.set_stylebox("tab_unselected","TabBar",button);book.set_stylebox("tab_hovered","TabBar",hover)
 var field:=paper.duplicate();field.bg_color=Color("f2e9d3")
 book.set_stylebox("normal","LineEdit",field);book.set_stylebox("read_only","LineEdit",field)
 var focus:=field.duplicate();focus.border_color=Color("98703d");book.set_stylebox("focus","LineEdit",focus)
 var track:=StyleBoxFlat.new();track.bg_color=Color("c9b48c");track.content_margin_top=4;track.content_margin_bottom=4;track.set_corner_radius_all(4)
 book.set_stylebox("slider","HSlider",track)
 var fill:=track.duplicate();fill.bg_color=Color("b38a47");book.set_stylebox("grabber_area","HSlider",fill);book.set_stylebox("grabber_area_highlight","HSlider",fill)
 cog.theme=book
 dialog.theme=book;add_child(dialog)
 var box:=VBoxContainer.new();box.custom_minimum_size.x=390;box.add_theme_constant_override("separation",6);dialog.add_child(box)
 _label(box,"Settings",24)
 sections=TabContainer.new();sections.name="SettingsSections";box.add_child(sections)
 var camera:=VBoxContainer.new();camera.name="Camera";camera.add_theme_constant_override("separation",6);sections.add_child(camera)
 near_input=_distance_row(camera,"Closest zoom (m)","closest")
 far_input=_distance_row(camera,"Farthest zoom (m)","farthest")
 var sound:=VBoxContainer.new();sound.name="Sound";sound.add_theme_constant_override("separation",6);sections.add_child(sound)
 mute_toggle=CheckButton.new();mute_toggle.name="MuteAudio";mute_toggle.text="Mute game";mute_toggle.tooltip_text="Mute all audio, including music and effects";mute_toggle.focus_mode=Control.FOCUS_ALL;sound.add_child(mute_toggle);mute_toggle.toggled.connect(func(value:bool):set_value("muted",value))
 master_slider=_volume_row(sound,"Master volume","master")
 combat_slider=_volume_row(sound,"Combat volume","combat")
 distance_toggle=CheckButton.new();distance_toggle.name="DistanceAudio";distance_toggle.text="Distance affects volume";sound.add_child(distance_toggle);distance_toggle.toggled.connect(func(value:bool):set_value("distance",value))
 dialog.confirmed.connect(close);dialog.canceled.connect(close)
 dialog.window_input.connect(func(event:InputEvent):
  if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
   close();dialog.set_input_as_handled())
 _refresh_ui()
func _label(parent:Node,text:String,font_size:int)->void:
 var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",font_size);parent.add_child(label)
func _distance_row(parent:Node,title:String,key:String)->SpinBox:
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);parent.add_child(row)
 var label:=Label.new();label.text=title;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
 var input:=SpinBox.new();input.name=key;input.min_value=0.25;input.max_value=500;input.step=0.01;input.custom_minimum_size.x=120
 input.add_theme_icon_override("updown",preload("res://scripts/animation_row_icons.gd").get_icon("length_arrows"))
 row.add_child(input);input.value_changed.connect(func(value:float):set_value(key,value));return input
func _volume_row(parent:Node,title:String,key:String)->HSlider:
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);parent.add_child(row)
 var label:=Label.new();label.text=title;label.custom_minimum_size.x=180;row.add_child(label)
 var slider:=HSlider.new();slider.name=key;slider.min_value=0;slider.max_value=100;slider.step=1;slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;slider.custom_minimum_size.x=160
 row.add_child(slider);slider.value_changed.connect(func(value:float):set_value(key,value/100.0));return slider
func _refresh_ui()->void:
 if not is_instance_valid(dialog):return
 near_input.set_value_no_signal(min_camera_distance);far_input.set_value_no_signal(max_camera_distance)
 master_slider.set_value_no_signal(master_volume*100);combat_slider.set_value_no_signal(combat_volume*100)
 mute_toggle.set_pressed_no_signal(muted);distance_toggle.set_pressed_no_signal(distance_audio)
func toggle()->void:
 if opened:close()
 else:open()
func open(section:String="")->void:
 if not section.is_empty():
  for i in sections.get_tab_count():
   if sections.get_tab_title(i)==section:sections.current_tab=i;break
 if opened:return
 opened=true;previous_pause=get_tree().paused;previous_mouse=Input.mouse_mode
 get_tree().paused=true;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 _refresh_ui();dialog.popup_centered(Vector2i(450,390))
 if sections.current_tab==1:mute_toggle.grab_focus()
 else:near_input.grab_focus()
func close()->void:
 if not opened:return
 dialog.hide();opened=false;get_tree().paused=previous_pause;Input.mouse_mode=previous_mouse
func _unhandled_key_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
  toggle();get_viewport().set_input_as_handled()
