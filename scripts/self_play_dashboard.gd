extends Control
const Design=preload("res://scripts/ui_design.gd")
const SPEEDS:=[1,2,4,8,16]
var service:Node
var matches:SpinBox
var speed:OptionButton
var mode_choice:OptionButton
var evaluation:SpinBox
var eval_pairs:SpinBox
var start_button:Button
var pause_button:Button
var stop_button:Button
var log_button:Button
var models_button:Button
var progress_bar:ProgressBar
var round_bar:ProgressBar
var heading:Label
var detail:Label
var completed:Label
var round_label:Label
var metric_labels:Dictionary={}
var chart:Control
var recent:Label
var log_text:Label
var refresh_left:=0.0
func _ready():
 theme=Design.theme();service=get_node("/root/SelfPlayTraining")
 get_tree().root.get_node("SharedMusic").enter_context("menu",self)
 build_ui();restore_options();service.changed.connect(refresh);refresh()
func label(parent:Node,text:String,size_:int=18,color:Color=Design.TEXT)->Label:
 var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",size_);node.add_theme_color_override("font_color",color);parent.add_child(node);return node
func button(parent:Node,text:String,callback:Callable)->Button:
 var node:=Button.new();node.text=text;node.custom_minimum_size.y=38;node.focus_mode=Control.FOCUS_ALL;node.pressed.connect(callback);parent.add_child(node);return node
func panel(parent:Node)->VBoxContainer:
 var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",Design.box());parent.add_child(frame)
 var margins:=MarginContainer.new()
 for side in ["left","right","top","bottom"]:margins.add_theme_constant_override("margin_"+side,14)
 frame.add_child(margins)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);margins.add_child(column);return column
