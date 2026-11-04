extends RefCounted
## One upcoming held input. It owns no poses, damage or resource payment.
const Hold=preload("res://scripts/held_cast_preview.gd")
var pending:=false
var action:=""
var seconds:=0.0
var key_released:=false
var profile:Dictionary={}

func press(b:Node,next:String)->void:
 if b.editor.actor.combat_reaction_active() or b.editor.actor.health<=0.0:return
 if pending:return # One upcoming action, never an unbounded macro queue.
 if not b.playing or (b.cast_committed() and b.prepare_combo_start()):
  start(b,next,0.0,false);return
 action=next;seconds=0.0;key_released=false
 profile=(b.held_practice_shortcut.snapshot.get("casting_animation",b.casting_animation) if b.held_practice_shortcut.active else b.casting_animation).duplicate(true) if next=="selected" else b.held_practice_shortcut.profile_for(b,next)
 if profile.is_empty():return
 pending=true
 if not b.held_cast.active:b.held_cast.ensure_feedback(b,preload("res://scripts/combat_aim.gd").emitter(profile))
 show_feedback(b)

func release(b:Node,next:String)->void:
 if pending and action==next:key_released=true;return
 if next=="selected":
  if not b.held_practice_shortcut.active:b.held_cast.release(b)
 else:b.held_practice_shortcut.release(b,next)

func advance(b:Node,delta:float)->void:
 if not pending:return
 if b.editor.actor.combat_reaction_active() or b.editor.actor.health<=0.0 or not b.get_window().has_focus() or b.editor.camera_text_editing() or preload("res://scripts/combat_pointer.gd").dialog_open(b.get_viewport()):
  cancel(b);return
 # Accept overlapping key-downs, but charge only one held windup at a time.
 if b.held_cast.active:return
 if not is_instance_valid(b.held_cast.feedback) or not b.held_cast.feedback.holding:
  b.held_cast.ensure_feedback(b,preload("res://scripts/combat_aim.gd").emitter(profile))
 if not key_released:seconds=minf(60.0,seconds+maxf(delta,0.0))
 show_feedback(b)

func show_feedback(b:Node)->void:
 if b.held_cast.active:return
 var feedback=b.held_cast.feedback
 if not is_instance_valid(feedback):return
 var normalized:=seconds/Hold.charge_window(profile)
 feedback.progress(normalized)
 feedback.quote_label.text="Next · %s\n%s"%[profile.get("title","Cast"),preload("res://scripts/cast_charge_rules.gd").sample(normalized).name]

func flush(b:Node)->void:
 if not pending:return
 var next:=action;var held:=seconds;var released:=key_released
 if b.playing and (not b.released or not b.prepare_combo_start()):return
 pending=false;profile={}
 start(b,next,held,released)

func start(b:Node,next:String,held:float,released:bool)->void:
 if next=="selected":
  if b.held_practice_shortcut.active:b.held_practice_shortcut.restore(b)
  b.held_cast.begin(b)
 else:b.held_practice_shortcut.begin(b,next)
 if not b.held_cast.active:return
 b.held_cast.seed_hold(b,held)
 if released:b.held_cast.release(b)

func cancel(b:Node)->void:
 if pending and is_instance_valid(b.held_cast.feedback):b.held_cast.feedback.finish()
 pending=false;profile={};seconds=0.0;key_released=false
