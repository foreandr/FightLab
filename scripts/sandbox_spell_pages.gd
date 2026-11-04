extends VBoxContainer
## Pages over the existing authoring controls. No spell calculations live here.
var builder:Node
var column:VBoxContainer
var page:="wizard"
var heading:Label
var previous:Button
var next:Button
var last_state:=""
var had_animation:=false
func setup(owner_builder:Node,content:VBoxContainer)->void:
 builder=owner_builder;column=content
 process_priority=100
 name="SandboxSpellPages";add_theme_constant_override("separation",6)
 var scroll=column.get_parent()
 column.reparent(self)
 builder.demo_timing_panel.add_child(self)
 scroll.queue_free()
 heading=Label.new();heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_theme_font_size_override("font_size",18)
 add_child(heading);move_child(heading,0)
 column.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var nav:=HBoxContainer.new();add_child(nav)
 previous=Button.new();previous.text="← Back";previous.focus_mode=Control.FOCUS_ALL;nav.add_child(previous);previous.pressed.connect(go_back)
 var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;nav.add_child(spacer)
 next=Button.new();next.text="Next →";next.focus_mode=Control.FOCUS_ALL;nav.add_child(next);next.pressed.connect(go_next)
 for connection in builder.delivery_back_button.pressed.get_connections():builder.delivery_back_button.pressed.disconnect(connection.callable)
 last_state=state_key();apply_page()
func state_key()->String:
 return str([builder.creation_step,builder.fire_shapes_open,builder.fire_sound_open,builder.spell_save_open,builder.touch_authoring.confirmed,builder.touch_authoring.effect_confirmed,builder.barrier_authoring.attachment_confirmed,builder.barrier_authoring.size_confirmed])
func show_page(value:String)->void:
 page=value;apply_page()
func stages()->Array[String]:
 if builder.spell_delivery_type()=="Projectile":return ["mana","power","results","save"]
 return ["mana","results"]
func go_next()->void:
 if page=="shield":
  builder.barrier_authoring.confirm_choice();show_page("mana")
 else:
  var sequence:=stages();var index:=sequence.find(page)
  if index>=0 and index+1<sequence.size():show_page(sequence[index+1])
  elif index>=0:builder.play_projectile_once()
func go_back()->void:
 if page=="wizard":return
 if page=="shield":builder.barrier_authoring.go_back();show_page("wizard");return
 var sequence:=stages();var index:=sequence.find(page)
 if index>0:show_page(sequence[index-1])
 elif index==0:
  if builder.spell_delivery_type()=="Barrier":show_page("shield")
  elif builder.spell_delivery_type()=="Projectile":
   builder.spell_save_open=false;builder.refresh_effect_choices();show_page("wizard")
  else:
   builder.touch_authoring.effect_confirmed=false;builder.touch_authoring.refresh();show_page("wizard")
func wizard_control()->Control:
 match builder.creation_step:
  "delivery":return builder.delivery_screen
  "barrier","shield":return builder.barrier_screen
  "touch":return builder.touch_authoring
 return builder.projectile_screen
func active_control()->Control:
 match page:
  "wizard":return wizard_control()
  "mana":return builder.spell_sections.Mana
  "power":return builder.spell_sections["Power balance"]
  "shield":return builder.spell_sections.Shield
  "save":return builder.projectile_screen
  "results":
   if builder.spell_delivery_type()=="Barrier":return builder.spell_sections.Shield
   if builder.spell_delivery_type()=="Touch":return builder.spell_sections.Touch
   return builder.spell_sections.Results
 return wizard_control()
func page_title()->String:
 if page=="mana":return "Mana"
 if page=="power":return "Power balance"
 if page=="results":return "Results"
 if page=="shield":return "Shield strength & duration"
 if page=="save":return "Save spell"
 if builder.creation_step=="delivery":return "Spell type"
 if builder.creation_step=="touch":return "Touch effect" if builder.touch_authoring.confirmed else "Contact parts"
 if builder.creation_step=="barrier":return "Barrier type"
 if builder.creation_step=="shield":return "Shield placement"
 if builder.fire_sound_open:return "Fire sound"
 if builder.fire_shapes_open:return "Fire style"
 return "Spell effect"
func apply_page()->void:
 var active:=active_control()
 for child in column.get_children():
  if child is Control:child.visible=child==active
 if page=="save" and not builder.spell_save_open:
  builder.spell_save_open=true;builder.refresh_effect_choices()
 if active in builder.spell_sections.values():
  active.header.hide()
  if active.collapsed:active.set_collapsed(false,false)
  active.content.show()
 heading.text=page_title()
 heading.visible=page not in ["wizard","save"]
 previous.visible=page!="wizard"
 next.visible=page not in ["wizard","save"]
 next.disabled=false
 # The root is now spell selection; it has no preceding timing page.
 builder.delivery_back_button.hide()
 next.text="Test spell" if page=="results" and builder.spell_delivery_type()!="Projectile" else "Next →"
 fit_page(active)
func fit_page(active:Control)->void:
 # Keep the existing 12-style gallery paginated within this narrow panel.
 if builder.fire_style_gallery.grid.columns!=4:builder.fire_style_gallery.grid.columns=4
 for control in active.find_children("*","Control",true,false):
  if control is Label and control.get_theme_font_size("font_size")>16:control.add_theme_font_size_override("font_size",16)
  if control is Button:
   var preview=control.find_child("PreviewImage",true,false)
   if preview!=null:
    control.custom_minimum_size=Vector2(64,78);preview.custom_minimum_size.y=42
   else:control.custom_minimum_size.y=minf(control.custom_minimum_size.y,32)
func _process(_delta:float)->void:
 if not is_instance_valid(builder):return
 var current:=state_key()
 if had_animation and not builder.demo_choice_selected:page="wizard"
 elif current!=last_state:
  if builder.spell_save_open:page="mana"
  elif builder.creation_step=="touch" and builder.touch_authoring.effect_confirmed:page="mana"
  elif builder.creation_step=="shield" and builder.barrier_authoring.attachment_confirmed:
   page="mana" if builder.barrier_authoring.size_confirmed else "shield"
  else:page="wizard"
 had_animation=builder.demo_choice_selected;last_state=current
 apply_page()
