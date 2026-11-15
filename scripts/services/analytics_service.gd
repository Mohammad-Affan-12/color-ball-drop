class_name AnalyticsService
extends Node

## Opt-in PostHog Capture API; no auto-collection, session replay, ad ID or GPS.
const MAX_BUFFER_SIZE := 200
const MAX_SESSION_EVENTS := 150
const ALLOWED_EVENTS := ["session_start", "session_resume", "level_start", "level_complete", "level_fail", "level_restart", "hint_used", "tutorial_complete", "rewarded_ad_completed", "ad_impression", "ad_revenue", "cosmetic_unlocked"]
var consent_granted := false:
	set(value):
		consent_granted = value
		if not value:
			clear_history()
			_pending.clear()
			if _request != null:
				_request.cancel_request()
			_inflight.clear()
var event_history: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _inflight: Array[Dictionary] = []
var _request: HTTPRequest
var _timer := 0.0
var _session_events := 0
var _distinct_id := ""
var _session_id := ""
var _host := ""
var _key := ""
var _identity_path := "user://analytics_identity.cfg"

func configure(enabled: bool, identity_path: String = "user://analytics_identity.cfg") -> void:
	_identity_path = identity_path
	consent_granted = enabled
	_host = str(ProjectSettings.get_setting("release/analytics/host", ""))
	_key = str(ProjectSettings.get_setting("release/analytics/project_key", ""))
	_session_id = _uuid()
	if enabled:
		_load_identity()
	if _request == null:
		_request = HTTPRequest.new()
		_request.timeout = 5.0
		_request.body_size_limit = 65536
		add_child(_request)
		_request.request_completed.connect(_on_request_completed)

func _load_identity() -> void:
	var cfg := ConfigFile.new()
	cfg.load(_identity_path)
	_distinct_id = str(cfg.get_value("analytics", "id", ""))
	if _distinct_id.is_empty():
		_distinct_id = Crypto.new().generate_random_bytes(16).hex_encode()
		cfg.set_value("analytics", "id", _distinct_id)
		cfg.save(_identity_path)

func set_opt_in(enabled: bool) -> void:
	consent_granted = enabled
	if enabled:
		_load_identity()
	else:
		_distinct_id = ""
		if FileAccess.file_exists(_identity_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_identity_path))

func log_event(event_name: String, properties: Dictionary = {}) -> void:
	if not consent_granted or not ALLOWED_EVENTS.has(event_name) or _session_events >= MAX_SESSION_EVENTS:
		return
	_session_events += 1
	var props := properties.duplicate(true)
	props["distinct_id"] = _distinct_id
	props["$session_id"] = _session_id
	props["$process_person_profile"] = false
	props["locale"] = TranslationServer.get_locale()
	props["build_version"] = "1.0.0"
	props["development_build"] = OS.is_debug_build()
	var entry := {"event": event_name, "timestamp": Time.get_datetime_string_from_system(true) + "Z", "properties": props, "uuid": _uuid()}
	event_history.append(entry)
	_pending.append(entry)
	if event_history.size() > MAX_BUFFER_SIZE:
		event_history.pop_front()
	if _pending.size() > MAX_BUFFER_SIZE:
		_pending.pop_front()

func _uuid() -> String:
	var raw := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-4%s-8%s-%s" % [raw.substr(0, 8), raw.substr(8, 4), raw.substr(13, 3), raw.substr(17, 3), raw.substr(20, 12)]

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 30.0:
		_timer = 0.0
		flush()

func flush() -> void:
	# Empty configuration intentionally makes no network calls. No disk event queue.
	if not consent_granted or _key.is_empty() or _request == null or _pending.is_empty() or not _inflight.is_empty():
		return
	if not _host in ["https://us.i.posthog.com", "https://eu.i.posthog.com"]:
		return
	_inflight.assign(_pending.slice(0, 20))
	for _i in range(_inflight.size()):
		_pending.pop_front()
	var error := _request.request(_host + "/batch/", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"api_key": _key, "batch": _inflight}))
	if error != OK:
		_on_request_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if consent_granted and (result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300):
		for entry in _inflight:
			if _pending.size() < MAX_BUFFER_SIZE:
				_pending.append(entry)
	_inflight.clear()

func has_logged_event(event_name: String) -> bool:
	return get_event_count(event_name) > 0

func get_event_count(event_name: String) -> int:
	var count := 0
	for item in event_history:
		if item["event"] == event_name:
			count += 1
	return count

func clear_history() -> void:
	event_history.clear()
