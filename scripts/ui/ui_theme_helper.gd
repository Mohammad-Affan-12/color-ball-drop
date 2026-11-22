class_name UiThemeHelper
extends RefCounted

const BASE_WIDTH := 720.0
const BASE_HEIGHT := 1280.0

# Commercial Midnight-Indigo Casual Puzzle Palette
const BG_DEEP := Color("091224")
const INK := Color("0f1d36")
const SURFACE := Color("192d4f")
const SURFACE_ALT := Color("213860")
const BORDER_SUBTLE := Color("2f4b78")
const BORDER_BRIGHT := Color("496da3")
const TEXT := Color("f3f8ff")
const MUTED := Color("a8bdd9")
const TEAL := Color("42ecc8")
const TEAL_DARK := Color("165c52")
const GOLD := Color("ffd466")
const CORAL := Color("ff627d")
const BLUE := Color("43a8ff")
const VIOLET := Color("a478ff")

const CHAPTER_ACCENTS := {
	1: Color("42ecc8"),
	2: Color("ff627d"),
	3: Color("ffd466"),
	4: Color("43a8ff"),
	5: Color("b482ff")
}

const THEME_PATH := "res://resources/ui_theme.tres"
static var _cached_theme: Theme

static func get_shared_theme() -> Theme:
	if _cached_theme == null:
		_cached_theme = load(THEME_PATH)
	return _cached_theme

static func get_chapter_accent(chapter: int) -> Color:
	return CHAPTER_ACCENTS.get(clampi(chapter, 1, 5), TEAL)

static func create_modal_style(accent: Color = BORDER_BRIGHT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INK
	style.border_color = accent
	style.set_border_width_all(2)
	style.border_width_bottom = 6
	style.set_corner_radius_all(34)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 24
	return style

static func create_hud_bar_style(accent: Color = BORDER_SUBTLE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("11223e")
	style.border_color = accent
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.set_corner_radius_all(24)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 10
	return style

static func create_card_style(bg: Color = Color("142645"), border: Color = BORDER_SUBTLE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.set_corner_radius_all(22)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

static func create_pill_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.border_width_bottom = 5
	style.set_corner_radius_all(22)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func create_styled_button(caption: String, bg: Color = SURFACE, border: Color = BORDER_BRIGHT, font_size: int = 30) -> Button:
	var button := Button.new()
	button.theme = get_shared_theme()
	button.text = caption
	button.custom_minimum_size = Vector2(96, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", maxi(font_size, 28))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("d8ecff"))
	button.add_theme_color_override("font_disabled_color", Color("6f86a8"))

	var normal := create_pill_style(bg, border)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	normal.shadow_size = 6

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.09)
	hover.border_color = border.lightened(0.14)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.14)
	pressed.border_width_bottom = 2
	pressed.content_margin_top = 14
	pressed.content_margin_bottom = 10

	var disabled := create_pill_style(Color("121f36"), Color("253959"))
	disabled.border_width_bottom = 2

	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = TEAL
	focus.set_border_width_all(3)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	return button

static func create_badge_pill(text_str: String, color: Color = GOLD, bg: Color = Color("132544")) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(color.r, color.g, color.b, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	pill.add_theme_stylebox_override("panel", style)
	var lbl := label(text_str, 24, color)
	lbl.name = "BadgeLabel"
	pill.add_child(lbl)
	return pill

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
	backdrop.color = Color(0.02, 0.04, 0.09, 0.94)
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
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	return content

static func action(parent: Container, caption: String, callback: Callable, primary: bool = false) -> Button:
	var bg := Color("1a6d5e") if primary else SURFACE
	var border := TEAL if primary else BORDER_BRIGHT
	var result := create_styled_button(caption, bg, border)
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

static func danger_action(parent: Container, caption: String, callback: Callable) -> Button:
	var result := create_styled_button(caption, Color("4a1f31"), CORAL)
	result.pressed.connect(callback)
	parent.add_child(result)
	return result
