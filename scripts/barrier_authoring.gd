extends VBoxContainer
## Shield setup UI. Preview geometry is separate from future protection rules.
const Icons=preload("res://scripts/animation_row_icons.gd")
var builder:Control
var choices:Dictionary={}
var attachment:=""
var attachment_confirmed:=false
var size_confirmed:=false
var radius:=1.5
var placed_ground:=Vector3.ZERO
var picking_location:=false
var heading:Label
var confirm:Button
var position_row:HBoxContainer
var pick_button:Button
var size_card:Control
var size_label:Label
var size_slider:HSlider
var preview:Node3D
func configure(owner_builder:Control,column:VBoxContainer)->void:
 builder=owner_builder;name="ShieldPlacement"
 heading=builder.editor.menu_label(self,"Where is the shield?",20)
 for kind in ["Self","Follow","Place"]:
  var title:String={"Self":"Self · Block","Follow":"Follow me","Place":"Place in the arena"}[kind]
  var button:Button=builder.editor.button(self,title,func():choose(kind))
  button.name="Shield"+kind;button.toggle_mode=true;button.custom_minimum_size.y=64
  button.icon=Icons.get_icon({"Self":"shield_self","Follow":"shield_follow","Place":"shield_place"}[kind])
  button.add_theme_constant_override("icon_max_width",40)
  button.tooltip_text={"Self":"A transparent barrier fitted to your body.","Follow":"A sphere centered on you that moves with you.","Place":"A sphere that stays at the chosen arena location."}[kind]
  button.disabled=kind!="Self"
  if button.disabled:button.tooltip_text="Not available yet"
  button.focus_mode=Control.FOCUS_ALL;choices[kind]=button
 position_row=HBoxContainer.new();add_child(position_row)
 pick_button=builder.editor.button(position_row,"Choose location",func():picking_location=not picking_location;refresh())
 pick_button.name="PickShieldLocation"
 var ahead:Button=builder.editor.button(position_row,"Place ahead",place_ahead)
 ahead.name="PlaceShieldAhead"
 confirm=builder.editor.button(self,"Confirm",confirm_choice);confirm.name="ConfirmShieldPlacement"
 var content:VBoxContainer=preload("res://scripts/spell_timing_layout.gd").card(builder,column,"Barrier size")
 size_card=builder.spell_sections["Barrier size"]
 size_label=builder.editor.menu_label(content,"Radius: 1.5 m",18)
 size_slider=HSlider.new();content.add_child(size_slider)
 size_slider.name="BarrierRadius";size_slider.min_value=0.25;size_slider.max_value=10.0;size_slider.step=0.05;size_slider.value=radius
 size_slider.custom_minimum_size.y=28;size_slider.focus_mode=Control.FOCUS_ALL
 size_slider.value_changed.connect(func(value:float):radius=value;size_confirmed=false;refresh())
 preview=preload("res://scripts/barrier_volume_preview.gd").new();builder.editor.field.add_child(preview)
 place_ahead();refresh()
func reset()->void:
 attachment="";attachment_confirmed=false;size_confirmed=false;picking_location=false
 radius=1.5;size_slider.set_value_no_signal(radius);place_ahead();refresh()
func choose(kind:String)->void:
 if not choices.has(kind) or choices[kind].disabled:return
 attachment=kind;attachment_confirmed=false;size_confirmed=false;picking_location=false
 if kind=="Place":place_ahead()
 refresh()
func confirm_choice()->void:
 if attachment.is_empty():return
 if not attachment_confirmed:attachment_confirmed=true
 else:size_confirmed=true
 picking_location=false;refresh()
func go_back()->bool:
 if attachment_confirmed:
  attachment_confirmed=false;size_confirmed=false;picking_location=false;refresh();return true
 return false
func place_ahead()->void:
 var actor=builder.editor.actor
 placed_ground=builder.editor.field.surface_placement(actor.global_position+actor.global_basis.z*4.0)
 picking_location=false;size_confirmed=false;refresh()
func set_location(ground:Vector3)->void:
 placed_ground=builder.editor.field.surface_placement(ground)
 picking_location=false;size_confirmed=false;refresh()
func definition()->Dictionary:
 return {"attachment":attachment,"radius":radius,"position":placed_ground,"shape":"body" if attachment=="Self" else "sphere"}
func handle_input(event:InputEvent,area:Control)->bool:
 if not picking_location or not is_visible_in_tree():return false
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  picking_location=false;refresh();return true
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and is_instance_valid(area) and area.get_global_rect().has_point(event.position):
  var camera:Camera3D=builder.editor.field.camera
  var from:Vector3=camera.project_ray_origin(event.position)
  var query:=PhysicsRayQueryParameters3D.create(from,from+camera.project_ray_normal(event.position)*500.0,1|1024)
  var hit:Dictionary=builder.editor.actor.get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty():set_location(hit.position)
  return true
 return false
func refresh()->void:
 if not is_instance_valid(builder) or not is_instance_valid(confirm):return
 visible=builder.creation_step=="shield"
 heading.text="Barrier size" if attachment_confirmed else "Where is the shield?"
 for kind in choices:
  choices[kind].visible=not attachment_confirmed or attachment==kind
  choices[kind].set_pressed_no_signal(attachment==kind)
 confirm.disabled=attachment.is_empty() or size_confirmed
 confirm.text="Size confirmed" if size_confirmed else "Confirm"
 position_row.visible=attachment=="Place"
 pick_button.text="Click a surface…" if picking_location else "Choose location"
 size_card.visible=is_visible_in_tree() and attachment_confirmed
 size_label.text="Fitted to body" if attachment=="Self" else "Radius: %.2f m"%radius
 size_slider.visible=attachment!="Self"
 update_preview()
func update_preview()->void:
 if not is_instance_valid(preview):return
 preview.visible=is_visible_in_tree() and not attachment.is_empty() and builder.editor.actor.health>0.0
 if preview.visible:preview.update_volume(builder.editor.actor,attachment,radius,placed_ground)
func _process(_delta:float)->void:
 if is_instance_valid(size_card):size_card.visible=is_visible_in_tree() and attachment_confirmed
 update_preview()
func _exit_tree()->void:
 if is_instance_valid(preview):preview.queue_free()
