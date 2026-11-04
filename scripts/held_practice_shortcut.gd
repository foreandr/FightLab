extends RefCounted
## A temporary input binding over the existing held-cast pipeline, never new combat math.
const FIELDS:=["casting_animation","demo_duration","demo_choice_selected","demo_source_ready","sandbox_spell_record","creation_step","delivery_type","preview_delivery_type","delivery_choice_selected","element","preview_effect","limiter_enabled"]
var active:=false
var snapshot:Dictionary={}
var contacts:Dictionary={}
var physical:Dictionary={}
func begin(b:Node)->void:
 if active or b.held_cast.active or b.cast_committed() or b.editor.actor.combat_reaction_active():return
 b.stop_preview_controls(true)
 snapshot.clear()
 for key in FIELDS:
  var value:Variant=b.get(key)
  snapshot[key]=value.duplicate(true) if value is Dictionary or value is Array else value
 contacts={"selected":b.touch_authoring.selected.duplicate(),"confirmed":b.touch_authoring.confirmed,"effect_confirmed":b.touch_authoring.effect_confirmed,"preview_effect":b.touch_authoring.preview_effect}
 if physical.is_empty():
  for record in b.saved_spells.entries():
   if record.delivery_type=="Touch" and str(record.name).nocasecmp_to("Physical Touch")==0:physical=record.duplicate(true);break
  if physical.is_empty():
   physical=load("res://scripts/spell_definition.gd").make("None","Touch",{"size":0.5,"speed":0.5},{})
   physical.merge({"id":"builtin_physical_touch","name":"Physical Touch"})
 var actor=b.editor.actor
 if not actor.player.has_animation_library("practice_cross"):actor.player.add_animation_library("practice_cross",AnimationLibrary.new())
 var animation:Animation=preload("res://assets/animations/demos/left_cross.res")
 if not actor.player.has_animation("practice_cross/left_cross"):actor.player.get_animation_library("practice_cross").add_animation("left_cross",animation)
 active=true
 b.casting_animation={"title":"Left Cross","clip":"practice_cross/left_cross","step":"Cross","group":"Attack","category":"Punch","animation_type":"Arm","attack_bone":"hand_l","store_raw":true,"sandbox_animation":true,"sandbox_offensive":true,"source_duration":animation.length,"duration":animation.length}
 b.demo_duration=animation.length;b.demo_choice_selected=true;b.demo_source_ready=true
 b.sandbox_spell_record=physical.duplicate(true);b.creation_step="touch";b.delivery_type="Touch";b.preview_delivery_type="Touch";b.delivery_choice_selected=true
 b.element="None";b.preview_effect="None";b.limiter_enabled=true
 b.touch_authoring.selected.assign(["hand_l"]);b.touch_authoring.confirmed=true;b.touch_authoring.effect_confirmed=true;b.touch_authoring.preview_effect="None"
 b.held_cast.begin(b)
 if not b.held_cast.active:restore(b)
func release(b:Node)->void:
 if active:b.held_cast.release(b)
func after_step(b:Node)->void:
 if active and not b.held_cast.active and not b.playing:restore(b)
func cancel(b:Node)->void:
 if not active:return
 b.stop_preview_controls(true);restore(b)
func restore(b:Node)->void:
 if not active:return
 active=false
 for key in snapshot:b.set(key,snapshot[key])
 b.touch_authoring.selected.assign(contacts.selected)
 for key in ["confirmed","effect_confirmed","preview_effect"]:b.touch_authoring.set(key,contacts[key])
 snapshot.clear();contacts.clear()
 b.refresh_demo_choices();b.refresh_demo_timing();b.refresh_playback_controls()
