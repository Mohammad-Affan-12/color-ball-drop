class_name GameplayHud
extends RefCounted

signal layout_changed

## View only: the application supplies level, objective and cut state.
var root: Control
var top_bar: PanelContainer
var bottom_bar: HBoxContainer
var footer: VBoxContainer
var level_label: Label
var title_label: Label
var subtitle_label: Label
var progress_label: Label
var moves_label: Label
var hint_btn: Button
var restart_btn: Button
var pause_btn: Button
var _progress_tween: Tween

func build(ui_layer: CanvasLayer, _home: Callable, on_hint: Callable, on_restart: Callable, on_pause: Callable, _levels: Callable, _quick_level: Callable) -> void:
	root = Control.new()
	root.name = "GameplayHUD"
	root.theme = UiThemeHelper.get_shared_theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	top_bar = PanelContainer.new()
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_theme_stylebox_override("panel", UiThemeHelper.create_hud_bar_style())
	root.add_child(top_bar)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 6)
	top_bar.add_child(content)

	level_label = UiThemeHelper.label("CH 1 · LEVEL 01", 24, UiThemeHelper.TEAL)
	content.add_child(level_label)

	title_label = UiThemeHelper.label("Twin Cascades", 34, UiThemeHelper.TEXT)
	content.add_child(title_label)

	var counters := HBoxContainer.new()
	counters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counters.add_theme_constant_override("separation", 12)
	content.add_child(counters)

	var prog_pill := UiThemeHelper.create_badge_pill("Match colors  0 / 5", UiThemeHelper.TEAL)
	prog_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label = prog_pill.get_node("BadgeLabel") as Label
	counters.add_child(prog_pill)

	var moves_pill := UiThemeHelper.create_badge_pill("3 cuts left", UiThemeHelper.GOLD)
	moves_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moves_label = moves_pill.get_node("BadgeLabel") as Label
	counters.add_child(moves_pill)

	footer = VBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.add_theme_constant_override("separation", 10)
	root.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)

	subtitle_label = UiThemeHelper.label("Swipe gold ropes & beams · Match ball colors", 24, UiThemeHelper.MUTED)
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(subtitle_label)

	bottom_bar = HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 14)
	footer.add_child(bottom_bar)

	pause_btn = UiThemeHelper.action(bottom_bar, "Pause", on_pause)
	restart_btn = UiThemeHelper.action(bottom_bar, "Restart", on_restart)
	hint_btn = UiThemeHelper.action(bottom_bar, "Hint", on_hint, true)
	pause_btn.icon = preload("res://resources/icons/pause.svg")
	restart_btn.icon = preload("res://resources/icons/restart.svg")
	hint_btn.icon = preload("res://resources/icons/hint.svg")
	for button in [pause_btn, restart_btn, hint_btn]:
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)

	footer.resized.connect(func() -> void: layout_changed.emit())
	footer.minimum_size_changed.connect(_fit_footer)
	top_bar.resized.connect(func() -> void: layout_changed.emit())

func layout(insets: Vector4) -> void:
	top_bar.offset_left = insets.x + 24
	top_bar.offset_right = -insets.z - 24
	top_bar.offset_top = insets.y + 12
	top_bar.offset_bottom = insets.y + 178
	footer.offset_left = insets.x + 24
	footer.offset_right = -insets.z - 24
	footer.offset_top = -insets.w - 164
	footer.offset_bottom = -insets.w - 20
	_fit_footer()

func _fit_footer() -> void:
	footer.offset_top = footer.offset_bottom - footer.get_combined_minimum_size().y

func puzzle_area() -> Rect2:
	var top := top_bar.get_global_rect().end.y + 12.0
	var bottom := footer.get_global_rect().position.y - 12.0
	return Rect2(12, top, root.size.x - 24, maxf(bottom - top, 1))

func show_level(index: int, caption: String, daily: bool) -> void:
	var chapter := LevelData.get_chapter_for_level(index)
	var accent := UiThemeHelper.get_chapter_accent(chapter)
	level_label.add_theme_color_override("font_color", UiThemeHelper.GOLD if daily else accent)
	level_label.text = tr("DAILY CHALLENGE · LEVEL %02d") % index if daily else tr("CHAPTER %d · LEVEL %02d") % [chapter, index]
	title_label.text = caption.trim_prefix(tr("Level %d: ") % index)
	subtitle_label.text = tr("Swipe gold ropes & beams · Match ball colors")

func update_moves_display(moves_used: int, par_moves: int) -> void:
	if moves_used > par_moves:
		moves_label.text = "+%d over par" % (moves_used - par_moves)
		moves_label.add_theme_color_override("font_color", UiThemeHelper.CORAL)
	else:
		moves_label.text = tr("%d cuts left") % maxi(par_moves - moves_used, 0)
		moves_label.add_theme_color_override("font_color", UiThemeHelper.GOLD)

func update_progress_display(collected: int, total: int) -> void:
	progress_label.text = tr("Balls  %d / %d") % [collected, total]
	if _progress_tween != null:
		_progress_tween.kill()
	progress_label.modulate = Color.WHITE
	if collected > 0:
		progress_label.modulate = UiThemeHelper.GOLD
		_progress_tween = progress_label.create_tween()
		_progress_tween.tween_property(progress_label, "modulate", Color.WHITE, 0.35)

func set_hint_active(active: bool) -> void:
	hint_btn.text = "Hint on" if active else "Hint"
	hint_btn.modulate = UiThemeHelper.GOLD if active else Color.WHITE
