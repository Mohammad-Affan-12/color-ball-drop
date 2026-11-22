class_name LevelSelectModal
extends RefCounted

var backdrop: ColorRect
var panel: PanelContainer
var chapter_tab_buttons: Array[Button] = []
var grid_container: GridContainer
var summary_label: Label
var chapter_title_label: Label
var chapter_progress_label: Label
var selected_chapter: int = 1
var _on_select_level: Callable
var _on_click_sfx: Callable
var _cached_save: SaveManager
var _cached_current_level: int = 1

func build(ui_layer: CanvasLayer, on_select: Callable, on_click: Callable) -> void:
	_on_select_level = on_select
	_on_click_sfx = on_click
	panel = UiThemeHelper.modal(ui_layer, Vector2(664, 1160))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	content.add_child(UiThemeHelper.label("Choose a Level", 42, UiThemeHelper.TEXT))
	summary_label = UiThemeHelper.label("", 26, UiThemeHelper.GOLD)
	content.add_child(summary_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	content.add_child(tabs)
	for chapter in range(1, 6):
		var button := UiThemeHelper.action(tabs, str(chapter), _select_chapter.bind(chapter))
		button.tooltip_text = "Chapter %d · Levels %d–%d" % [chapter, (chapter - 1) * 20 + 1, chapter * 20]
		chapter_tab_buttons.append(button)

	var chapter_card := PanelContainer.new()
	chapter_card.add_theme_stylebox_override("panel", UiThemeHelper.create_card_style())
	content.add_child(chapter_card)
	var ch_box := VBoxContainer.new()
	ch_box.add_theme_constant_override("separation", 2)
	chapter_card.add_child(ch_box)
	chapter_title_label = UiThemeHelper.label("", 28, UiThemeHelper.TEAL)
	ch_box.add_child(chapter_title_label)
	chapter_progress_label = UiThemeHelper.label("", 22, UiThemeHelper.MUTED)
	ch_box.add_child(chapter_progress_label)

	grid_container = GridContainer.new()
	grid_container.columns = 4
	grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_container.add_theme_constant_override("h_separation", 12)
	grid_container.add_theme_constant_override("v_separation", 12)
	content.add_child(grid_container)

	UiThemeHelper.action(content, "Back to puzzle", _close)

func _close() -> void:
	_on_click_sfx.call()
	backdrop.hide()

func _select_chapter(chapter: int) -> void:
	_on_click_sfx.call()
	selected_chapter = chapter
	_rebuild_current_grid()

func refresh(save: SaveManager, current: int) -> void:
	_cached_save = save
	_cached_current_level = current
	_rebuild_current_grid()

func _rebuild_current_grid() -> void:
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()

	var accent := UiThemeHelper.get_chapter_accent(selected_chapter)
	summary_label.text = "★ %d / 300 stars   ·   %d coins" % [_cached_save.get_total_stars(), _cached_save.coins]
	chapter_title_label.text = LevelData.CHAPTER_NAMES[selected_chapter]
	chapter_title_label.add_theme_color_override("font_color", accent)

	var chapter_stars := 0
	var chapter_cleared := 0
	var start_lvl := (selected_chapter - 1) * 20 + 1
	var end_lvl := selected_chapter * 20
	for lvl in range(start_lvl, end_lvl + 1):
		var st := _cached_save.get_level_stars(lvl)
		chapter_stars += st
		if st > 0:
			chapter_cleared += 1
	chapter_progress_label.text = "%d / 20 cleared   ·   ★ %d / 60" % [chapter_cleared, chapter_stars]

	for i in range(5):
		var ch_accent := UiThemeHelper.get_chapter_accent(i + 1)
		chapter_tab_buttons[i].modulate = ch_accent if i + 1 == selected_chapter else Color("9db2d1")

	for level in range(start_lvl, end_lvl + 1):
		var unlocked := _cached_save.is_level_unlocked(level)
		var stars := _cached_save.get_level_stars(level)
		var caption := "%02d\n%s" % [level, "★".repeat(stars) + "☆".repeat(3 - stars) if unlocked else "🔒"]
		var is_current := level == _cached_current_level
		var bg := Color("1d3a5c") if is_current else (Color("183052") if stars > 0 else UiThemeHelper.SURFACE)
		var border := accent if is_current else (UiThemeHelper.GOLD if stars == 3 else UiThemeHelper.BORDER_BRIGHT)
		var button := UiThemeHelper.create_styled_button(caption, bg, border, 28)
		button.custom_minimum_size = Vector2(118, 110)
		button.disabled = not unlocked
		button.tooltip_text = "Level %d · %d stars" % [level, stars] if unlocked else "Level %d · Locked" % level
		button.pressed.connect(_choose.bind(level))
		grid_container.add_child(button)

func _choose(level: int) -> void:
	_on_click_sfx.call()
	backdrop.hide()
	_on_select_level.call(level)
