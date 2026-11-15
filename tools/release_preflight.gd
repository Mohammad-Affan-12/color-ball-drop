extends SceneTree

var errors: Array[String] = []
var development := false

func _init() -> void:
	development = OS.get_cmdline_user_args().has("--development")
	call_deferred("_run")

func require(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _run() -> void:
	var presets := ConfigFile.new()
	require(presets.load("res://export_presets.cfg") == OK, "Export presets missing")
	for index in [0, 1]:
		var section := "preset.%d.options" % index
		require(bool(presets.get_value(section, "gradle_build/use_gradle_build", false)), "Both Android presets must use Gradle for the native SDK")
		require(int(presets.get_value(section, "gradle_build/target_sdk", "0")) >= 36, "Target SDK must be at least API 36; recheck current Play policy before submission")
		require(bool(presets.get_value(section, "permissions/internet", false)), "Missing internet permission for optional services")
		require(bool(presets.get_value(section, "architectures/arm64-v8a", false)), "64-bit ARM required")
	for variant in ["debug", "release"]:
		for name in ["ads", "core"]:
			require(FileAccess.file_exists("res://addons/admob/android/bin/ads/libs/poing-godot-admob-%s-%s.aar" % [name, variant]), "Missing pinned %s %s native AAR" % [name, variant])
	if not development:
		require(not bool(ProjectSettings.get_setting("release/ads/test_mode", true)), "Ads are intentionally in test mode")
		require(bool(ProjectSettings.get_setting("release/ads/audience_reviewed", false)), "Owner must review target audience, age handling and ad consent messages")
		require(str(ProjectSettings.get_setting("release/privacy_policy_url", "")).begins_with("https://"), "Public completed privacy-policy URL required")
		var app_id := str(ProjectSettings.get_setting("admob/general/android/app_id", "ca-app-pub-3940256099942544~3347511713"))
		require(app_id.contains("~") and not app_id.contains("3940256099942544"), "Owner AdMob app ID required")
		for kind in ["rewarded", "interstitial"]:
			var unit := str(ProjectSettings.get_setting("release/ads/%s_unit" % kind, ""))
			require(unit.begins_with("ca-app-pub-") and unit.contains("/") and not unit.contains("3940256099942544"), "Owner %s ad unit ID required" % kind)
		var key_path := OS.get_environment("GODOT_ANDROID_KEYSTORE_RELEASE_PATH")
		if key_path.is_empty():
			key_path = str(presets.get_value("preset.1.options", "keystore/release", ""))
		require(not key_path.is_empty() and FileAccess.file_exists(key_path), "Owner release upload keystore required (use environment secrets)")
	if str(ProjectSettings.get_setting("release/analytics/project_key", "")).is_empty():
		print("NOTICE: Remote analytics is intentionally unconfigured; no live country/retention dashboard yet")
	for error in errors:
		printerr("BLOCKER: ", error)
	print("PREFLIGHT %s: %d blockers" % ["development" if development else "production", errors.size()])
	quit(0 if errors.is_empty() else 1)
