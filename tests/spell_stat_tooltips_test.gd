extends SceneTree
const Tips=preload("res://scripts/spell_stat_tooltips.gd")
const Rules=Tips.Rules
func _initialize() -> void:call_deferred("run")
func run() -> void:
	# Exercise the real shared calculation over duration, release, allocation and movement.
	for element in ["None","Fire"]:
		for duration in [0.1,0.5,1.0,9.9,10.0,16.0,60.0]:
			for fraction in [0.05,0.3,0.55]:
				for power in [0.0,0.5,1.0]:
					var base:=Rules.allocate(Rules.projectile_base(element),{"size":0.2,"speed":0.6,"effect":0.2},element,power)
					var stats:=Rules.authored_stats(base,duration,fraction,true,Vector3(3,7,4))
					var tips:=Tips.breakdown(base,duration,fraction,true,stats)
					assert(tips.damage.contains("= %.1f"%float(stats.physical_damage)))
					assert(tips.mana.contains("= %.1f mana"%float(stats.mana)))
					assert(tips.stamina.contains("= %.1f stamina"%float(Rules.physical(duration,true).stamina)))
					assert(tips.speed.contains("= %.1f m/s"%float(stats.velocity)))
					assert(tips.size.contains("= %.2f m"%(float(stats.radius)*2.0)))
					assert(tips.burn.contains("= %.1f damage/s"%float(stats.burn_dps)))
					assert(tips.amp.contains("+%.1f%%"%((float(stats.amplifier)-1)*100)))
	change_scene_to_file("res://scenes/combat_sandbox.tscn")
	var editor:Node
	while true:
		await process_frame
		editor=current_scene
		if editor!=null and bool(editor.get("default_unit_ready")) and not is_instance_valid(editor.get("loading_layer")):break
	editor.select_group("Spells")
	var b=editor.spell_builder
	b.draft_path="user://logs/stat_tooltips_draft.cfg"
	b.preview_preferences_path="user://logs/stat_tooltips_prefs.cfg"
	b.open_projectile_workspace()
	b.preview_projectile_effect("Fire")
	b.hide()
	b.set_demo_duration(1.0)
	b.set_release_fraction(0.3)
	b.refresh_demo_timing()
	for label in [b.demo_stamina_label,b.demo_damage_label,b.demo_mana_cost_label,b.demo_amplifier_label,b.demo_size_bonus_label,b.demo_speed_bonus_label,b.demo_burn_label,b.demo_ragdoll_label]:
		if label.has_meta("stat_hover_box"):
			var box=label.get_meta("stat_hover_box")
			assert(label.mouse_filter==Control.MOUSE_FILTER_IGNORE)
			assert(box.mouse_filter==Control.MOUSE_FILTER_STOP)
			assert(box._get_tooltip(Vector2(1,1))==label.tooltip_text)
			box.mouse_entered.emit()
			assert(box.get_theme_stylebox("panel")==box.highlighted)
			box.mouse_exited.emit()
			assert(box.get_theme_stylebox("panel")==box.resting)
		else:assert(label.mouse_filter==Control.MOUSE_FILTER_PASS)
		assert(label.tooltip_text.length()>60)
	assert(b.demo_damage_label.tooltip_text.contains("Default benchmark"))
	assert(b.demo_mana_cost_label.tooltip_text.contains("10.0 projectile + 10.0 effect = 20.0"))
	b.set_limiter_enabled(false)
	b.set_test_value("damage",123.0)
	assert(b.demo_damage_label.tooltip_text.contains("independent testing value"))
	assert(not b.demo_size_bonus_label.tooltip_text.contains("spell amp"))
	assert(b.demo_damage_label.get_meta("stat_hover_box").visible==b.demo_damage_label.visible)
	print("SPELL STAT TOOLTIPS PASS: 126 live formula combinations, actual Create hover targets and limiter-off explanations")
	quit()
