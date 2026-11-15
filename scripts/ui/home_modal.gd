class_name HomeModal
extends RefCounted

## Single-responsibility controller for the Home Menu screen modal.

var backdrop: ColorRect
var panel: PanelContainer
var stats_label: Label
var play_btn: Button
var daily_btn: Button
var remove_ads_btn: Button

func build(
	ui_layer: CanvasLayer,
	on_play_continue: Callable,
	on_open_levels: Callable,
	on_start_daily: Callable,
	on_open_cosmetics: Callable,
	on_open_settings: Callable,
	on_purchase_remove_ads: Callable,
	on_close: Callable
) -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color(0.03, 0.05, 0.11, 0.90)
	backdrop.size = Vector2(UiThemeHelper.BASE_WIDTH, UiThemeHelper.BASE_HEIGHT)
	backdrop.visible = false
	ui_layer.add_child(backdrop)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 760)
	panel.position = Vector2(70, 210)
	panel.add_theme_stylebox_override("panel", UiThemeHelper.create_modal_style(Color(0.36, 0.82, 1.0, 0.95)))
	backdrop.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "CUT & CASCADE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.42, 0.94, 1.0))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "COLOR PUZZLE — 100 LEVELS"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36))
	vbox.add_child(sub)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0))
	vbox.add_child(stats_label)

	play_btn = UiThemeHelper.create_styled_button("Play / Continue ▶", Color(0.12, 0.48, 0.26), Color(0.42, 1.0, 0.64))
	play_btn.custom_minimum_size = Vector2(360, 54)
	play_btn.pressed.connect(func() -> void:
		backdrop.visible = false
		on_play_continue.call()
	)
	vbox.add_child(play_btn)

	var levels_btn := UiThemeHelper.create_styled_button("Select Level (Chapters 1–5)", Color(0.16, 0.30, 0.48), Color(0.52, 0.84, 1.0))
	levels_btn.custom_minimum_size = Vector2(360, 48)
	levels_btn.pressed.connect(func() -> void:
		backdrop.visible = false
		on_open_levels.call()
	)
	vbox.add_child(levels_btn)

	daily_btn = UiThemeHelper.create_styled_button("Daily Cascade Challenge 📅", Color(0.32, 0.24, 0.10), Color(1.0, 0.84, 0.28))
	daily_btn.custom_minimum_size = Vector2(360, 48)
	daily_btn.pressed.connect(func() -> void:
		backdrop.visible = false
		on_start_daily.call()
	)
	vbox.add_child(daily_btn)

	var cosmetics_btn := UiThemeHelper.create_styled_button("Blade Trails & Star Chests ✨", Color(0.26, 0.16, 0.42), Color(0.84, 0.56, 1.0))
	cosmetics_btn.custom_minimum_size = Vector2(360, 48)
	cosmetics_btn.pressed.connect(func() -> void:
		backdrop.visible = false
		on_open_cosmetics.call()
	)
	vbox.add_child(cosmetics_btn)

	var settings_btn := UiThemeHelper.create_styled_button("Settings, Accessibility & Privacy ⚙", Color(0.18, 0.24, 0.36), Color(0.64, 0.78, 0.96))
	settings_btn.custom_minimum_size = Vector2(360, 46)
	settings_btn.pressed.connect(func() -> void:
		backdrop.visible = false
		on_open_settings.call()
	)
	vbox.add_child(settings_btn)

	remove_ads_btn = UiThemeHelper.create_styled_button("Remove Ads ($2.99)", Color(0.34, 0.16, 0.24), Color(1.0, 0.54, 0.72))
	remove_ads_btn.custom_minimum_size = Vector2(360, 44)
	remove_ads_btn.pressed.connect(on_purchase_remove_ads)
	vbox.add_child(remove_ads_btn)

	var close_btn := UiThemeHelper.create_styled_button("Resume Current Level", Color(0.14, 0.18, 0.28), Color(0.48, 0.62, 0.84))
	close_btn.custom_minimum_size = Vector2(360, 42)
	close_btn.pressed.connect(func() -> void:
		backdrop.visible = false
		on_close.call()
	)
	vbox.add_child(close_btn)

func refresh(save_manager: SaveManager) -> void:
	if save_manager == null:
		return
	var highest: int = save_manager.highest_unlocked_level
	var stars: int = save_manager.get_total_stars()
	var coins: int = save_manager.coins
	var streak: int = save_manager.daily_streak
	stats_label.text = "Unlocked: %d/%d  •  Stars: ★ %d/300  •  Coins: 💰 %d  •  Daily Streak: 🔥 %d" % [
		highest, LevelData.TOTAL_LEVELS, stars, coins, streak
	]
	play_btn.text = "Play / Continue (Level %d) ▶" % highest
	var today_str: String = DailyChallenge.get_today_date_string()
	var daily_lvl: int = DailyChallenge.get_level_index_for_date(today_str)
	var daily_done: bool = save_manager.is_daily_completed(today_str)
	daily_btn.text = "Daily Challenge: Lvl %d %s" % [daily_lvl, "(✓ Done)" if daily_done else "(+75 💰)"]
	remove_ads_btn.visible = not save_manager.remove_ads_owned
