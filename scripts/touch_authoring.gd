extends VBoxContainer
## Contact/effect authoring. Runtime owns hit queries, costs and damage.
const CONTACTS:={"hand_l":"Left hand","hand_r":"Right hand","lowerarm_l":"Left elbow","lowerarm_r":"Right elbow","calf_l":"Left knee","calf_r":"Right knee","foot_l":"Left foot","foot_r":"Right foot","Head":"Head"}
var heading:Label
var contact_heading:Label
var grid:GridContainer
var effect_panel:VBoxContainer
var effect_summary:Label
var effect_buttons:Dictionary={}
var effect_confirm:Button
var preview_effect:="None"
var effect_confirmed:=false
var preview_signature:=""
var burn_label:Label
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
 heading=builder.editor.menu_label(self,"Touch",24)
 contact_heading=builder.editor.menu_label(self,"Choose contact parts",18)
 grid=GridContainer.new();grid.columns=3;add_child(grid)
 for bone in CONTACTS:
  var button:Button=builder.editor.button(grid,CONTACTS[bone],func():toggle(bone))
  button.name="TouchContact"+bone;button.toggle_mode=true;button.custom_minimum_size=Vector2(0,62)
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.icon=preload("res://scripts/animation_row_icons.gd").get_icon("head" if bone=="Head" else ("leg" if bone.begins_with("calf") or bone.begins_with("foot") else "arm"))
  button.focus_mode=Control.FOCUS_ALL;buttons[bone]=button
 confirm=builder.editor.button(self,"Next",confirm_contacts);confirm.name="ConfirmTouchContacts"
 effect_panel=VBoxContainer.new();add_child(effect_panel)
 effect_summary=builder.editor.menu_label(effect_panel,"",16);effect_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 builder.editor.menu_label(effect_panel,"Choose an effect",20)
 for effect in ["None","Fire"]:
  var button:Button=builder.editor.button(effect_panel,"Physical" if effect=="None" else "Fire",func():choose_effect(effect))
  button.name="TouchEffect"+effect;button.toggle_mode=true;button.custom_minimum_size.y=64
  button.icon=preload("res://scripts/animation_row_icons.gd").get_icon("arm" if effect=="None" else "fire")
  button.focus_mode=Control.FOCUS_ALL;effect_buttons[effect]=button
 effect_confirm=builder.editor.button(effect_panel,"Confirm",confirm_effect)
 effect_confirm.name="ConfirmTouchEffect"
 var back:Button=builder.editor.button(self,"← Back",go_back)
 builder.add_start_navigation(back)
 var content:VBoxContainer=preload("res://scripts/spell_timing_layout.gd").card(builder,column,"Touch")
 mana_label=builder.editor.menu_label(content,"Physical contact only",16)
 stamina_label=builder.editor.menu_label(content,"",16);stamina_label.add_theme_color_override("font_color",Color("34844d"))
 damage_label=builder.editor.menu_label(content,"",16);damage_label.add_theme_color_override("font_color",Color("bd413a"))
 burn_label=builder.editor.menu_label(content,"",16);burn_label.add_theme_color_override("font_color",Color("c46c2d"))
 for label in [stamina_label,damage_label,burn_label]:
  var box=preload("res://scripts/spell_stat_box.gd").new();content.add_child(box);box.setup(label,builder.editor._book_theme(),builder)
 refresh()
func reset_for_animation()->void:
 var bone:String=preload("res://scripts/combat_aim.gd").emitter(builder.casting_animation)
 selected.assign([bone if CONTACTS.has(bone) else "hand_l"])
 confirmed=false;preview_effect="None";effect_confirmed=false;refresh()
func toggle(bone:String)->void:
 if builder.cast_committed():return
 builder.stop_preview_controls();builder.begin_demo_exit()
 if selected.has(bone):selected.erase(bone)
 else:selected.append(bone)
 confirmed=false;refresh();builder.refresh_playback_controls();builder.refresh_demo_timing()
func confirm_contacts()->void:
 if selected.is_empty():return
 confirmed=true;refresh();builder.refresh_playback_controls();builder.refresh_demo_timing()
func choose_effect(effect:String)->void:
 if effect not in ["None","Fire"] or builder.cast_committed():return
 builder.stop_preview_controls();builder.begin_demo_exit()
 preview_effect=effect;effect_confirmed=false
 refresh();builder.refresh_demo_timing()
func confirm_effect()->void:
 effect_confirmed=true;refresh()
