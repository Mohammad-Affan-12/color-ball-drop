class_name AdService
extends Node

## Sole owner of AdMob, UMP, inventory, frequency policy and SDK telemetry.
## No fabricated rewards, impressions, revenue, or desktop SDK availability.
signal rewarded_ad_completed(placement: String)
signal rewarded_ad_failed(placement: String, reason: String)
signal interstitial_closed()
signal availability_changed()
signal presentation_changed(active: bool)
signal telemetry(event_name: String, properties: Dictionary)

const TEST_REWARDED := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL := "ca-app-pub-3940256099942544/1033173712"
const MIN_LEVEL_FOR_INTERSTITIAL := 11
const MIN_LEVELS_BETWEEN_INTERSTITIALS := 3
const MIN_SECONDS_BETWEEN_INTERSTITIALS := 180.0
const INVENTORY_TTL_MS := 3300000

var consent_granted := false # Only fresh UMP state can change this.
var remove_ads_owned := false
var ads_enabled := false
var live_sdk_attached := false
var is_safe_break: Callable
var _initialized := false
var _consent_updating := false
var _consent_checked := false
var _presenting := false
var _presentation_token := 0
var _levels_since_last_interstitial := 0
var _last_interstitial_time := 0.0
var _completed_breaks: Dictionary = {}
var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _rewarded_loaded_ms := 0
var _interstitial_loaded_ms := 0
var _reward_loading := false
var _interstitial_loading := false
var _reward_load_generation := 0
var _interstitial_load_generation := 0
var _retry_at_ms := 0
var _continuation: Callable
var _reward_callback: Callable
var _placement := ""
var _reward_earned := false
var _init_listener: OnInitializationCompleteListener
var _reward_listener: OnUserEarnedRewardListener
var _reward_loader: RewardedAdLoader
var _interstitial_loader: InterstitialAdLoader
var _consent_form: ConsentForm

func initialize(_legacy_consent: bool, is_ad_free: bool) -> void:
	remove_ads_owned = is_ad_free
	live_sdk_attached = OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob") and Engine.has_singleton("PoingGodotAdMobUserMessagingPlatform") and Engine.has_singleton("PoingGodotAdMobConsentInformation")
	_last_interstitial_time = Time.get_ticks_msec() / 1000.0
	ads_enabled = bool(ProjectSettings.get_setting("release/ads/audience_reviewed", false))

func _safe_break() -> bool:
	return is_safe_break.is_valid() and is_safe_break.call() and not _presenting

func prepare_at_break() -> void:
	if not live_sdk_attached or not ads_enabled or not _safe_break():
		return
	if not _consent_checked:
		if _consent_updating:
			return
		_consent_updating = true
		var params := ConsentRequestParameters.new()
		params.tag_for_under_age_of_consent = bool(ProjectSettings.get_setting("release/ads/under_age_of_consent", true))
		UserMessagingPlatform.consent_information.update(params, _consent_updated, _consent_failed)
	elif consent_granted:
		_initialize_sdk()
	elif UserMessagingPlatform.consent_information.get_is_consent_form_available():
		_load_consent_form()

func _consent_updated() -> void:
	_consent_updating = false
	_consent_checked = true
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	if status == ConsentInformation.ConsentStatus.REQUIRED:
		if _safe_break():
			_load_consent_form()
	else:
		_refresh_consent()

func _load_consent_form() -> void:
	if _consent_updating:
		return
	_consent_updating = true
	UserMessagingPlatform.load_consent_form(func(form: ConsentForm) -> void:
		_consent_updating = false
		if not _safe_break():
			return
		_consent_form = form
		var token := _set_presenting(true)
		form.show(func(error: FormError) -> void:
			if not _is_current_presentation(token):
				return
			_set_presenting(false)
			_consent_form = null
			if error == null:
				_refresh_consent()
			else:
				_consent_failed(error)
		)
	, _consent_failed)

func _consent_failed(_error: FormError) -> void:
	_consent_updating = false
	consent_granted = false
	_consent_checked = false
	availability_changed.emit()

func _refresh_consent() -> void:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	consent_granted = status == ConsentInformation.ConsentStatus.OBTAINED or status == ConsentInformation.ConsentStatus.NOT_REQUIRED
	if consent_granted and ads_enabled:
		_initialize_sdk()
	else:
		_discard_inventory()
	availability_changed.emit()

func open_privacy_options() -> void:
	if not live_sdk_attached or not ads_enabled or not _safe_break():
		return
	if not _consent_checked:
		prepare_at_break()
	elif UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED:
		_discard_inventory()
		consent_granted = false
		var token := _set_presenting(true)
		UserMessagingPlatform.show_privacy_options_form(func(error: FormError) -> void:
			if not _is_current_presentation(token):
				return
			_set_presenting(false)
			if error == null:
				_refresh_consent()
			else:
				_consent_failed(error)
		)
	else:
		prepare_at_break()

