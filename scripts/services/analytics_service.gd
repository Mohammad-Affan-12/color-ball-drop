class_name AnalyticsService
extends RefCounted

const MAX_BUFFER_SIZE := 200

var consent_granted: bool = true
var event_history: Array[Dictionary] = []

func log_event(event_name: String, properties: Dictionary = {}) -> void:
	if not consent_granted and event_name != "session_start":
		return
	var entry := {
		"event": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"props": properties.duplicate()
	}
	event_history.append(entry)
	if event_history.size() > MAX_BUFFER_SIZE:
		event_history.pop_front()

func has_logged_event(event_name: String) -> bool:
	for item in event_history:
		if item["event"] == event_name:
			return true
	return false

func get_event_count(event_name: String) -> int:
	var c := 0
	for item in event_history:
		if item["event"] == event_name:
			c += 1
	return c

func clear_history() -> void:
	event_history.clear()
