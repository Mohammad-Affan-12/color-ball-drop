class_name UiThemeHelper
extends RefCounted

const BASE_WIDTH := 720.0
const BASE_HEIGHT := 1280.0
const INK := Color("101e32")
const SURFACE := Color("172b42")
const TEXT := Color("eef6ff")
const MUTED := Color("adbed1")
const TEAL := Color("72e7cd")
const GOLD := Color("ffd482")
const THEME_PATH := "res://resources/ui_theme.tres"
static var _cached_theme: Theme

static func get_shared_theme() -> Theme:
	if _cached_theme == null:
		_cached_theme = load(THEME_PATH)
	return _cached_theme

static func create_modal_style(_border: Color = TEAL) -> StyleBoxFlat:
	var style := create_pill_style(INK, Color("344960"))
	style.set_corner_radius_all(32)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 20
	return style

static func create_hud_bar_style() -> StyleBoxFlat:
	return create_pill_style(INK, Color("2b4058"))

static func create_pill_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func create_styled_button(caption: String, bg: Color = SURFACE, border: Color = Color("405974"), font_size: int = 30) -> Button:
	var button := Button.new()
	button.theme = get_shared_theme()
	button.text = caption
	button.custom_minimum_size = Vector2(96, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", maxi(font_size, 28))
	var normal := create_pill_style(bg, border)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.16)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("142237")
	disabled.border_color = Color("2a3c52")
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = TEAL
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	return button

static func label(caption: String, font_size: int = 30, color: Color = TEXT) -> Label:
	var result := Label.new()
	result.text = caption
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func modal(ui_layer: CanvasLayer, preferred: Vector2) -> PanelContainer:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.045, 0.08, 0.96)
	backdrop.theme = get_shared_theme()
	ui_layer.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.hide()
	var panel := PanelContainer.new()
	panel.set_meta("preferred_size", preferred)
	panel.add_theme_stylebox_override("panel", create_modal_style())
	backdrop.add_child(panel)
	return panel

static func modal_content(panel: PanelContainer) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	scroll.add_child(content)
	return content

static func action(parent: Container, caption: String, callback: Callable, primary: bool = false) -> Button:
	var result := create_styled_button(caption, Color("23584f") if primary else SURFACE, TEAL if primary else Color("405974"))
	result.pressed.connect(callback)
	parent.add_child(result)
	return result
