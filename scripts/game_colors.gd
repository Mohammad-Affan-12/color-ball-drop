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

static func get_main_color(c_type: int) -> Color:
	return COLOR_MAP.get(c_type, Color.WHITE)

static func get_dark_color(c_type: int) -> Color:
	return DARK_MAP.get(c_type, Color.DIM_GRAY)

static func get_light_color(c_type: int) -> Color:
	return LIGHT_MAP.get(c_type, Color.WHITE)

static func get_color_name(c_type: int) -> String:
	return NAME_MAP.get(c_type, "UNKNOWN")