func build_ui():
 var bg:=ColorRect.new();bg.color=Design.VOID;bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,20)
 add_child(margin)
 var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",14);margin.add_child(outer)
 var header:=HBoxContainer.new();outer.add_child(header)
 var back:=button(header,"‹  Dev",func():get_tree().set_meta("home_page","Dev");get_tree().change_scene_to_file("res://scenes/home.tscn"));back.name="BackToDev"
 label(header,"SELF PLAY",30,Design.CYAN)
 var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(spacer)
 label(header,"Train  ·  Save  ·  Compare",16,Design.MUTED)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;outer.add_child(scroll)
 var body:=HBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",14);scroll.add_child(body)
 var setup:=panel(body);setup.get_parent().get_parent().custom_minimum_size.x=250
 label(setup,"TRAINING SETUP",18,Design.CYAN)
 label(setup,"Matches",15,Design.MUTED);matches=SpinBox.new();matches.name="TrainingMatchCount";matches.min_value=1;matches.max_value=1000000;matches.step=1;setup.add_child(matches)
 label(setup,"Requested speed",15,Design.MUTED);speed=OptionButton.new();speed.name="TrainingSpeed"
 for value in SPEEDS:speed.add_item(str(value)+"×")
 setup.add_child(speed)
 label(setup,"Animation processing",15,Design.MUTED);mode_choice=OptionButton.new();mode_choice.name="TrainingPoseMode";mode_choice.add_item("Standard");mode_choice.add_item("Fast · collision poses");setup.add_child(mode_choice)
 mode_choice.tooltip_text="Uses the existing headless collision-pose optimization. Combat rules stay shared."
 var advanced:=VBoxContainer.new();advanced.visible=false
 var advanced_button:=button(setup,"▸  Evaluation options",func():advanced.visible=not advanced.visible)
 advanced_button.tooltip_text="Optional frozen-model checks between training batches"
 setup.add_child(advanced)
 label(advanced,"Evaluate every N matches",15,Design.MUTED);evaluation=SpinBox.new();evaluation.name="TrainingEvaluationEvery";evaluation.min_value=0;evaluation.max_value=1000000;evaluation.step=1;advanced.add_child(evaluation);evaluation.tooltip_text="0 skips evaluations. Evaluations compare frozen models; training wins alone do not promote a champion."
 label(advanced,"Evaluation pairs",15,Design.MUTED);eval_pairs=SpinBox.new();eval_pairs.name="TrainingEvaluationPairs";eval_pairs.min_value=1;eval_pairs.max_value=100;eval_pairs.step=1;eval_pairs.tooltip_text="Each pair plays twice, swapping sides. Use 10 or more pairs for champion promotion.";advanced.add_child(eval_pairs)
 var note:=label(setup,"Completed matches save automatically. Training continues when you leave this page.",15,Design.MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.custom_minimum_size.x=210
 start_button=button(setup,"▶  Start training",start_training);start_button.name="StartSelfPlay";start_button.add_theme_stylebox_override("normal",Design.box(Design.SELECTED,Design.CYAN))
 pause_button=button(setup,"Pause after match",func():service.toggle_pause());pause_button.name="PauseSelfPlay"
 stop_button=button(setup,"Stop after match",func():service.request_stop());stop_button.name="StopSelfPlay"
 var files:=HBoxContainer.new();setup.add_child(files)
 log_button=button(files,"Open log",func():service.open_log());models_button=button(files,"Models",func():service.open_models())
 var main:=VBoxContainer.new();main.size_flags_horizontal=Control.SIZE_EXPAND_FILL;main.add_theme_constant_override("separation",12);body.add_child(main)
 var overview:=panel(main)
 heading=label(overview,"Ready to train",26,Design.CYAN);heading.name="TrainingPhase"
 detail=label(overview,"Choose a match target and press Start.",16,Design.MUTED);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 completed=label(overview,"0 / 1,000 matches",30);completed.name="TrainingCompleted"
 progress_bar=ProgressBar.new();progress_bar.name="TrainingProgress";progress_bar.show_percentage=false;progress_bar.custom_minimum_size.y=12;overview.add_child(progress_bar)
 round_label=label(overview,"No match running",15,Design.MUTED)
 round_bar=ProgressBar.new();round_bar.show_percentage=false;round_bar.custom_minimum_size.y=5;overview.add_child(round_bar)
 var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);main.add_child(grid)
 for item in [["rate","MATCHES / MIN"],["speed","ACTUAL SPEED"],["eta","REMAINING"],["elapsed","ELAPSED"],["models","TOTAL MODEL MATCHES"],["updates","LEARNING UPDATES"]]:
  var column:=panel(grid);column.get_parent().get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
  label(column,item[1],12,Design.MUTED);metric_labels[item[0]]=label(column,"—",24,Design.CYAN)
 var graph:=panel(main);label(graph,"TRAINING SPEED",15,Design.MUTED);chart=preload("res://scripts/ai/training_speed_chart.gd").new();graph.add_child(chart)
 var outcomes:=panel(main);label(outcomes,"LATEST MATCHES",15,Design.MUTED);recent=label(outcomes,"Completed matches will appear here.",15);recent.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var logs:=panel(main);label(logs,"TRAINER LOG",14,Design.MUTED);log_text=label(logs,"",12,Design.MUTED);log_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;log_text.max_lines_visible=5
func options()->Dictionary:
 return {"matches":int(matches.value),"speed":SPEEDS[speed.selected],"pose_mode":"collision" if mode_choice.selected==1 else "full","eval_every":int(evaluation.value),"eval_pairs":int(eval_pairs.value)}
func restore_options():apply_options(service.preferences())
func apply_options(saved:Dictionary):
 matches.set_value_no_signal(int(saved.get("matches",1000)));speed.select(maxi(0,SPEEDS.find(int(saved.get("speed",8)))));mode_choice.select(1 if saved.get("pose_mode","full")=="collision" else 0);evaluation.set_value_no_signal(int(saved.get("eval_every",100)));eval_pairs.set_value_no_signal(int(saved.get("eval_pairs",10)))
func start_training():
 var settings:=options();service.save_preferences(settings);service.start_job(settings)
