extends VBoxContainer
## Same cards and spacing as flame styles; pictures show each sound's actual waveform.
signal sound_chosen(id:String)
const Sounds=preload("res://assets/spells/fire/sounds.gd")
const PAGE_SIZE:=12
var page:=0
var selected_id:=""
var previous_button:Button
var next_button:Button
var page_input:SpinBox
var page_label:Label
var choices:Dictionary={}
var grid:GridContainer
static var thumbnails:Dictionary={}
func setup(book_theme:Theme)->void:
 theme=book_theme
 add_theme_constant_override("separation",6)
 var title:=Label.new();title.text="Fire sounds · %d"%Sounds.ENTRIES.size()
 title.add_theme_font_size_override("font_size",18);add_child(title)
 grid=GridContainer.new();grid.columns=4
 grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);add_child(grid)
 var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",6);add_child(footer)
 previous_button=Button.new();previous_button.text="← Prev";previous_button.focus_mode=Control.FOCUS_ALL
 previous_button.add_theme_font_size_override("font_size",13);footer.add_child(previous_button)
 previous_button.pressed.connect(func():set_page(page-1))
 page_input=SpinBox.new();page_input.min_value=1;page_input.max_value=page_count();page_input.step=1;page_input.custom_minimum_size.x=62
 page_input.add_theme_icon_override("updown",preload("res://scripts/animation_row_icons.gd").get_icon("length_arrows"))
 page_input.add_theme_font_size_override("font_size",13);page_input.focus_mode=Control.FOCUS_ALL;page_input.tooltip_text="Page"
 footer.add_child(page_input);page_input.value_changed.connect(func(value:float):set_page(int(value)-1))
 page_label=Label.new();page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(page_label)
 next_button=Button.new();next_button.text="Next →";next_button.focus_mode=Control.FOCUS_ALL
 next_button.add_theme_font_size_override("font_size",13);footer.add_child(next_button);next_button.pressed.connect(func():set_page(page+1))
 resized.connect(update_columns)
func page_count()->int:return maxi(1,ceili(Sounds.ENTRIES.size()/float(PAGE_SIZE)))
func open_sounds(id:String="")->void:
 selected_id=id
 var index:=0
 for i in Sounds.ENTRIES.size():
  if Sounds.ENTRIES[i].id==id:index=i;break
 set_page(floori(index/float(PAGE_SIZE)))
func set_page(value:int)->void:
 page=clampi(value,0,page_count()-1)
 choices.clear()
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 var group:=ButtonGroup.new()
 for i in range(page*PAGE_SIZE,mini((page+1)*PAGE_SIZE,Sounds.ENTRIES.size())):
  var entry:Dictionary=Sounds.ENTRIES[i]
  var id:String=entry.id
  var title_:String=str(entry.title).replace(" · Default","")
  var tooltip:=str(entry.title)+("\n"+str(entry.author)+" · "+str(entry.license) if entry.has("author") else "")+"\nClick to preview"
  var button:=preload("res://scripts/asset_preview_card.gd").create(id,title_,thumbnail(id),tooltip)
  button.button_group=group
  button.set_pressed_no_signal(id==selected_id)
  button.pressed.connect(func():sound_chosen.emit(id))
  grid.add_child(button);choices[id]=button
 previous_button.disabled=page==0;next_button.disabled=page==page_count()-1
 page_input.max_value=page_count();page_input.set_value_no_signal(page+1);page_label.text="/ %d"%page_count()
 update_columns()
func update_columns()->void:
 grid.columns=4 if size.x>=370 else 3
func select_sound(id:String)->void:
 selected_id=id
 for key in choices:choices[key].set_pressed_no_signal(key==id)
static func thumbnail(id:String)->Texture2D:
 if thumbnails.has(id):return thumbnails[id]
 var stream:=Sounds.synthesize(id)
 var image:=Image.create(144,144,false,Image.FORMAT_RGBA8);image.fill(Color("382b21"))
 var bins:=52
 var peaks:PackedFloat32Array=[]
 var maximum:=1.0
 var count:=stream.data.size()/2
 for bin in bins:
  var peak:=0.0
  for sample in range(int(bin*count/bins),int((bin+1)*count/bins),4):peak=maxf(peak,absf(stream.data.decode_s16(sample*2)))
  peaks.append(peak);maximum=maxf(maximum,peak)
 for bin in bins:
  var half:=maxi(1,int(peaks[bin]/maximum*35.0))
  for x in range(20+bin*2,22+bin*2):
   for y in range(72-half,73+half):image.set_pixel(x,y,Color("ffb347") if absi(y-72)>half/2 else Color("ffe889"))
 # Small playback mark above the waveform.
 for x in range(64,81):
  var half:=int((81-x)*0.55)
  for y in range(26-half,27+half):image.set_pixel(x,y,Color("ffe889"))
 thumbnails[id]=ImageTexture.create_from_image(image)
 return thumbnails[id]
