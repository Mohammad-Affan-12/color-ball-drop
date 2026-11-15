class_name SaveManager
extends RefCounted

const DEFAULT_SAVE_PATH := "user://cut_and_cascade_save.cfg"
const SAVE_VERSION := 2

var save_path: String = DEFAULT_SAVE_PATH
var highest_unlocked_level: int = 1
var level_stars: Dictionary = {}
var level_best_moves: Dictionary = {}
var coins: int = 0
var owned_cosmetics: Array = ["classic_slash"]
var equipped_cosmetic: String = "classic_slash"
var claimed_star_milestones: Array = []
var tutorial_completed: bool = false
var remove_ads_owned: bool = false

var sfx_muted: bool = false
var sfx_volume_percent: int = 100
var music_muted: bool = false
var music_volume_percent: int = 75
var vibration_enabled: bool = true
var colorblind_assist: bool = true
var particle_quality_low: bool = OS.get_name() == "Android"
var privacy_consent_granted: bool = false # Legacy field; never authorizes SDK collection.
var privacy_prompt_seen: bool = false
var analytics_opt_in: bool = false
var locale_override: String = ""

var daily_completed_dates: Array = []
var daily_streak: int = 0
var stats: Dictionary = {
	"levels_played": 0,
	"levels_won": 0,
	"levels_failed": 0,
	"total_valid_cuts": 0,
	"total_balls_collected": 0
}

func _init(custom_path: String = DEFAULT_SAVE_PATH) -> void:
	save_path = custom_path
	load_data()

func _compute_checksum(unlocked: int, stars_dict: Dictionary, coin_val: int) -> String:
	var raw := "v%d|u:%d|c:%d|s:%s" % [SAVE_VERSION, unlocked, coin_val, JSON.stringify(stars_dict)]
	return raw.sha256_text().substr(0, 16)

func load_data() -> bool:
	if _try_load_from_file(save_path):
		return true
	var bak_path := save_path + ".bak"
	if FileAccess.file_exists(bak_path) and _try_load_from_file(bak_path):
		save_data()
		return true
	reset_to_defaults(false)
	return false

func _try_load_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	if err != OK:
		return false
	if not cfg.has_section("progress"):
		return false

	var u_lvl := int(cfg.get_value("progress", "highest_unlocked_level", 1))
	var s_dict: Variant = cfg.get_value("progress", "level_stars", {})
	var c_val := int(cfg.get_value("progress", "coins", 0))
	if not (s_dict is Dictionary) or u_lvl < 1 or c_val < 0:
		return false

	var stored_hash := String(cfg.get_value("meta", "checksum", ""))
	if not stored_hash.is_empty():
		var expected_hash := _compute_checksum(u_lvl, s_dict as Dictionary, c_val)
		if stored_hash != expected_hash:
			return false

	highest_unlocked_level = clampi(u_lvl, 1, LevelData.TOTAL_LEVELS)
	level_stars = (s_dict as Dictionary).duplicate()
	var bm_var: Variant = cfg.get_value("progress", "level_best_moves", {})
	level_best_moves = (bm_var as Dictionary).duplicate() if bm_var is Dictionary else {}
	coins = maxi(c_val, 0)

	var owned_var: Variant = cfg.get_value("progress", "owned_cosmetics", ["classic_slash"])
	owned_cosmetics = (owned_var as Array).duplicate() if owned_var is Array else ["classic_slash"]
	if not owned_cosmetics.has("classic_slash"):
		owned_cosmetics.push_front("classic_slash")

	equipped_cosmetic = String(cfg.get_value("progress", "equipped_cosmetic", "classic_slash"))
	if not owned_cosmetics.has(equipped_cosmetic):
		equipped_cosmetic = "classic_slash"

	var ms_var: Variant = cfg.get_value("progress", "claimed_star_milestones", [])
	claimed_star_milestones = (ms_var as Array).duplicate() if ms_var is Array else []
	tutorial_completed = bool(cfg.get_value("progress", "tutorial_completed", false))
	remove_ads_owned = bool(cfg.get_value("progress", "remove_ads_owned", false))

	sfx_muted = bool(cfg.get_value("audio", "sfx_muted", false))
	sfx_volume_percent = clampi(int(cfg.get_value("audio", "sfx_volume_percent", 100)), 0, 100)
	music_muted = bool(cfg.get_value("audio", "music_muted", false))
	music_volume_percent = clampi(int(cfg.get_value("audio", "music_volume_percent", 75)), 0, 100)
	vibration_enabled = bool(cfg.get_value("settings", "vibration_enabled", true))
	colorblind_assist = bool(cfg.get_value("settings", "colorblind_assist", true))
	particle_quality_low = bool(cfg.get_value("settings", "particle_quality_low", OS.get_name() == "Android"))
	privacy_consent_granted = bool(cfg.get_value("settings", "privacy_consent_granted", false))
	privacy_prompt_seen = bool(cfg.get_value("settings", "privacy_prompt_seen", false))
	analytics_opt_in = bool(cfg.get_value("settings", "analytics_opt_in", false))
	locale_override = str(cfg.get_value("settings", "locale_override", ""))

	var daily_var: Variant = cfg.get_value("daily", "completed_dates", [])
	daily_completed_dates = (daily_var as Array).duplicate() if daily_var is Array else []
	daily_streak = maxi(int(cfg.get_value("daily", "streak", 0)), 0)

	var st_var: Variant = cfg.get_value("stats", "data", stats)
	if st_var is Dictionary:
		for k in stats.keys():
			if (st_var as Dictionary).has(k):
				stats[k] = int((st_var as Dictionary)[k])
	return true

