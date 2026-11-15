class_name SaveManager
extends RefCounted

const DEFAULT_SAVE_PATH := "user://cut_and_cascade_save.cfg"

var save_path: String = DEFAULT_SAVE_PATH
var highest_unlocked_level: int = 1
var level_stars: Dictionary = {}
var level_best_moves: Dictionary = {}
var tutorial_completed: bool = false
var sfx_muted: bool = false
var sfx_volume_percent: int = 100
var vibration_enabled: bool = true

func _init(custom_path: String = DEFAULT_SAVE_PATH) -> void:
	save_path = custom_path
	load_data()

func load_data() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(save_path)
	if err != OK:
		reset_to_defaults(false)
		return

	highest_unlocked_level = clampi(int(cfg.get_value("progress", "highest_unlocked_level", 1)), 1, LevelData.TOTAL_LEVELS)
	tutorial_completed = bool(cfg.get_value("progress", "tutorial_completed", false))
	level_stars = cfg.get_value("progress", "level_stars", {}) as Dictionary
	level_best_moves = cfg.get_value("progress", "level_best_moves", {}) as Dictionary

	sfx_muted = bool(cfg.get_value("audio", "sfx_muted", false))
	sfx_volume_percent = clampi(int(cfg.get_value("audio", "sfx_volume_percent", 100)), 0, 100)
	vibration_enabled = bool(cfg.get_value("settings", "vibration_enabled", true))

func save_data() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "highest_unlocked_level", highest_unlocked_level)
	cfg.set_value("progress", "tutorial_completed", tutorial_completed)
	cfg.set_value("progress", "level_stars", level_stars)
	cfg.set_value("progress", "level_best_moves", level_best_moves)

	cfg.set_value("audio", "sfx_muted", sfx_muted)
	cfg.set_value("audio", "sfx_volume_percent", sfx_volume_percent)
	cfg.set_value("settings", "vibration_enabled", vibration_enabled)
	return cfg.save(save_path)

func reset_to_defaults(write_to_disk: bool = true) -> void:
	highest_unlocked_level = 1
	level_stars = {}
	level_best_moves = {}
	tutorial_completed = false
	sfx_muted = false
	sfx_volume_percent = 100
	vibration_enabled = true
	if write_to_disk:
		save_data()

func is_level_unlocked(level_idx: int) -> bool:
	return level_idx >= 1 and level_idx <= highest_unlocked_level

func record_level_win(level_idx: int, stars: int, moves: int) -> void:
	if level_idx >= highest_unlocked_level and level_idx < LevelData.TOTAL_LEVELS:
		highest_unlocked_level = level_idx + 1
	if level_idx == 1:
		tutorial_completed = true

	var prev_stars: int = int(level_stars.get(level_idx, 0))
	if stars > prev_stars:
		level_stars[level_idx] = stars

	var prev_moves: int = int(level_best_moves.get(level_idx, 9999))
	if moves > 0 and moves < prev_moves:
		level_best_moves[level_idx] = moves

	save_data()

func get_level_stars(level_idx: int) -> int:
	return int(level_stars.get(level_idx, 0))

func get_level_best_moves(level_idx: int) -> int:
	return int(level_best_moves.get(level_idx, 0))
