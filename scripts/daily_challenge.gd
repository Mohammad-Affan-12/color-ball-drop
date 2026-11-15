class_name DailyChallenge
extends RefCounted

## Offline-compatible deterministic Daily Cascade Challenge selector.
## Note: Uses local device system date so it works 100% offline without an account.
## Local device clocks can be modified by users and are not treated as cheat-resistant for online leaderboards.

static func get_today_date_string() -> String:
	var dt := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(dt.get("year", 2026)), int(dt.get("month", 1)), int(dt.get("day", 1))]

static func get_level_index_for_date(date_str: String) -> int:
	var h := date_str.hash()
	if h < 0:
		h = -h
	# Pick deterministically from the 100-level campaign pool
	return (h % LevelData.TOTAL_LEVELS) + 1