func save_data() -> Error:
	var cfg := ConfigFile.new()
	var checksum := _compute_checksum(highest_unlocked_level, level_stars, coins)
	cfg.set_value("meta", "version", SAVE_VERSION)
	cfg.set_value("meta", "checksum", checksum)

	cfg.set_value("progress", "highest_unlocked_level", highest_unlocked_level)
	cfg.set_value("progress", "level_stars", level_stars)
	cfg.set_value("progress", "level_best_moves", level_best_moves)
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "owned_cosmetics", owned_cosmetics)
	cfg.set_value("progress", "equipped_cosmetic", equipped_cosmetic)
	cfg.set_value("progress", "claimed_star_milestones", claimed_star_milestones)
	cfg.set_value("progress", "tutorial_completed", tutorial_completed)
	cfg.set_value("progress", "remove_ads_owned", remove_ads_owned)

	cfg.set_value("audio", "sfx_muted", sfx_muted)
	cfg.set_value("audio", "sfx_volume_percent", sfx_volume_percent)
	cfg.set_value("audio", "music_muted", music_muted)
	cfg.set_value("audio", "music_volume_percent", music_volume_percent)
	cfg.set_value("settings", "vibration_enabled", vibration_enabled)
	cfg.set_value("settings", "colorblind_assist", colorblind_assist)
	cfg.set_value("settings", "particle_quality_low", particle_quality_low)
	cfg.set_value("settings", "privacy_consent_granted", privacy_consent_granted)
	cfg.set_value("settings", "privacy_prompt_seen", privacy_prompt_seen)
	cfg.set_value("settings", "analytics_opt_in", analytics_opt_in)
	cfg.set_value("settings", "locale_override", locale_override)

	cfg.set_value("daily", "completed_dates", daily_completed_dates)
	cfg.set_value("daily", "streak", daily_streak)
	cfg.set_value("stats", "data", stats)

	# Keep a backup copy before overwriting primary save file
	if FileAccess.file_exists(save_path):
		var existing_bytes := FileAccess.get_file_as_bytes(save_path)
		if existing_bytes.size() > 0:
			var bak_file := FileAccess.open(save_path + ".bak", FileAccess.WRITE)
			if bak_file != null:
				bak_file.store_buffer(existing_bytes)
				bak_file.close()

	return cfg.save(save_path)