func _initialize_sdk() -> void:
	if _initialized:
		_preload()
		return
	_initialized = true
	var configuration := RequestConfiguration.new()
	configuration.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	configuration.tag_for_child_directed_treatment = int(ProjectSettings.get_setting("release/ads/child_directed", 1))
	configuration.tag_for_under_age_of_consent = int(ProjectSettings.get_setting("release/ads/under_age_of_consent", true))
	MobileAds.set_request_configuration(configuration)
	_init_listener = OnInitializationCompleteListener.new()
	_init_listener.on_initialization_complete = func(_status: InitializationStatus) -> void: _preload()
	MobileAds.initialize(_init_listener)

func _unit_id(rewarded: bool) -> String:
	if OS.is_debug_build() or bool(ProjectSettings.get_setting("release/ads/test_mode", true)):
		return TEST_REWARDED if rewarded else TEST_INTERSTITIAL
	return str(ProjectSettings.get_setting("release/ads/rewarded_unit" if rewarded else "release/ads/interstitial_unit", ""))

func _preload() -> void:
	if not live_sdk_attached or not _initialized or not consent_granted or not ads_enabled or _presenting or Time.get_ticks_msec() < _retry_at_ms:
		return
	if _rewarded != null and Time.get_ticks_msec() - _rewarded_loaded_ms >= INVENTORY_TTL_MS:
		_rewarded.destroy()
		_rewarded = null
	if _interstitial != null and Time.get_ticks_msec() - _interstitial_loaded_ms >= INVENTORY_TTL_MS:
		_interstitial.destroy()
		_interstitial = null
	if _rewarded == null and not _reward_loading and not _unit_id(true).is_empty():
		_reward_loading = true
		_reward_load_generation += 1
		_reward_loader = RewardedAdLoader.new()
		var callback := RewardedAdLoadCallback.new()
		callback.on_ad_loaded = _on_rewarded_loaded.bind(_reward_load_generation)
		callback.on_ad_failed_to_load = _on_rewarded_load_failed.bind(_reward_load_generation)
		_reward_loader.load(_unit_id(true), AdRequest.new(), callback)
	if not remove_ads_owned and _interstitial == null and not _interstitial_loading and not _unit_id(false).is_empty():
		_interstitial_loading = true
		_interstitial_load_generation += 1
		_interstitial_loader = InterstitialAdLoader.new()
		var callback := InterstitialAdLoadCallback.new()
		callback.on_ad_loaded = _on_interstitial_loaded.bind(_interstitial_load_generation)
		callback.on_ad_failed_to_load = _on_interstitial_load_failed.bind(_interstitial_load_generation)
		_interstitial_loader.load(_unit_id(false), AdRequest.new(), callback)

func _on_rewarded_loaded(ad: RewardedAd, generation: int) -> void:
	if generation != _reward_load_generation or not _reward_loading:
		ad.destroy()
		return
	_reward_loading = false
	if not consent_granted or not ads_enabled:
		ad.destroy()
		return
	_rewarded = ad
	_rewarded_loaded_ms = Time.get_ticks_msec()
	availability_changed.emit()

func _on_rewarded_load_failed(_error: LoadAdError, generation: int) -> void:
	if generation != _reward_load_generation or not _reward_loading:
		return
	_reward_loading = false
	_retry_at_ms = Time.get_ticks_msec() + 60000
	availability_changed.emit()

func _on_interstitial_loaded(ad: InterstitialAd, generation: int) -> void:
	if generation != _interstitial_load_generation or not _interstitial_loading:
		ad.destroy()
		return
	_interstitial_loading = false
	if not consent_granted or not ads_enabled or remove_ads_owned:
		ad.destroy()
		return
	_interstitial = ad
	_interstitial_loaded_ms = Time.get_ticks_msec()

func _on_interstitial_load_failed(_error: LoadAdError, generation: int) -> void:
	if generation != _interstitial_load_generation or not _interstitial_loading:
		return
	_interstitial_loading = false
	_retry_at_ms = Time.get_ticks_msec() + 60000

func is_rewarded_available() -> bool:
	return live_sdk_attached and consent_granted and ads_enabled and not _presenting and _rewarded != null and Time.get_ticks_msec() - _rewarded_loaded_ms < INVENTORY_TTL_MS

