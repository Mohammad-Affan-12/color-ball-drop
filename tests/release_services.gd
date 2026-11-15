extends SceneTree

class TestInterstitial extends InterstitialAd:
	var shows := 0
	var destroyed := false
	func _init() -> void: super(-9001)
	func register_callbacks() -> void: pass
	func show() -> void: shows += 1
	func destroy() -> void: destroyed = true

class TestRewarded extends RewardedAd:
	var listener: OnUserEarnedRewardListener
	var destroyed := false
	func _init() -> void: super(-9002)
	func register_callbacks() -> void: pass
	func show(reward := OnUserEarnedRewardListener.new()) -> void: listener = reward
	func destroy() -> void: destroyed = true

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.test-user"))
	var analytics := AnalyticsService.new()
	root.add_child(analytics)
	analytics.configure(false, "res://.test-user/release_analytics.cfg")
	analytics.log_event("session_start")
	check(analytics.event_history.is_empty(), "No collection before opt-in, including session_start")
	analytics.set_opt_in(true)
	analytics.log_event("level_complete", {"level": 1})
	check(analytics.has_logged_event("level_complete"), "Opt-in allows gameplay telemetry")
	check(FileAccess.file_exists("res://.test-user/release_analytics.cfg"), "Opt-in creates random local identity")
	analytics.set_opt_in(false)
	check(analytics.event_history.is_empty() and analytics._pending.is_empty(), "Opt-out erases buffered telemetry")
	check(not FileAccess.file_exists("res://.test-user/release_analytics.cfg"), "Opt-out removes local identity")
	analytics.flush()
	check(analytics._inflight.is_empty(), "Unconfigured transport cannot send")
	var ads := AdService.new()
	root.add_child(ads)
	ads.initialize(true, false)
	check(not ads.consent_granted and not ads.is_rewarded_available(), "Legacy combined consent never authorizes native ads")
	var rewards := [0]
	var continuations := [0]
	ads.show_rewarded_ad("test", func() -> void: rewards[0] += 1)
	check(rewards[0] == 0, "Unavailable rewarded never grants coins")
	ads.on_level_completed_break(12, 500, func() -> void: continuations[0] += 1)
	check(continuations[0] == 1, "Offline next-level callback runs immediately exactly once")
	# Explicit test doubles; never installed or used by production paths.
	ads.live_sdk_attached = true
	ads.ads_enabled = true
	ads.consent_granted = true
	ads.is_safe_break = func() -> bool: return true
	ads._last_interstitial_time = 0
	var inventory := TestInterstitial.new()
	ads._interstitial = inventory
	ads._interstitial_loaded_ms = Time.get_ticks_msec()
	ads.on_level_completed_break(12, 500, Callable())
	check(ads._levels_since_last_interstitial == 1, "Repeated same completion does not increase frequency counter")
	ads.on_level_completed_break(13, 500, Callable())
	check(not ads.can_show_interstitial(5, 500), "Early campaign cannot show interstitials")
	check(not ads.can_show_interstitial(14, 100), "Session grace/cooldown blocks early ads")
	ads.is_safe_break = func() -> bool: return false
	ads.on_level_completed_break(14, 500, func() -> void: continuations[0] += 1)
	check(inventory.shows == 0, "Never show while gameplay is active")
	ads.is_safe_break = func() -> bool: return true
	ads.on_level_completed_break(15, 500, func() -> void: continuations[0] += 1)
	check(inventory.shows == 1 and continuations[0] == 2, "Eligible ad waits for dismissal before continuing")
	inventory.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	inventory.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	check(continuations[0] == 3, "Duplicate dismissal cannot navigate twice")
	check(not ads.can_show_interstitial(16, 510), "Cooldown enforced after ad")
	var reward := TestRewarded.new()
	ads._rewarded = reward
	ads._rewarded_loaded_ms = Time.get_ticks_msec()
	ads.show_rewarded_ad("test", func() -> void: rewards[0] += 1)
	check(rewards[0] == 0, "Opening an ad never grants reward")
	var item := RewardedItem.new(1, "test")
	reward.listener.on_user_earned_reward.call(item)
	reward.listener.on_user_earned_reward.call(item)
	check(rewards[0] == 1, "Only earned callback grants reward, once")
	reward.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	var skipped := TestRewarded.new()
	ads._rewarded = skipped
	ads._rewarded_loaded_ms = Time.get_ticks_msec()
	ads.show_rewarded_ad("test", func() -> void: rewards[0] += 1)
	skipped.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	check(rewards[0] == 1, "Skipping rewarded grants nothing")
	# Retained callbacks from an old ad must not affect a later presentation.
	var telemetry: Array[Dictionary] = []
	ads.telemetry.connect(func(event: String, properties: Dictionary) -> void:
		telemetry.append({"event": event, "properties": properties})
	)
	var next_reward := TestRewarded.new()
	ads._rewarded = next_reward
	ads._rewarded_loaded_ms = Time.get_ticks_msec()
	ads.show_rewarded_ad("second", func() -> void: rewards[0] += 1)
	reward.listener.on_user_earned_reward.call(item)
	reward.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	reward.full_screen_content_callback.on_ad_failed_to_show_full_screen_content.call(null)
	check(rewards[0] == 1, "Stale earned callback cannot grant the next ad's reward")
	check(ads._presenting and ads._rewarded == next_reward and not next_reward.destroyed, "Old dismiss/failure cannot end a subsequent rewarded ad")
	reward.full_screen_content_callback.on_ad_impression.call()
	check(telemetry.is_empty(), "Stale impression cannot be attributed to a subsequent placement")
	var test_value := AdValue.new("USD", AdValue.PrecisionType.ESTIMATED, 123)
	reward.on_ad_paid.call(test_value)
	reward.on_ad_paid.call(test_value)
	check(telemetry.size() == 1 and telemetry[0].properties.placement == "test" and telemetry[0].properties.value_micros == 123, "Late paid callback keeps original placement and deduplicates")
	next_reward.full_screen_content_callback.on_ad_impression.call()
	next_reward.full_screen_content_callback.on_ad_impression.call()
	check(telemetry.size() == 2 and telemetry[1].properties.placement == "second", "Current impression is attributed once to its own placement")
	next_reward.listener.on_user_earned_reward.call(item)
	check(rewards[0] == 2, "A current ad still earns its own reward after stale callbacks")
	next_reward.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	# Simulate a new UMP presentation without invoking a fake native consent SDK.
	var ump_token := ads._set_presenting(true)
	next_reward.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	next_reward.full_screen_content_callback.on_ad_failed_to_show_full_screen_content.call(null)
	check(ads._is_current_presentation(ump_token), "Old ad callbacks cannot end a later UMP presentation")
	ads._set_presenting(false)
	var next_interstitial := TestInterstitial.new()
	ads._interstitial = next_interstitial
	ads._interstitial_loaded_ms = Time.get_ticks_msec()
	ads._levels_since_last_interstitial = 3
	ads.on_level_completed_break(16, 900, func() -> void: continuations[0] += 1)
	inventory.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	inventory.full_screen_content_callback.on_ad_failed_to_show_full_screen_content.call(null)
	next_reward.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	check(ads._presenting and ads._interstitial == next_interstitial and continuations[0] == 3, "Old ad callbacks cannot dismiss or navigate a subsequent interstitial")
	next_interstitial.full_screen_content_callback.on_ad_failed_to_show_full_screen_content.call(null)
	check(not ads._presenting and continuations[0] == 4, "Current failed-to-show resumes navigation exactly once")
	# A pending load under an earlier privacy state must not become new inventory.
	ads._reward_loading = true
	ads._interstitial_loading = true
	var old_reward_generation := ads._reward_load_generation
	var old_interstitial_generation := ads._interstitial_load_generation
	ads._discard_inventory()
	check(not ads._reward_loading and not ads._interstitial_loading, "Discard invalidates both pending inventory generations")
	ads._reward_load_generation += 1
	ads._interstitial_load_generation += 1
	ads._reward_loading = true
	ads._interstitial_loading = true
	var stale_reward := TestRewarded.new()
	var stale_interstitial := TestInterstitial.new()
	ads._on_rewarded_loaded(stale_reward, old_reward_generation)
	ads._on_interstitial_loaded(stale_interstitial, old_interstitial_generation)
	check(stale_reward.destroyed and stale_interstitial.destroyed and ads._rewarded == null and ads._interstitial == null, "Loads from before privacy withdrawal are destroyed")
	ads._on_rewarded_load_failed(null, old_reward_generation)
	ads._on_interstitial_load_failed(null, old_interstitial_generation)
	check(ads._reward_loading and ads._interstitial_loading, "Stale load success/failure cannot clear a newer pending request")
	var fresh_reward := TestRewarded.new()
	var fresh_interstitial := TestInterstitial.new()
	ads._on_rewarded_loaded(fresh_reward, ads._reward_load_generation)
	ads._on_interstitial_loaded(fresh_interstitial, ads._interstitial_load_generation)
	check(ads._rewarded == fresh_reward and ads._interstitial == fresh_interstitial and not ads._reward_loading and not ads._interstitial_loading, "Only current inventory generation is accepted")
	var save := SaveManager.new("res://.test-user/release_migration.cfg")
	save.reset_to_defaults(false)
	save.privacy_consent_granted = true
	save.analytics_opt_in = false
	save.record_level_win(7, 3, 2)
	var migrated := SaveManager.new("res://.test-user/release_migration.cfg")
	check(migrated.highest_unlocked_level == 8 and migrated.get_level_stars(7) == 3, "Existing v2 progress remains readable")
	check(not migrated.analytics_opt_in, "Legacy privacy allowance does not opt a migrated save into analytics")
	save.record_daily_challenge_win("2026-11-01")
	save.record_daily_challenge_win("2026-11-02")
	check(save.daily_streak == 2, "Consecutive dates extend streak")
	save.record_daily_challenge_win("2026-11-15")
	check(save.daily_streak == 1, "Gap resets daily streak")
	save.record_daily_challenge_win("2026-11-15")
	check(save.daily_streak == 1, "Replay never increments daily streak")
	TranslationServer.set_locale("es")
	check(tr("Next level") == "Siguiente nivel", "Spanish translations loaded")
	TranslationServer.set_locale("en")
	ads.queue_free()
	analytics.queue_free()
	await process_frame
	print("RELEASE SERVICES: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
