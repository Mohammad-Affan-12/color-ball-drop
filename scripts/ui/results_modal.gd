class_name ResultsModal
extends RefCounted

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

func build(ui_layer: CanvasLayer, on_retry: Callable, on_next: Callable, on_bonus: Callable, on_levels: Callable) -> void:
	panel = UiThemeHelper.modal(ui_layer, Vector2(620, 900))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	header_label = UiThemeHelper.label("", 42, UiThemeHelper.TEAL)
	content.add_child(header_label)
	stars_label = UiThemeHelper.label("", 72, UiThemeHelper.GOLD)
	content.add_child(stars_label)
	body_label = UiThemeHelper.label("", 30, UiThemeHelper.MUTED)
	content.add_child(body_label)
	reward_label = UiThemeHelper.label("", 28, UiThemeHelper.GOLD)
	content.add_child(reward_label)
	next_btn = UiThemeHelper.action(content, "Next level", on_next, true)
	retry_btn = UiThemeHelper.action(content, "Try again", on_retry)
	bonus_btn = UiThemeHelper.action(content, "+25 coins · Watch ad", on_bonus)
	levels_btn = UiThemeHelper.action(content, "Choose a level", func() -> void:
		backdrop.hide()
		on_levels.call()
	)
	splash_backdrop = ColorRect.new()
	splash_backdrop.color = UiThemeHelper.INK
	splash_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(splash_backdrop)
	splash_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_backdrop.hide()
	var title := UiThemeHelper.label("CUT &\nCASCADE", 64, UiThemeHelper.TEAL)
	splash_backdrop.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _animate(host: Node) -> void:
	panel.modulate.a = 0.0
	host.create_tween().tween_property(panel, "modulate:a", 1.0, 0.2)

func show_win(host: Node, level: int, stars: int, coins: int, moves: int, _save: SaveManager = null) -> void:
	backdrop.show()
	_animate(host)
	header_label.text = "LEVEL COMPLETE!" if level < LevelData.TOTAL_LEVELS else "100 LEVELS CLEARED!"
	header_label.add_theme_color_override("font_color", UiThemeHelper.TEAL)
	stars_label.text = "★ ".repeat(stars) + "☆ ".repeat(3 - stars)
	stars_label.show()
	body_label.text = tr("Every color found its home.\n%d cuts · Nicely done.") % moves
	reward_label.text = tr("+%d coins earned") % coins
	reward_label.show()
	next_btn.text = "Next level" if level < LevelData.TOTAL_LEVELS else "Play from level 1"
	next_btn.show()
	bonus_btn.show()
	bonus_btn.disabled = false
	bonus_btn.text = "+25 coins · Watch ad"

func show_fail(host: Node, reason: String) -> void:
	backdrop.show()
	_animate(host)
	header_label.text = "LEVEL FAILED"
	header_label.add_theme_color_override("font_color", Color("ff949e"))
	stars_label.hide()
	body_label.text = reason
	reward_label.text = "Try Hint to see the recommended cut order."
	reward_label.show()
	next_btn.hide()
	bonus_btn.hide()