func go_back()->void:
 if builder.cast_committed():return
 builder.stop_preview_controls();builder.begin_demo_exit()
 if confirmed:
  confirmed=false;effect_confirmed=false;refresh();builder.refresh_playback_controls()
 else:builder.show_creation_step("delivery")
func base_spec()->Dictionary:
 var base:Dictionary=preload("res://scripts/combat_spell_rules.gd").touch_base(selected,preview_effect)
 if preview_effect=="Fire":
  var library=preload("res://assets/spells/fire/library.gd")
  base["appearance"]=library.selection(library.Styles.active_id({}))
  base["sound_id"]=library.sound()
 base["animation_type"]=preload("res://scripts/animation_cast_type.gd").kind(builder.casting_animation)
 return base
func refresh()->void:
 if not is_instance_valid(confirm):return
 visible=builder.creation_step=="touch"
 for bone in buttons:buttons[bone].set_pressed_no_signal(selected.has(bone))
 contact_heading.visible=not confirmed;grid.visible=not confirmed;confirm.visible=not confirmed
 confirm.disabled=selected.is_empty();confirm.text="Next"
 effect_panel.visible=confirmed
 var names:PackedStringArray=[]
 for bone in selected:names.append(CONTACTS[bone])
 effect_summary.text=" + ".join(names)
 for effect in effect_buttons:effect_buttons[effect].set_pressed_no_signal(effect==preview_effect)
 effect_confirm.disabled=effect_confirmed;effect_confirm.text="Confirmed" if effect_confirmed else "Confirm"
 if builder.spell_sections.has("Touch"):builder.spell_sections.Touch.visible=is_visible_in_tree()
func refresh_stats(spec:Dictionary)->void:
 mana_label.text="Fire touch" if preview_effect=="Fire" else "Physical contact only"
 burn_label.visible=preview_effect=="Fire"
 if burn_label.visible:
  var burn=preload("res://scripts/burn_rules.gd")
  var dps:float=burn.dps(float(spec.get("potency",1.0)))
  burn_label.text="Burn: %.1f/s · %.1f total / %.0f s"%[dps,dps*burn.DURATION,burn.DURATION]
  burn_label.tooltip_text="Burn per second = %.1f\nDuration = %.1f seconds\nTotal = %.1f × %.1f = %.1f"%[dps,burn.DURATION,dps,burn.DURATION,dps*burn.DURATION]
 stamina_label.text="Stamina depletion: %.1f"%float(spec.get("stamina_cost",0.0))
 damage_label.text="Physical damage: %.1f"%float(spec.get("damage",0.0))
 var physical:Dictionary=preload("res://scripts/combat_spell_rules.gd").physical(builder.demo_duration,builder.demo_offensive())
 stamina_label.tooltip_text="Animation stamina = %.1f\nExtra contact cost = %.1f\n\nStamina = %.1f + %.1f = %.1f"%[physical.stamina,float(spec.get("touch_contact_stamina",0.0)),physical.stamina,float(spec.get("touch_contact_stamina",0.0)),float(spec.get("stamina_cost",0.0))]
 damage_label.tooltip_text="Base damage = %.1f\nAnimation type multiplier = %.2f\n\nAuthored physical damage = %.1f\nMovement speed and headshots apply at contact."%[physical.damage,float(spec.get("animation_type_multiplier",1.0)),float(spec.get("damage",0.0))]

func _process(_delta:float)->void:
 if not is_instance_valid(builder) or not is_instance_valid(builder.editor.actor):return
 var visible_step:=is_visible_in_tree()
 # Warm region geometry on selection, but show it only during playback.
 if visible_step:
  var ready_visual=builder.editor.actor.ensure_touch_contact_visual()
  for bone in selected:ready_visual.ensure_region(bone)
 var active:bool=visible_step and builder.playing
 var next_signature:=JSON.stringify([selected,preview_effect]) if active else "[]"
 var visual=builder.editor.actor.touch_contact_visual
 if preview_signature==next_signature and is_instance_valid(visual) and visual.preview_spec.is_empty()==(not active):return
 preview_signature=next_signature
 if active or is_instance_valid(visual):builder.editor.actor.ensure_touch_contact_visual().set_preview(base_spec() if active else {})
func _exit_tree()->void:
 if is_instance_valid(builder) and is_instance_valid(builder.editor.actor) and is_instance_valid(builder.editor.actor.touch_contact_visual):builder.editor.actor.touch_contact_visual.set_preview({})
