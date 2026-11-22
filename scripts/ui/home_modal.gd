class_name HomeModal
extends RefCounted

class HomeHeroArt extends Control:
	var _t: float = 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 146)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 10.0 or h <= 10.0:
			return
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("0c1930")
		bg.border_color = Color("294775")
		bg.set_border_width_all(2)
		bg.set_corner_radius_all(22)
		draw_style_box(bg, Rect2(Vector2.ZERO, size))

		var cx := w * 0.5
		var colors := [
			GameColors.ColorType.RED,
			GameColors.ColorType.BLUE,
			GameColors.ColorType.YELLOW,
			GameColors.ColorType.GREEN
		]
		var spacing := minf(w * 0.2, 110.0)
		var start_x := cx - spacing * 1.5

		# Draw 4 hanging glossy balls on gold ropes
		for i in range(4):
			var bx := start_x + float(i) * spacing
			var bob := sin(_t * 2.2 + float(i) * 1.1) * 5.0
			var by := h * 0.62 + bob
			var anchor := Vector2(bx, 14.0)
			# Gold rope
			draw_line(anchor, Vector2(bx, by - 18.0), Color("8c572b"), 5.5, true)
			draw_line(anchor, Vector2(bx, by - 18.0), Color("f0be73"), 3.2, true)
			draw_circle(anchor, 5.0, Color("72e7cd"))
			# Glossy ball
			var main := GameColors.get_main_color(colors[i])
			var light := GameColors.get_light_color(colors[i])
			var dark := GameColors.get_dark_color(colors[i])
			var r := 22.0
			draw_circle(Vector2(bx, by + 3.0), r + 2.0, Color(0, 0, 0, 0.30))
			draw_circle(Vector2(bx, by), r + 3.5, Color(light.r, light.g, light.b, 0.16))
			draw_circle(Vector2(bx, by), r, dark.lerp(main, 0.65))
			draw_circle(Vector2(bx - 2.0, by - 2.0), r * 0.78, main)
			draw_circle(Vector2(bx - 5.0, by - 6.0), r * 0.32, Color(light.r, light.g, light.b, 0.72))
			draw_circle(Vector2(bx - 7.0, by - 8.0), r * 0.16, Color(1, 1, 1, 0.90))
			GameColors.draw_color_emblem(self, Vector2(bx, by + 1.0), r * 0.85, colors[i], Color(dark.darkened(0.2), 0.85))

		# Sweeping glowing slash arc across the ropes
		var slash_y := h * 0.33
		var p1 := Vector2(w * 0.12, slash_y + 12.0)
		var p2 := Vector2(w * 0.88, slash_y - 12.0)
		var pulse := 0.55 + 0.35 * sin(_t * 3.0)
		draw_line(p1, p2, Color(0.26, 0.93, 0.78, pulse * 0.30), 10.0, true)
		draw_line(p1, p2, Color(0.88, 1.0, 0.96, pulse * 0.85), 3.0, true)

var backdrop: ColorRect
var panel: PanelContainer
var stats_label: Label
var currency_label: Label
var play_btn: Button
var daily_btn: Button
var remove_ads_btn: Button
var back_btn: Button
var _launch_mode := false

func build(ui_layer: CanvasLayer, on_play: Callable, on_levels: Callable, on_daily: Callable, on_cosmetics: Callable, on_settings: Callable, on_purchase: Callable, on_close: Callable) -> void:
	panel = UiThemeHelper.modal(ui_layer, Vector2(650, 1140))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 4)
	content.add_child(title_box)
	title_box.add_child(UiThemeHelper.label("COLOR BALL DROP", 48, UiThemeHelper.TEAL))
	title_box.add_child(UiThemeHelper.label("Cut ropes · Drop balls · Match every color", 24, UiThemeHelper.MUTED))

	var hero := HomeHeroArt.new()
	content.add_child(hero)

	var wallet := PanelContainer.new()
	wallet.add_theme_stylebox_override("panel", UiThemeHelper.create_card_style())
	content.add_child(wallet)
	var wallet_box := VBoxContainer.new()
	wallet_box.add_theme_constant_override("separation", 4)
	wallet.add_child(wallet_box)
	currency_label = UiThemeHelper.label("", 28, UiThemeHelper.GOLD)
	wallet_box.add_child(currency_label)
	stats_label = UiThemeHelper.label("", 24, UiThemeHelper.MUTED)
	wallet_box.add_child(stats_label)

	play_btn = UiThemeHelper.create_styled_button("PLAY · LEVEL 1", Color("167a64"), UiThemeHelper.TEAL, 34)
	play_btn.custom_minimum_size = Vector2(96, 108)
	play_btn.pressed.connect(_navigate.bind(on_play))
	content.add_child(play_btn)

	# 2x2 secondary grid avoids a monotonous vertical stack of identical buttons
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	content.add_child(grid)

	UiThemeHelper.action(grid, "Levels", _navigate.bind(on_levels))
	daily_btn = UiThemeHelper.action(grid, "Daily", _navigate.bind(on_daily))
	UiThemeHelper.action(grid, "Blade Trails", _navigate.bind(on_cosmetics))
	UiThemeHelper.action(grid, "Settings", _navigate.bind(on_settings))

	remove_ads_btn = UiThemeHelper.action(content, "Remove Ads", on_purchase)
	remove_ads_btn.hide() # No purchase offer until real verified billing exists.

	back_btn = UiThemeHelper.action(content, "Back to puzzle", _navigate.bind(on_close))

## On app launch there is no puzzle in progress yet, so "Back to puzzle" is hidden
## and the primary button reads "PLAY".
func set_launch_mode(is_launch: bool) -> void:
	_launch_mode = is_launch
	back_btn.visible = not is_launch

func _navigate(callback: Callable) -> void:
	backdrop.hide()
	callback.call()

func refresh(save: SaveManager) -> void:
	currency_label.text = tr("%d coins   ·   ★ %d / 300") % [save.coins, save.get_total_stars()]
	stats_label.text = tr("Level %d / 100 unlocked · %d day streak") % [save.highest_unlocked_level, save.daily_streak]
	if _launch_mode:
		play_btn.text = tr("PLAY · LEVEL %d") % save.highest_unlocked_level
	else:
		play_btn.text = tr("CONTINUE · LEVEL %d") % save.highest_unlocked_level
	daily_btn.text = tr("Daily ✓") if save.is_daily_completed(DailyChallenge.get_today_date_string()) else tr("Daily +75")
	remove_ads_btn.hide()
