extends VBoxContainer
## Contact selection only. Runtime owns hit queries, costs and damage.
const CONTACTS:={"hand_l":"Left hand","hand_r":"Right hand","lowerarm_l":"Left elbow","lowerarm_r":"Right elbow","calf_l":"Left knee","calf_r":"Right knee","foot_l":"Left foot","foot_r":"Right foot","Head":"Head"}
var builder:Control
var selected:Array[String]=["hand_l"]
var confirmed:=false
var buttons:Dictionary={}
var confirm:Button
var mana_label:Label
var stamina_label:Label
var damage_label:Label
func configure(owner_builder:Control,column:VBoxContainer)->void:
 builder=owner_builder;name="TouchWorkspace"
 builder.editor.menu_label(self,"Touch · Physical",24)
 builder.editor.menu_label(self,"Choose contact parts",18)
 var grid:=GridContainer.new();grid.columns=3;add_child(grid)
 for bone in CONTACTS:
  var button:Button=builder.editor.button(grid,CONTACTS[bone],func():toggle(bone))
  button.name="TouchContact"+bone;button.toggle_mode=true;button.custom_minimum_size=Vector2(0,62)
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.icon=preload("res://scripts/animation_row_icons.gd").get_icon("head" if bone=="Head" else ("leg" if bone.begins_with("calf") or bone.begins_with("foot") else "arm"))
  button.focus_mode=Control.FOCUS_ALL;buttons[bone]=button
 confirm=builder.editor.button(self,"Confirm",confirm_contacts);confirm.name="ConfirmTouchContacts"
 var back:Button=builder.editor.button(self,"← Back",func():builder.show_creation_step("delivery"))
 builder.add_start_navigation(back)
 var content:VBoxContainer=preload("res://scripts/spell_timing_layout.gd").card(builder,column,"Touch")
 mana_label=builder.editor.menu_label(content,"Physical contact only",16)
 stamina_label=builder.editor.menu_label(content,"",16);stamina_label.add_theme_color_override("font_color",Color("34844d"))
 damage_label=builder.editor.menu_label(content,"",16);damage_label.add_theme_color_override("font_color",Color("bd413a"))
 for label in [stamina_label,damage_label]:
  var box=preload("res://scripts/spell_stat_box.gd").new();content.add_child(box);box.setup(label,builder.editor._book_theme(),builder)
 refresh()
func reset_for_animation()->void:
 var bone:String=preload("res://scripts/combat_aim.gd").emitter(builder.casting_animation)
 selected.assign([bone if CONTACTS.has(bone) else "hand_l"])
 confirmed=false;refresh()
func toggle(bone:String)->void:
 if builder.cast_committed():return
 builder.stop_preview_controls();builder.begin_demo_exit()
 if selected.has(bone):selected.erase(bone)
 else:selected.append(bone)
 confirmed=false;refresh();builder.refresh_playback_controls();builder.refresh_demo_timing()
func confirm_contacts()->void:
 if selected.is_empty():return
 confirmed=true;refresh();builder.refresh_playback_controls();builder.refresh_demo_timing()
func base_spec()->Dictionary:
 var base:Dictionary=preload("res://scripts/combat_spell_rules.gd").touch_base(selected)
 base["animation_type"]=preload("res://scripts/animation_cast_type.gd").kind(builder.casting_animation)
 return base
func refresh()->void:
 if not is_instance_valid(confirm):return
 visible=builder.creation_step=="touch"
 for bone in buttons:buttons[bone].set_pressed_no_signal(selected.has(bone))
 confirm.disabled=selected.is_empty() or confirmed;confirm.text="Confirmed" if confirmed else "Confirm"
 if builder.spell_sections.has("Touch"):builder.spell_sections.Touch.visible=is_visible_in_tree()
func refresh_stats(spec:Dictionary)->void:
 mana_label.text="Physical contact only"
 stamina_label.text="Stamina depletion: %.1f"%float(spec.get("stamina_cost",0.0))
 damage_label.text="Physical damage: %.1f"%float(spec.get("damage",0.0))
 var physical:Dictionary=preload("res://scripts/combat_spell_rules.gd").physical(builder.demo_duration,builder.demo_offensive())
 stamina_label.tooltip_text="Animation stamina = %.1f\nExtra contact cost = %.1f\n\nStamina = %.1f + %.1f = %.1f"%[physical.stamina,float(spec.get("touch_contact_stamina",0.0)),physical.stamina,float(spec.get("touch_contact_stamina",0.0)),float(spec.get("stamina_cost",0.0))]
 damage_label.tooltip_text="Base damage = %.1f\nAnimation type multiplier = %.2f\n\nAuthored physical damage = %.1f\nMovement speed and headshots apply at contact."%[physical.damage,float(spec.get("animation_type_multiplier",1.0)),float(spec.get("damage",0.0))]
