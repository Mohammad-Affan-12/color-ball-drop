class_name ResultsModal
extends RefCounted

## Single-responsibility controller for the Win/Fail results modal and startup splash overlay.

var backdrop: ColorRect
var panel: PanelContainer
var header_label: Label
var stars_label: Label
var body_label: Label
var reward_label: Label
var next_btn: Button
var retry_btn: Button
var bonus_btn: Button
var levels_btn: Button
var splash_backdrop: ColorRect

func build(
	ui_layer: CanvasLayer,
	on_retry: Callable,
	on_next: Callable,
	on_bonus_ad: Callable,
	on_open_levels: Callable
) -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.04, 0.08, 0.76)
	backdrop.size = Vector2(UiThemeHelper.BASE_WIDTH, UiThemeHelper.BASE_HEIGHT)
	backdrop.visible = false
	ui_layer.add_child(backdrop)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 390)
	panel.position = Vector2(80, 390)
	panel.pivot_offset = Vector2(280, 195)
	panel.add_theme_stylebox_override("panel", UiThemeHelper.create_modal_style(Color(0.38, 0.78, 1.0, 0.92)))
	backdrop.add_child(panel)

	var modal_vbox := VBoxContainer.new()
	modal_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(modal_vbox)

	header_label = Label.new()
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 30)
	modal_vbox.add_child(header_label)

	stars_label = Label.new()
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_font_size_override("font_size", 34)
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	modal_vbox.add_child(stars_label)

	body_label = Label.new()
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.add_theme_color_override("font_color", Color(0.84, 0.90, 0.98))
	modal_vbox.add_child(body_label)

	reward_label = Label.new()
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 17)
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.34))
	modal_vbox.add_child(reward_label)

	var btn_row1 := HBoxContainer.new()
	btn_row1.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row1.add_theme_constant_override("separation", 14)
	modal_vbox.add_child(btn_row1)

	retry_btn = UiThemeHelper.create_styled_button("Retry Level ↻", Color(0.22, 0.28, 0.42), Color(0.7, 0.85, 1.0))
	retry_btn.custom_minimum_size = Vector2(155, 46)
	retry_btn.pressed.connect(on_retry)
	btn_row1.add_child(retry_btn)

	next_btn = UiThemeHelper.create_styled_button("Next Level ▶", Color(0.12, 0.46, 0.26), Color(0.4, 1.0, 0.62))
	next_btn.custom_minimum_size = Vector2(175, 46)
	next_btn.pressed.connect(on_next)
	btn_row1.add_child(next_btn)

	var btn_row2 := HBoxContainer.new()
	btn_row2.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row2.add_theme_constant_override("separation", 14)
	modal_vbox.add_child(btn_row2)

	bonus_btn = UiThemeHelper.create_styled_button("+25 Bonus Coins (Ad)", Color(0.36, 0.26, 0.08), Color(1.0, 0.84, 0.28))
	bonus_btn.custom_minimum_size = Vector2(190, 40)
	bonus_btn.pressed.connect(on_bonus_ad)
	btn_row2.add_child(bonus_btn)

	levels_btn = UiThemeHelper.create_styled_button("Level Select", Color(0.16, 0.24, 0.38), Color(0.55, 0.78, 1.0))
	levels_btn.custom_minimum_size = Vector2(140, 40)
	levels_btn.pressed.connect(func() -> void:
		backdrop.visible = false
		on_open_levels.call()
	)
	btn_row2.add_child(levels_btn)

	_build_splash(ui_layer)

func _build_splash(ui_layer: CanvasLayer) -> void:
	splash_backdrop = ColorRect.new()
	splash_backdrop.color = Color(0.05, 0.08, 0.15, 1.0)
	splash_backdrop.size = Vector2(UiThemeHelper.BASE_WIDTH, UiThemeHelper.BASE_HEIGHT)
	splash_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash_backdrop.visible = false
	ui_layer.add_child(splash_backdrop)

	var splash_lbl := Label.new()
	splash_lbl.text = "CUT & CASCADE\nCOLOR PUZZLE"
	splash_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	splash_lbl.size = Vector2(UiThemeHelper.BASE_WIDTH, UiThemeHelper.BASE_HEIGHT)
	splash_lbl.add_theme_font_size_override("font_size", 38)
	splash_lbl.add_theme_color_override("font_color", Color(0.45, 0.94, 1.0))
	splash_backdrop.add_child(splash_lbl)

func show_win(host: Node, lvl_idx: int, earned_stars: int, coins_awarded: int, moves_taken: int) -> void:
	backdrop.visible = true
	panel.scale = Vector2(0.75, 0.75)
	var tw := host.create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.26)

	var star_str := ""
	for s in range(1, 4):
		star_str += "★ " if s <= earned_stars else "☆ "
	stars_label.text = star_str.strip_edges()
	stars_label.visible = true
	reward_label.text = "+%d Coins Earned! (Moves: %d)" % [coins_awarded, moves_taken]
	reward_label.visible = true
	bonus_btn.visible = true
	bonus_btn.disabled = false
	bonus_btn.text = "+25 Bonus Coins (Ad)"

	if lvl_idx < LevelData.TOTAL_LEVELS:
		header_label.text = "LEVEL COMPLETE!"
		header_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
		body_label.text = "All colored balls cascaded into their matching containers!"
		next_btn.text = "Next Level ▶"
		next_btn.visible = true
	else:
		header_label.text = "ALL 100 LEVELS CLEARED!"
		header_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28))
		body_label.text = "Congratulations! You mastered all %d levels of Cut & Cascade!" % LevelData.TOTAL_LEVELS
		next_btn.text = "Play From Level 1"
		next_btn.visible = true

func show_fail(host: Node, reason: String) -> void:
	backdrop.visible = true
	panel.scale = Vector2(0.75, 0.75)
	var tw := host.create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.26)

	header_label.text = "LEVEL FAILED"
	header_label.add_theme_color_override("font_color", Color(1.0, 0.36, 0.38))
	stars_label.visible = false
	body_label.text = reason
	reward_label.text = "Tip: Tap Hint to highlight recommended cut positions."
	reward_label.visible = true
	next_btn.visible = false
	bonus_btn.visible = false
