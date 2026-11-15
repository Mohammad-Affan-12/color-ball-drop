class_name CosmeticsCatalog
extends RefCounted

const TRAILS := [
	{
		"id": "classic_slash",
		"name": "Classic Slash",
		"desc": "Crisp cyan & white energy blade.",
		"coin_cost": 0,
		"star_milestone": 0,
		"outer_color": Color(0.22, 0.86, 1.0, 0.50),
		"core_color": Color(0.92, 0.98, 1.0, 0.96),
		"hot_outer": Color(1.0, 0.78, 0.22, 0.58),
		"hot_core": Color(1.0, 0.98, 0.82, 0.98),
		"spark_color": Color(0.75, 0.96, 1.0)
	},
	{
		"id": "neon_blue",
		"name": "Neon Blue",
		"desc": "Deep Cobalt plasma arc.",
		"coin_cost": 120,
		"star_milestone": 10,
		"outer_color": Color(0.10, 0.45, 1.0, 0.62),
		"core_color": Color(0.65, 0.92, 1.0, 0.98),
		"hot_outer": Color(0.25, 0.75, 1.0, 0.72),
		"hot_core": Color(0.90, 0.98, 1.0, 1.0),
		"spark_color": Color(0.35, 0.78, 1.0)
	},
	{
		"id": "golden_spark",
		"name": "Golden Spark",
		"desc": "Radiant solar gold ribbon.",
		"coin_cost": 200,
		"star_milestone": 25,
		"outer_color": Color(1.0, 0.72, 0.12, 0.60),
		"core_color": Color(1.0, 0.96, 0.68, 0.98),
		"hot_outer": Color(1.0, 0.52, 0.10, 0.70),
		"hot_core": Color(1.0, 1.0, 0.88, 1.0),
		"spark_color": Color(1.0, 0.86, 0.28)
	},
	{
		"id": "rainbow_trail",
		"name": "Rainbow Trail",
		"desc": "Prismatic spectrum wave.",
		"coin_cost": 300,
		"star_milestone": 45,
		"outer_color": Color(0.95, 0.35, 0.85, 0.58),
		"core_color": Color(0.98, 0.98, 1.0, 0.96),
		"hot_outer": Color(0.35, 1.0, 0.65, 0.68),
		"hot_core": Color(1.0, 0.98, 0.85, 1.0),
		"spark_color": Color(1.0, 0.55, 0.92),
		"is_rainbow": true
	},
	{
		"id": "electric_trail",
		"name": "Electric Trail",
		"desc": "High-voltage emerald-cyan surge.",
		"coin_cost": 400,
		"star_milestone": 70,
		"outer_color": Color(0.12, 0.96, 0.68, 0.60),
		"core_color": Color(0.84, 1.0, 0.95, 0.98),
		"hot_outer": Color(0.25, 1.0, 0.45, 0.70),
		"hot_core": Color(1.0, 1.0, 0.92, 1.0),
		"spark_color": Color(0.28, 1.0, 0.75)
	},
	{
		"id": "crystal_trail",
		"name": "Crystal Trail",
		"desc": "Diamond-violet refractive beam.",
		"coin_cost": 500,
		"star_milestone": 100,
		"outer_color": Color(0.68, 0.42, 1.0, 0.60),
		"core_color": Color(0.94, 0.88, 1.0, 0.98),
		"hot_outer": Color(0.86, 0.48, 1.0, 0.70),
		"hot_core": Color(1.0, 0.96, 1.0, 1.0),
		"spark_color": Color(0.82, 0.65, 1.0)
	},
	{
		"id": "fire_trail",
		"name": "Fire Trail",
		"desc": "Blazing crimson-orange comet.",
		"coin_cost": 650,
		"star_milestone": 140,
		"outer_color": Color(1.0, 0.26, 0.14, 0.64),
		"core_color": Color(1.0, 0.86, 0.38, 0.98),
		"hot_outer": Color(1.0, 0.15, 0.25, 0.75),
		"hot_core": Color(1.0, 0.96, 0.75, 1.0),
		"spark_color": Color(1.0, 0.44, 0.18)
	},
	{
		"id": "cosmic_trail",
		"name": "Cosmic Trail",
		"desc": "Starlight nebula supernova slash.",
		"coin_cost": 800,
		"star_milestone": 190,
		"outer_color": Color(0.45, 0.18, 0.95, 0.66),
		"core_color": Color(0.48, 0.96, 1.0, 0.98),
		"hot_outer": Color(0.95, 0.22, 0.78, 0.75),
		"hot_core": Color(1.0, 0.98, 1.0, 1.0),
		"spark_color": Color(0.62, 0.88, 1.0)
	}
]

static func get_trail_def(trail_id: String) -> Dictionary:
	for item in TRAILS:
		if item["id"] == trail_id:
			return item
	return TRAILS[0]

static func get_all_trails() -> Array:
	return TRAILS
