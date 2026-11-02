extends VBoxContainer
## Same cards and spacing as flame styles; pictures show each sound's actual waveform.
signal sound_chosen(id:String)
const Sounds=preload("res://assets/spells/fire/sounds.gd")
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
 resized.connect(update_columns)
func open_sounds()->void:
 if not choices.is_empty():
  update_columns();return
 var group:=ButtonGroup.new()
 for entry in Sounds.ENTRIES:
  var id:String=entry.id
  var title_:String=str(entry.title).replace(" · Default","")
  var button:=preload("res://scripts/asset_preview_card.gd").create(id,title_,thumbnail(id),str(entry.title)+"\nClick to preview")
  button.button_group=group
  button.pressed.connect(func():sound_chosen.emit(id))
  grid.add_child(button);choices[id]=button
 update_columns()
func update_columns()->void:
 grid.columns=4 if size.x>=370 else 3
func select_sound(id:String)->void:
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