static func duration(seconds:float)->String:
 if seconds<0:return "—"
 var total:=int(seconds);return "%dh %02dm"%[total/3600,(total%3600)/60] if total>=3600 else ("%dm %02ds"%[total/60,total%60] if total>=60 else "%ds"%total)
func refresh():
 var state:Dictionary=service.state;var busy:bool=service.running();var phase:=str(state.get("phase","idle"));var count:=int(state.get("completed",0));var target:=int(state.get("target",int(matches.value)))
 var elapsed:=float(state.get("elapsed_seconds",0));var active:=maxf(0.001,float(state.get("active_seconds",elapsed-float(state.get("paused_seconds",0)))));var sim:=float(state.get("simulated_seconds",0))+float(state.get("round_seconds",0))
 if busy:apply_options(service.session.get("options",{}))
 var titles:={"idle":"Ready to train","starting":"Preparing training","training":"Training","evaluating":"Evaluating models","paused":"Paused","completed":"Training complete","stopped":"Stopped safely","error":"Training needs attention"}
 heading.text=titles.get(phase,phase.capitalize());heading.add_theme_color_override("font_color",Color("ff6d7d") if phase=="error" else Design.CYAN)
 detail.text=service.error if not service.error.is_empty() else str(state.get("message","Choose a match target and press Start."))
 if busy and service.stop_requested:detail.text="Stopping after the current match · completed matches will be saved"
 elif busy and service.pause_requested and phase!="paused":detail.text="Pausing after the current match"
 completed.text="%d / %d matches"%[count,target];progress_bar.max_value=maxi(1,target);progress_bar.value=count
 var round_seconds:=float(state.get("round_seconds",0));var round_limit:=float(state.get("round_limit",120));round_bar.max_value=maxf(1,round_limit);round_bar.value=round_seconds
 round_label.text=(("Evaluation %d / %d"%[int(state.get("evaluation_game",0)),int(state.get("evaluation_target",0))]) if phase=="evaluating" else "Current match")+" · %.1f / %.0f s"%[round_seconds,round_limit] if busy and phase in ["training","evaluating"] else ("All completed matches saved" if phase in ["completed","stopped"] else "Waiting for next match")
 var rate:float=count/active*60.0
 metric_labels.rate.text="%.1f"%rate if count>0 else "—"
 metric_labels.speed.text="%.1f×"%(sim/active) if sim>0 else "—"
 metric_labels.speed.tooltip_text="Measured simulation speed · requested %.0f×"%float(state.get("requested_speed",8))
 metric_labels.eta.text="Evaluating" if busy and phase=="evaluating" and count>=target else (duration((target-count)*60.0/rate) if rate>0 and busy else ("Done" if phase=="completed" else "—"))
 metric_labels.elapsed.text=duration(elapsed);metric_labels.models.text=str(int(state.model_matches)) if state.has("model_matches") else "—";metric_labels.updates.text=str(int(state.updates)) if state.has("updates") else "—"
 chart.set_samples(state.get("samples",[]))
 var lines:Array[String]=[]
 var history:Array=state.get("recent",[])
 for match_ in history.slice(maxi(0,history.size()-3)):lines.append("#%d  ·  %s  ·  %.1fs fight / %.1fs real"%[match_.match,"Red won" if match_.winner==0 else ("Blue won" if match_.winner==1 else "Draw"),match_.sim_seconds,match_.wall_seconds])
 recent.text="\n".join(lines) if not lines.is_empty() else "Completed matches will appear here."
 start_button.disabled=busy;pause_button.disabled=not busy or service.stop_requested;stop_button.disabled=not busy or service.stop_requested
 pause_button.text="Resume" if service.pause_requested else "Pause after match"
 log_button.disabled=service.session.is_empty()
 for node in [matches,speed,mode_choice,evaluation,eval_pairs]:
  if node is SpinBox:node.editable=not busy
  else:node.disabled=busy
 log_text.text=service.log_tail()
func _process(delta:float):
 refresh_left-=delta
 if refresh_left<=0:refresh_left=1.0;refresh()
