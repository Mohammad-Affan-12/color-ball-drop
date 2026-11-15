class_name UiThemeHelper
extends RefCounted

## Shared factory for StyleBoxFlat panels and themed mobile buttons.

const BASE_WIDTH: float = 720.0
const BASE_HEIGHT: float = 1280.0

static func create_modal_style(border_col: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.13, 0.22, 0.98)
	style.border_color = border_col
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style

static func create_styled_button(text_str: String, bg_col: Color, border_col: Color) -> Button:
	var btn := Button.new()
	btn.text = text_str
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_col
	normal.border_color = border_col
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg_col.lightened(0.16)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg_col.darkened(0.18)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.10, 0.12, 0.18, 0.65)
	disabled.border_color = Color(0.28, 0.32, 0.42, 0.5)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.48, 0.52, 0.62))
	return btn
