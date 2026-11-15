class_name LevelSelectModal
extends RefCounted

## Single-responsibility controller for the 100-Level Chapter Selection Grid modal.

var backdrop: ColorRect
var panel: PanelContainer
var chapter_tab_buttons: Array[Button] = []
var grid_container: GridContainer
var summary_label: Label
var selected_chapter: int = 1
var _on_select_level: Callable
var _on_click_sfx: Callable

func build(ui_layer: CanvasLayer, on_select_level: Callable, on_click_sfx: Callable) -> void:
	_on_select_level = on_select_level
	_on_click_sfx = on_click_sfx

	backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.04, 0.09, 0.90)
	backdrop.size = Vector2(UiThemeHelper.BASE_WIDTH, UiThemeHelper.BASE_HEIGHT)
	backdrop.visible = false
	ui_layer.add_child(backdrop)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(648, 960)
	panel.position = Vector2(36, 120)
	panel.add_theme_stylebox_override("panel", UiThemeHelper.create_modal_style(Color(0.42, 0.80, 1.0, 0.94)))
	backdrop.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "SELECT LEVEL (1–100)"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	vbox.add_child(header)

	summary_label = Label.new()
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.add_theme_font_size_override("font_size", 15)
	summary_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36))
	vbox.add_child(summary_label)

	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 6)
	vbox.add_child(tab_row)

	chapter_tab_buttons.clear()
	for ch in range(1, 6):
		var cbtn := UiThemeHelper.create_styled_button("Ch.%d (%d-%d)" % [ch, (ch - 1) * 20 + 1, ch * 20], Color(0.16, 0.22, 0.36), Color(0.48, 0.72, 1.0))
		cbtn.custom_minimum_size = Vector2(112, 38)
		var ch_idx := ch
		cbtn.pressed.connect(func() -> void:
			_on_click_sfx.call()
			selected_chapter = ch_idx
			_rebuild_current_grid()
		)
		tab_row.add_child(cbtn)
		chapter_tab_buttons.append(cbtn)

	grid_container = GridContainer.new()
	grid_container.columns = 4
	grid_container.add_theme_constant_override("h_separation", 10)
	grid_container.add_theme_constant_override("v_separation", 10)
	grid_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid_container)

	var close_btn := UiThemeHelper.create_styled_button("Close ✕", Color(0.22, 0.26, 0.38), Color(0.68, 0.80, 0.98))
	close_btn.custom_minimum_size = Vector2(240, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		_on_click_sfx.call()
		backdrop.visible = false
	)
	vbox.add_child(close_btn)

var _cached_save: SaveManager = null
var _cached_current_level: int = 1

func refresh(save_manager: SaveManager, current_level_index: int) -> void:
	_cached_save = save_manager
	_cached_current_level = current_level_index
	_rebuild_current_grid()

func _rebuild_current_grid() -> void:
	if grid_container == null:
		return
	for child in grid_container.get_children():
		child.queue_free()

	var total_stars: int = _cached_save.get_total_stars() if _cached_save != null else 0
	var highest: int = _cached_save.highest_unlocked_level if _cached_save != null else 1
	summary_label.text = "Chapter %d  •  Total Stars: ★ %d / 300  •  Highest Unlocked: Level %d" % [
		selected_chapter, total_stars, highest
	]

	for i in range(chapter_tab_buttons.size()):
		var btn := chapter_tab_buttons[i]
		btn.modulate = Color(1.0, 0.94, 0.45) if (i + 1) == selected_chapter else Color(0.80, 0.86, 0.96)

	var start_lvl: int = (selected_chapter - 1) * 20 + 1
	var end_lvl: int = mini(start_lvl + 19, LevelData.TOTAL_LEVELS)
	for lvl in range(start_lvl, end_lvl + 1):
		var unlocked: bool = true if _cached_save == null else _cached_save.is_level_unlocked(lvl)
		var stars: int = 0 if _cached_save == null else _cached_save.get_level_stars(lvl)
		var star_txt: String = "🔒"
		if unlocked:
			star_txt = "★★★" if stars == 3 else ("★★☆" if stars == 2 else ("★☆☆" if stars == 1 else "☆☆☆"))
		var bg := Color(0.16, 0.28, 0.44) if unlocked else Color(0.11, 0.13, 0.20)
		var border := Color(0.45, 0.82, 1.0) if unlocked else Color(0.28, 0.32, 0.44)
		if lvl == _cached_current_level:
			bg = Color(0.22, 0.42, 0.28)
			border = Color(0.45, 1.0, 0.65)
		var cell_btn := UiThemeHelper.create_styled_button("Lvl %d\n%s" % [lvl, star_txt], bg, border)
		cell_btn.custom_minimum_size = Vector2(136, 110)
		cell_btn.disabled = not unlocked
		var target_lvl: int = lvl
		cell_btn.pressed.connect(func() -> void:
			_on_click_sfx.call()
			backdrop.visible = false
			_on_select_level.call(target_lvl)
		)
		grid_container.add_child(cell_btn)
