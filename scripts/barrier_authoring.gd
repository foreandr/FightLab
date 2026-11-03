extends VBoxContainer
## Shield setup UI. Shared casting/runtime own activation, absorption and expiry.
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
var strength:=10.0
var lifetime:=1.0
var strength_label:Label
var strength_slider:HSlider
var lifetime_label:Label
var lifetime_slider:HSlider
var amp_label:Label
var stamina_label:Label
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
 var content:VBoxContainer=preload("res://scripts/spell_timing_layout.gd").card(builder,column,"Shield")
 size_card=builder.spell_sections["Shield"]
 size_label=builder.editor.menu_label(content,"Radius: 1.5 m",18)
 size_slider=HSlider.new();content.add_child(size_slider)
 size_slider.name="BarrierRadius";size_slider.min_value=0.25;size_slider.max_value=10.0;size_slider.step=0.05;size_slider.value=radius
 size_slider.custom_minimum_size.y=28;size_slider.focus_mode=Control.FOCUS_ALL
 size_slider.value_changed.connect(func(value:float):radius=value;size_confirmed=false;refresh())
 strength_label=builder.editor.menu_label(content,"Shield strength: 10",18)
 strength_slider=HSlider.new();content.add_child(strength_slider)
 strength_slider.name="ShieldStrength";strength_slider.min_value=1.0;strength_slider.max_value=100.0;strength_slider.step=1.0;strength_slider.value=strength;strength_slider.custom_minimum_size.y=28
 strength_slider.focus_mode=Control.FOCUS_ALL
 strength_slider.tooltip_text="Blocked physical damage also drains stamina. Activate within 0.12 s of impact to parry effects and refund 5 mana."
 strength_slider.value_changed.connect(func(value:float):strength=value;size_confirmed=false;refresh();builder.refresh_demo_timing())
 lifetime_label=builder.editor.menu_label(content,"Duration: 1.0 s",18)
 lifetime_slider=HSlider.new();content.add_child(lifetime_slider)
 lifetime_slider.name="ShieldDuration";lifetime_slider.min_value=0.1;lifetime_slider.max_value=30.0;lifetime_slider.step=0.1;lifetime_slider.value=lifetime;lifetime_slider.custom_minimum_size.y=28
 lifetime_slider.focus_mode=Control.FOCUS_ALL
 lifetime_slider.tooltip_text="Time after activation before the shield expires."
 lifetime_slider.value_changed.connect(func(value:float):lifetime=value;size_confirmed=false;refresh();builder.refresh_demo_timing())
 amp_label=builder.editor.menu_label(content,"Spell amp: +0%",16)
 amp_label.add_theme_color_override("font_color",Color("8b56b8"))
 stamina_label=builder.editor.menu_label(content,"Stamina depletion: 0",16)
 stamina_label.add_theme_color_override("font_color",Color("34844d"))
 preview=preload("res://scripts/barrier_volume_preview.gd").new();builder.editor.field.add_child(preview)
 place_ahead();refresh()
func reset()->void:
 attachment="";attachment_confirmed=false;size_confirmed=false;picking_location=false
 radius=1.5;size_slider.set_value_no_signal(radius)
 strength=10.0;lifetime=1.0;strength_slider.set_value_no_signal(strength);lifetime_slider.set_value_no_signal(lifetime)
 builder.editor.actor.self_barrier.clear()
 place_ahead();refresh()
func choose(kind:String)->void:
 if not choices.has(kind) or choices[kind].disabled:return
 attachment=kind;attachment_confirmed=false;size_confirmed=false;picking_location=false
 if kind=="Place":place_ahead()
 refresh()
func confirm_choice()->void:
 if attachment.is_empty():return
 if not attachment_confirmed:attachment_confirmed=true
 else:size_confirmed=true
 picking_location=false;refresh();builder.refresh_playback_controls();builder.refresh_demo_timing()
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
 return {"attachment":attachment,"radius":radius,"position":placed_ground,"shape":"body" if attachment=="Self" else "sphere","shield_strength":strength,"shield_duration":lifetime}
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
 heading.text="Self Block" if attachment_confirmed else "Where is the shield?"
 for kind in choices:
  choices[kind].visible=not attachment_confirmed or attachment==kind
  choices[kind].set_pressed_no_signal(attachment==kind)
 confirm.disabled=attachment.is_empty() or size_confirmed
 confirm.text="Confirmed" if size_confirmed else "Confirm"
 position_row.visible=attachment=="Place"
 pick_button.text="Click a surface…" if picking_location else "Choose location"
 size_card.visible=is_visible_in_tree() and attachment_confirmed
 size_label.visible=attachment!="Self"
 size_label.text="Radius: %.2f m"%radius
 strength_label.text="Shield strength: %.0f"%strength
 lifetime_label.text="Duration: %.1f s"%lifetime
 size_slider.visible=attachment!="Self"
 if attachment_confirmed:refresh_stats(builder.demo_preview_spec())
 update_preview()
func refresh_stats(spec:Dictionary)->void:
 amp_label.text="Spell amp: +%.1f%%"%((float(spec.get("spell_amplifier",1.0))-1.0)*100.0)
 stamina_label.text="Cast stamina: %.1f\nNormal block: 1 stamina per damage\nPerfect parry: 0 impact stamina"%float(spec.get("stamina_cost",0.0))
 stamina_label.tooltip_text="Block (green): physical only, impact stamina. Perfect timing (blue): no impact stamina, stops effects, +5 mana, +10% cast speed. Directional perfect (gold): face within 30 degrees of the incoming attack, +10 mana, +20% cast speed. Both perfect tiers use the same 0.12 s window."
 strength_label.text="Shield strength: %.0f → %.1f"%[strength,float(spec.get("shield_strength",strength))]
 strength_label.tooltip_text="Base strength × block multiplier = physical damage blocked\n%.1f × %.3f = %.1f"%[strength,float(spec.get("shield_strength_multiplier",1.0)),float(spec.get("shield_strength",strength))]
 lifetime_label.text="Duration: %.1f s"%lifetime

func update_preview()->void:
 if not is_instance_valid(preview):return
 preview.visible=is_visible_in_tree() and attachment!="Self" and not attachment.is_empty() and builder.editor.actor.health>0.0
 if preview.visible:preview.update_volume(builder.editor.actor,attachment,radius,placed_ground)
func _process(_delta:float)->void:
 if is_instance_valid(size_card):size_card.visible=is_visible_in_tree() and attachment_confirmed
 update_preview()
func _exit_tree()->void:
 if is_instance_valid(preview):preview.queue_free()