func reset_to_defaults(write_to_disk: bool = true) -> void:
	highest_unlocked_level = 1
	level_stars = {}
	level_best_moves = {}
	coins = 0
	owned_cosmetics = ["classic_slash"]
	equipped_cosmetic = "classic_slash"
	claimed_star_milestones = []
	tutorial_completed = false
	remove_ads_owned = false
	sfx_muted = false
	sfx_volume_percent = 100
	music_muted = false
	music_volume_percent = 75
	vibration_enabled = true
	colorblind_assist = true
	particle_quality_low = OS.get_name() == "Android"
	daily_completed_dates = []
	daily_streak = 0
	stats = {
		"levels_played": 0,
		"levels_won": 0,
		"levels_failed": 0,
		"total_valid_cuts": 0,
		"total_balls_collected": 0
	}
	if write_to_disk:
		save_data()

func is_level_unlocked(level_idx: int) -> bool:
	return level_idx >= 1 and level_idx <= highest_unlocked_level

func get_total_stars() -> int:
	var sum := 0
	for k in level_stars.keys():
		sum += clampi(int(level_stars[k]), 0, 3)
	return sum

func record_level_win(level_idx: int, stars: int, moves: int) -> int:
	var clamped_stars := clampi(stars, 1, 3)
	var prev_stars := int(level_stars.get(level_idx, 0))
	var is_first_clear := prev_stars == 0

	if level_idx >= highest_unlocked_level and level_idx < LevelData.TOTAL_LEVELS:
		highest_unlocked_level = level_idx + 1
	if level_idx == 1:
		tutorial_completed = true

	if clamped_stars > prev_stars:
		level_stars[level_idx] = clamped_stars

	var prev_moves := int(level_best_moves.get(level_idx, 9999))
	if moves > 0 and moves < prev_moves:
		level_best_moves[level_idx] = moves

	# Calculate coin reward: +25 on first clear (+10 on replay), +15 bonus per newly earned 3rd star
	var earned_coins := 25 if is_first_clear else 10
	if clamped_stars == 3 and prev_stars < 3:
		earned_coins += 15
	coins += earned_coins
	stats["levels_won"] = int(stats.get("levels_won", 0)) + 1

	# Auto-unlock any Star Chest milestone cosmetics reached
	_check_star_milestone_unlocks()
	save_data()
	return earned_coins

func _check_star_milestone_unlocks() -> Array[String]:
	var newly_unlocked: Array[String] = []
	var total_s := get_total_stars()
	for trail in CosmeticsCatalog.get_all_trails():
		var ms: int = int(trail.get("star_milestone", 0))
		var tid: String = String(trail["id"])
		if ms > 0 and total_s >= ms and not owned_cosmetics.has(tid):
			owned_cosmetics.append(tid)
			if not claimed_star_milestones.has(ms):
				claimed_star_milestones.append(ms)
			newly_unlocked.append(tid)
	return newly_unlocked

func unlock_cosmetic_with_coins(trail_id: String) -> bool:
	if owned_cosmetics.has(trail_id):
		return true
	var def := CosmeticsCatalog.get_trail_def(trail_id)
	var cost := int(def.get("coin_cost", 9999))
	if coins < cost:
		return false
	coins -= cost
	owned_cosmetics.append(trail_id)
	equipped_cosmetic = trail_id
	save_data()
	return true

func equip_cosmetic(trail_id: String) -> bool:
	if not owned_cosmetics.has(trail_id):
		return false
	equipped_cosmetic = trail_id
	save_data()
	return true

func record_daily_challenge_win(date_str: String) -> int:
	if daily_completed_dates.has(date_str):
		coins += 15
		save_data()
		return 15
	daily_completed_dates.append(date_str)
	var today_unix := int(Time.get_unix_time_from_datetime_string(date_str + "T00:00:00"))
	var yesterday := Time.get_date_string_from_unix_time(today_unix - 86400)
	daily_streak = daily_streak + 1 if daily_completed_dates.has(yesterday) else 1
	var reward := 75
	coins += reward
	save_data()
	return reward

func is_daily_completed(date_str: String) -> bool:
	return daily_completed_dates.has(date_str)

func get_level_stars(level_idx: int) -> int:
	return int(level_stars.get(level_idx, 0))

func get_level_best_moves(level_idx: int) -> int:
	return int(level_best_moves.get(level_idx, 0))
