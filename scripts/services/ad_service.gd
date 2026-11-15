class_name AdService
extends RefCounted

signal rewarded_ad_completed(placement: String)
signal rewarded_ad_failed(placement: String, reason: String)
signal interstitial_closed()

var consent_granted: bool = true
var remove_ads_owned: bool = false
var simulated_online: bool = true
var live_sdk_attached: bool = false

var _levels_since_last_interstitial: int = 0
var _last_interstitial_time: float = -999.0
const MIN_LEVEL_FOR_INTERSTITIAL := 11
const MIN_LEVELS_BETWEEN_INTERSTITIALS := 3
const MIN_SECONDS_BETWEEN_INTERSTITIALS := 180.0

func initialize(has_consent: bool, is_ad_free: bool) -> void:
	consent_granted = has_consent
	remove_ads_owned = is_ad_free
	live_sdk_attached = Engine.has_singleton("PoingGodotAdMob")

func is_rewarded_available() -> bool:
	return simulated_online

func show_rewarded_ad(placement: String, on_reward_earned: Callable, on_unavailable: Callable = Callable()) -> void:
	if not simulated_online:
		rewarded_ad_failed.emit(placement, "Offline or ad unavailable")
		if on_unavailable.is_valid():
			on_unavailable.call()
		return
	# In development/test mode (or when SDK reward callback confirms completion), grant reward:
	rewarded_ad_completed.emit(placement)
	if on_reward_earned.is_valid():
		on_reward_earned.call()

func can_show_interstitial(completed_level_idx: int, current_time_sec: float) -> bool:
	if remove_ads_owned or not consent_granted or not simulated_online:
		return false
	if completed_level_idx < MIN_LEVEL_FOR_INTERSTITIAL:
		return false
	if _levels_since_last_interstitial < MIN_LEVELS_BETWEEN_INTERSTITIALS:
		return false
	if (current_time_sec - _last_interstitial_time) < MIN_SECONDS_BETWEEN_INTERSTITIALS:
		return false
	return true

func on_level_completed_break(completed_level_idx: int, current_time_sec: float, on_continue: Callable) -> bool:
	_levels_since_last_interstitial += 1
	if can_show_interstitial(completed_level_idx, current_time_sec):
		_levels_since_last_interstitial = 0
		_last_interstitial_time = current_time_sec
		interstitial_closed.emit()
		if on_continue.is_valid():
			on_continue.call()
		return true
	if on_continue.is_valid():
		on_continue.call()
	return false
