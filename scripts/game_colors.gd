class_name GameColors
extends RefCounted

enum ColorType {
	RED = 0,
	BLUE = 1,
	YELLOW = 2,
	GREEN = 3,
	STEEL = 4
}

const COLOR_MAP := {
	ColorType.RED: Color(1.0, 0.27, 0.36),
	ColorType.BLUE: Color(0.18, 0.62, 1.0),
	ColorType.YELLOW: Color(1.0, 0.82, 0.16),
	ColorType.GREEN: Color(0.20, 0.88, 0.48),
	ColorType.STEEL: Color(0.62, 0.68, 0.78)
}

const DARK_MAP := {
	ColorType.RED: Color(0.62, 0.10, 0.18),
	ColorType.BLUE: Color(0.07, 0.30, 0.62),
	ColorType.YELLOW: Color(0.68, 0.48, 0.04),
	ColorType.GREEN: Color(0.08, 0.48, 0.24),
	ColorType.STEEL: Color(0.32, 0.36, 0.44)
}

const LIGHT_MAP := {
	ColorType.RED: Color(1.0, 0.68, 0.72),
	ColorType.BLUE: Color(0.66, 0.86, 1.0),
	ColorType.YELLOW: Color(1.0, 0.95, 0.68),
	ColorType.GREEN: Color(0.68, 0.98, 0.80),
	ColorType.STEEL: Color(0.86, 0.90, 0.96)
}

const NAME_MAP := {
	ColorType.RED: "RED",
	ColorType.BLUE: "BLUE",
	ColorType.YELLOW: "YELLOW",
	ColorType.GREEN: "GREEN",
	ColorType.STEEL: "STEEL"
}

const SYMBOL_MAP := {
	ColorType.RED: "●",
	ColorType.BLUE: "◆",
	ColorType.YELLOW: "★",
	ColorType.GREEN: "▲",
	ColorType.STEEL: "⚙"
}

static func get_main_color(c_type: int) -> Color:
	return COLOR_MAP.get(c_type, Color.WHITE)

static func get_dark_color(c_type: int) -> Color:
	return DARK_MAP.get(c_type, Color.DIM_GRAY)

static func get_light_color(c_type: int) -> Color:
	return LIGHT_MAP.get(c_type, Color.WHITE)

static func get_color_name(c_type: int) -> String:
	return NAME_MAP.get(c_type, "UNKNOWN")

static func get_color_symbol(c_type: int) -> String:
	return SYMBOL_MAP.get(c_type, "●")

static func get_collision_bit(c_type: int) -> int:
	# Bit 1 (value 1) is WorldStatic.
	# Bits 2..6 (values 2, 4, 8, 16, 32) correspond to RED, BLUE, YELLOW, GREEN, STEEL.
	return 1 << (clampi(c_type, 0, 4) + 1)

static func draw_color_emblem(canvas: CanvasItem, center: Vector2, r: float, c_type: int, col: Color) -> void:
	match c_type:
		ColorType.RED:
			# Twin concentric arcs + center dot
			canvas.draw_arc(center, r * 0.45, 0.25, PI - 0.25, 10, col, 2.2, true)
			canvas.draw_arc(center, r * 0.45, PI + 0.25, TAU - 0.25, 10, col, 2.2, true)
			canvas.draw_circle(center, r * 0.16, col)
		ColorType.BLUE:
			# Rotated diamond outline
			var d := r * 0.48
			var pts := PackedVector2Array([
				center + Vector2(0, -d),
				center + Vector2(d, 0),
				center + Vector2(0, d),
				center + Vector2(-d, 0),
				center + Vector2(0, -d)
			])
			canvas.draw_polyline(pts, col, 2.2, true)
		ColorType.YELLOW:
			# 4-point star cross
			var s := r * 0.48
			canvas.draw_line(center + Vector2(-s, 0), center + Vector2(s, 0), col, 2.4, true)
			canvas.draw_line(center + Vector2(0, -s), center + Vector2(0, s), col, 2.4, true)
			var d := s * 0.62
			canvas.draw_line(center + Vector2(-d, -d), center + Vector2(d, d), col, 1.8, true)
			canvas.draw_line(center + Vector2(-d, d), center + Vector2(d, -d), col, 1.8, true)
		ColorType.GREEN:
			# Equilateral triangle outline
			var t := r * 0.48
			var pts := PackedVector2Array([
				center + Vector2(0, -t),
				center + Vector2(t * 0.88, t * 0.65),
				center + Vector2(-t * 0.88, t * 0.65),
				center + Vector2(0, -t)
			])
			canvas.draw_polyline(pts, col, 2.2, true)
		ColorType.STEEL:
			for a in range(4):
				var ang := float(a) * PI * 0.5
				var p := center + Vector2.from_angle(ang) * (r * 0.55)
				canvas.draw_circle(p, 3.0, col)
			canvas.draw_arc(center, r * 0.45, 0.0, TAU, 18, col, 2.0, true)