func show_rewarded_ad(placement: String, on_reward_earned: Callable, on_unavailable: Callable = Callable()) -> void:
	if not is_rewarded_available() or not _safe_break():
		rewarded_ad_failed.emit(placement, "Ad unavailable. Keep playing offline.")
		if on_unavailable.is_valid():
			on_unavailable.call()
		return
	_placement = placement
	_reward_callback = on_reward_earned
	_reward_earned = false
	var token := _set_presenting(true)
	_rewarded.full_screen_content_callback = _content_callbacks("rewarded", token, placement)
	_rewarded.on_ad_paid = _paid_callback("rewarded", placement)
	_reward_listener = OnUserEarnedRewardListener.new()
	_reward_listener.on_user_earned_reward = func(_reward: RewardedItem) -> void:
		if not _is_current_presentation(token) or _reward_earned or not _reward_callback.is_valid():
			return
		_reward_earned = true
		rewarded_ad_completed.emit(_placement)
		_reward_callback.call()
	_rewarded.show(_reward_listener)

func can_show_interstitial(completed_level_idx: int, current_time_sec: float) -> bool:
	return live_sdk_attached and consent_granted and ads_enabled and not remove_ads_owned and not _presenting and _interstitial != null and completed_level_idx >= MIN_LEVEL_FOR_INTERSTITIAL and _levels_since_last_interstitial >= MIN_LEVELS_BETWEEN_INTERSTITIALS and current_time_sec - _last_interstitial_time >= MIN_SECONDS_BETWEEN_INTERSTITIALS and Time.get_ticks_msec() - _interstitial_loaded_ms < INVENTORY_TTL_MS

func on_level_completed_break(completed_level_idx: int, current_time_sec: float, on_continue: Callable) -> bool:
	if not _completed_breaks.has(completed_level_idx):
		_completed_breaks[completed_level_idx] = true
		_levels_since_last_interstitial += 1
	if can_show_interstitial(completed_level_idx, current_time_sec) and _safe_break():
		_continuation = on_continue
		var token := _set_presenting(true)
		_interstitial.full_screen_content_callback = _content_callbacks("interstitial", token, "next_level")
		_interstitial.on_ad_paid = _paid_callback("interstitial", "next_level")
		_levels_since_last_interstitial = 0
		_last_interstitial_time = current_time_sec
		_interstitial.show()
		return true
	if on_continue.is_valid():
		on_continue.call()
	return false

func _content_callbacks(format_name: String, token: int, placement: String) -> FullScreenContentCallback:
	var callback := FullScreenContentCallback.new()
	var impression_logged := [false]
	var test_ad := OS.is_debug_build() or bool(ProjectSettings.get_setting("release/ads/test_mode", true))
	callback.on_ad_impression = func() -> void:
		if not _is_current_presentation(token) or impression_logged[0]:
			return
		impression_logged[0] = true
		telemetry.emit("ad_impression", {"format": format_name, "placement": placement, "test_ad": test_ad})
	callback.on_ad_dismissed_full_screen_content = _finish_ad.bind(format_name, token)
	callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void: _finish_ad(format_name, token)
	return callback

func _paid_callback(format_name: String, placement: String) -> Callable:
	var paid_logged := [false]
	var test_ad := OS.is_debug_build() or bool(ProjectSettings.get_setting("release/ads/test_mode", true))
	return func(value: AdValue) -> void:
		if paid_logged[0]:
			return
		paid_logged[0] = true
		# A genuine paid callback may arrive after dismissal. Preserve its original
		# placement instead of associating it with whichever ad is now presenting.
		telemetry.emit("ad_revenue", {"format": format_name, "placement": placement, "value_micros": value.value_micros, "currency": value.currency_code, "precision": value.precision, "test_ad": test_ad})

func _finish_ad(format_name: String, token: int) -> void:
	if not _is_current_presentation(token):
		return
	if format_name == "rewarded":
		if _rewarded != null:
			_rewarded.destroy()
		_rewarded = null
		_reward_callback = Callable()
	else:
		if _interstitial != null:
			_interstitial.destroy()
		_interstitial = null
	_set_presenting(false)
	var continuation := _continuation
	_continuation = Callable()
	if format_name == "interstitial":
		interstitial_closed.emit()
	if continuation.is_valid():
		continuation.call()
	availability_changed.emit()

func _is_current_presentation(token: int) -> bool:
	return _presenting and token == _presentation_token

func _set_presenting(active: bool) -> int:
	_presentation_token += 1
	_presenting = active
	presentation_changed.emit(active)
	availability_changed.emit()
	return _presentation_token

func _discard_inventory() -> void:
	# Native loads cannot be cancelled by this wrapper. Invalidate their callbacks
	# before a changed consent state can start another request.
	_reward_load_generation += 1
	_interstitial_load_generation += 1
	_reward_loading = false
	_interstitial_loading = false
	if _rewarded != null:
		_rewarded.destroy()
	if _interstitial != null:
		_interstitial.destroy()
	_rewarded = null
	_interstitial = null

func _exit_tree() -> void:
	_discard_inventory()
