class_name GameplayHud
extends RefCounted

## Single-responsibility controller for the top gameplay HUD bar.

var top_bar: PanelContainer
var title_label: Label
var subtitle_label: Label
var progress_label: Label
var moves_label: Label
var coins_label: Label
var stars_hud_label: Label
var hint_btn: Button
var restart_btn: Button
var pause_btn: Button
var levels_btn: Button
var home_btn: Button
var level_buttons: Array[Button] = []

func build(
	ui_layer: CanvasLayer,
	on_home: Callable,
	on_hint: Callable,
	on_restart: Callable,
	on_pause: Callable,
	on_levels: Callable,
	on_quick_level: Callable
) -> void:
	top_bar = PanelContainer.new()
	top_bar.position = Vector2(12, 12)
	top_bar.custom_minimum_size = Vector2(696, 110)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.08, 0.11, 0.19, 0.94)
	top_style.border_color = Color(0.28, 0.48, 0.78, 0.72)
	top_style.set_border_width_all(2)
	top_style.set_corner_radius_all(14)
	top_style.content_margin_left = 12
	top_style.content_margin_right = 12
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_bar.add_theme_stylebox_override("panel", top_style)
	ui_layer.add_child(top_bar)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	top_bar.add_child(vbox)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	vbox.add_child(row1)

	home_btn = UiThemeHelper.create_styled_button("⌂", Color(0.16, 0.22, 0.36), Color(0.50, 0.74, 1.0))
	home_btn.custom_minimum_size = Vector2(36, 34)
	home_btn.pressed.connect(on_home)
	row1.add_child(home_btn)

	title_label = Label.new()
	title_label.text = "Level 1"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	row1.add_child(title_label)

	progress_label = Label.new()
	progress_label.text = "Balls: 0/0"
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0))
	row1.add_child(progress_label)

	moves_label = Label.new()
	moves_label.text = "Cuts: 0/1"
	moves_label.add_theme_font_size_override("font_size", 14)
	moves_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.42))
	row1.add_child(moves_label)

	hint_btn = UiThemeHelper.create_styled_button("Hint", Color(0.28, 0.24, 0.10), Color(1.0, 0.85, 0.28))
	hint_btn.custom_minimum_size = Vector2(58, 34)
	hint_btn.pressed.connect(on_hint)
	row1.add_child(hint_btn)

	restart_btn = UiThemeHelper.create_styled_button("↻", Color(0.18, 0.26, 0.42), Color(0.55, 0.82, 1.0))
	restart_btn.custom_minimum_size = Vector2(40, 34)
	restart_btn.pressed.connect(on_restart)
	row1.add_child(restart_btn)

	pause_btn = UiThemeHelper.create_styled_button("⏸", Color(0.20, 0.22, 0.34), Color(0.68, 0.76, 0.95))
	pause_btn.custom_minimum_size = Vector2(40, 34)
	pause_btn.pressed.connect(on_pause)
	row1.add_child(pause_btn)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	vbox.add_child(row2)

	subtitle_label = Label.new()
	subtitle_label.text = "Swipe across supports to drop balls!"
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", Color(0.74, 0.82, 0.94))
	subtitle_label.clip_text = true
	row2.add_child(subtitle_label)

	coins_label = Label.new()
	coins_label.text = "💰 0"
	coins_label.add_theme_font_size_override("font_size", 13)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28))
	row2.add_child(coins_label)

	stars_hud_label = Label.new()
	stars_hud_label.text = "★ 0"
	stars_hud_label.add_theme_font_size_override("font_size", 13)
	stars_hud_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.38))
	row2.add_child(stars_hud_label)

	level_buttons.clear()
	for i in range(1, 6):
		var lbtn := UiThemeHelper.create_styled_button(str(i), Color(0.14, 0.18, 0.28), Color(0.45, 0.60, 0.85))
		lbtn.custom_minimum_size = Vector2(30, 26)
		var lvl_idx := i
		lbtn.pressed.connect(func() -> void: on_quick_level.call(lvl_idx))
		row2.add_child(lbtn)
		level_buttons.append(lbtn)

	levels_btn = UiThemeHelper.create_styled_button("Levels (100)", Color(0.16, 0.30, 0.46), Color(0.48, 0.86, 1.0))
	levels_btn.custom_minimum_size = Vector2(96, 26)
	levels_btn.pressed.connect(on_levels)
	row2.add_child(levels_btn)

func refresh_counters(save_manager: SaveManager, current_level: LevelController) -> void:
	if save_manager != null:
		coins_label.text = "💰 %d" % save_manager.coins
		stars_hud_label.text = "★ %d" % save_manager.get_total_stars()
	if current_level != null and is_instance_valid(current_level):
		moves_label.text = "Cuts: %d/%d" % [current_level.moves_used, current_level.par_moves]

func update_quick_level_buttons(save_manager: SaveManager, current_level_index: int) -> void:
	for i in range(level_buttons.size()):
		var btn := level_buttons[i]
		var lvl_num := i + 1
		var unlocked := true if save_manager == null else save_manager.is_level_unlocked(lvl_num)
		var stars := 0 if save_manager == null else save_manager.get_level_stars(lvl_num)
		var active := lvl_num == current_level_index
		btn.text = "%d%s" % [lvl_num, "★" if stars > 0 else ""]
		if active:
			btn.modulate = Color(1.0, 0.95, 0.45)
		elif unlocked:
			btn.modulate = Color(0.84, 0.90, 1.0)
		else:
			btn.modulate = Color(0.45, 0.50, 0.62)
