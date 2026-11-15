extends SceneTree

## Translation QA inventory; does not alter game scripts or puzzle data.
var messages: Dictionary = {}

func _init() -> void:
	_scan("res://scripts")
	var output := FileAccess.open("res://docs/localization-inventory.txt", FileAccess.WRITE)
	var keys := messages.keys()
	keys.sort()
	for key in keys:
		output.store_line(key)
	print("Localization inventory: %d candidate strings (manual review required)" % keys.size())
	quit()

func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	for child in dir.get_directories():
		_scan(path.path_join(child))
	var regex := RegEx.new()
	regex.compile('"([^"\\n]+)"')
	for name in dir.get_files():
		if not name.ends_with(".gd"):
			continue
		for result in regex.search_all(FileAccess.get_file_as_string(path.path_join(name))):
			var value: String = result.get_string(1)
			if value.contains(" ") and not value.begins_with("res://"):
				messages[value] = true
