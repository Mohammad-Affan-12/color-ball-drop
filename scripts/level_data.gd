class_name LevelData
extends RefCounted

const TOTAL_LEVELS := 100

const CHAPTER_NAMES := {
	1: "Chapter 1: The First Cut",
	2: "Chapter 2: Color Control",
	3: "Chapter 3: Physics Workshop",
	4: "Chapter 4: Cascade Factory",
	5: "Chapter 5: Cascade Master"
}

const COLOR_PERMS := [
	[GameColors.ColorType.RED, GameColors.ColorType.BLUE, GameColors.ColorType.YELLOW, GameColors.ColorType.GREEN],
	[GameColors.ColorType.GREEN, GameColors.ColorType.YELLOW, GameColors.ColorType.RED, GameColors.ColorType.BLUE],
	[GameColors.ColorType.BLUE, GameColors.ColorType.RED, GameColors.ColorType.GREEN, GameColors.ColorType.YELLOW],
	[GameColors.ColorType.YELLOW, GameColors.ColorType.GREEN, GameColors.ColorType.BLUE, GameColors.ColorType.RED],
	[GameColors.ColorType.RED, GameColors.ColorType.GREEN, GameColors.ColorType.BLUE, GameColors.ColorType.YELLOW],
	[GameColors.ColorType.BLUE, GameColors.ColorType.YELLOW, GameColors.ColorType.RED, GameColors.ColorType.GREEN],
	[GameColors.ColorType.GREEN, GameColors.ColorType.BLUE, GameColors.ColorType.YELLOW, GameColors.ColorType.RED],
	[GameColors.ColorType.YELLOW, GameColors.ColorType.RED, GameColors.ColorType.GREEN, GameColors.ColorType.BLUE]
]

const LEVEL_TITLES := [
	"Twin Cascades", "Triple Streams", "Chain Reaction", "Four-Color Spectrum", "Grand Cascade",
	"Look Before You Cut", "Decoy Support", "Pendulum Swing", "Order of Operations", "Double Relay",
	"Pinball Bounce", "Zig-Zag Ricochet", "Bridge Lock", "Twin Decoys", "Ricochet Relay",
	"Split Second", "Four-Way Cross", "The Gauntlet", "Precision Strike", "First Cut Finale",
	"Laser Filter", "Selective Entry", "Twin Gates", "Spectrum Barrier", "Gate & Trigger",
	"Filtered Ricochet", "Three-Gate Sort", "Guard the Chute", "Crossed Filters", "Gatekeeper Boss",
	"Color Alchemy", "Double Dye", "Chameleon Drop", "Prism Cascade", "Dye & Filter",
	"Rainbow Transform", "Trick Dye Trap", "Fourfold Alchemy", "Chain & Dye", "Color Control Finale",
	"Tipping Point", "Twin Seesaws", "Balance Beam", "Tilt & Sort", "Seesaw Relay",
	"Weighted Drop", "Alternating Chutes", "Seesaw Spectrum", "Dynamic Fulcrum", "Balance Boss",
	"Armored Chains", "Chain Lockout", "Retract the Barrier", "Steel & Silk", "Padlock Puzzle",
	"Dual Chain Locks", "Bumper & Chain", "Seesaw Lock", "Chain Reaction Master", "Workshop Finale",
	"Dimensional Hop", "Twin Portals", "Cross-Screen Warp", "Portal & Dye", "Warp Trigger",
	"Four-Way Warp", "Portal Ricochet", "Filtered Teleport", "Chain Warp", "Portal Boss",
	"Moving Paddles", "Rotary Mill", "Oscillating Chute", "Factory Rhythm", "Piston & Portal",
	"Dye Conveyor", "Kinetic Gears", "Shifting Gates", "Synchronized Factory", "Cascade Factory Finale",
	"Mastery I: Alchemy Warp", "Mastery II: Armored Sort", "Mastery III: Seesaw Warp", "Mastery IV: Prism Lock", "Mastery V: Quad Relay",
	"Mastery VI: Pinball Alchemy", "Mastery VII: Twin Locks", "Mastery VIII: Spectrum Mill", "Mastery IX: Portal Filter", "Mastery X: Grand Relay",
	"Mastery XI: Decoy Warp", "Mastery XII: Chromatic Vault", "Mastery XIII: Kinetic Maze", "Mastery XIV: Triple Trigger", "Mastery XV: Laser Labyrinth",
	"Mastery XVI: Starlight Cascade", "Mastery XVII: Supernova Sort", "Mastery XVIII: Quantum Chutes", "Mastery XIX: Ultimate Contraption", "Mastery XX: Grand Finale"
]

static func get_chapter_for_level(level_num: int) -> int:
	return clampi(((level_num - 1) / 20) + 1, 1, 5)

static func get_level_title(level_num: int) -> String:
	var idx := clampi(level_num, 1, TOTAL_LEVELS) - 1
	return "Level %d: %s" % [level_num, LEVEL_TITLES[idx]]

static func get_perm(level_num: int) -> Array:
	return COLOR_PERMS[(level_num * 3 + (level_num / 5)) % COLOR_PERMS.size()]

static func populate_level(lc: LevelController, level_num: int) -> void:
	var lvl := clampi(level_num, 1, TOTAL_LEVELS)
	lc.chapter_number = get_chapter_for_level(lvl)
	lc.level_title = get_level_title(lvl)
	var perm := get_perm(lvl)

	if lvl <= 20:
		Chapter1Levels.build(lc, lvl, perm)
	elif lvl <= 40:
		Chapter2Levels.build(lc, lvl, perm)
	elif lvl <= 60:
		Chapter3Levels.build(lc, lvl, perm)
	elif lvl <= 80:
		Chapter4Levels.build(lc, lvl, perm)
	else:
		Chapter5Levels.build(lc, lvl, perm)
