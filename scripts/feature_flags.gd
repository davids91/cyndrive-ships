extends Node
## Feature flag system for trunk-based development.
## Flags are loaded from feature_flags.json (gitignored) at startup.
## All flags default to false if the file doesn't exist or flag is not defined.

var _flags: Dictionary = {}


func _ready() -> void:
	_load_flags()


func _load_flags() -> void:
	if not FileAccess.file_exists("res://feature_flags.json"):
		print("ERROR: missing feature_flags.json - every feature will be turned off!")
		return
	var file := FileAccess.open("res://feature_flags.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json is Dictionary:
			_flags = json


func is_enabled(flag_name: String) -> bool:
	var flag = _flags.get(flag_name, {})
	if flag is Dictionary:
		return flag.get("enabled", false)
	return false
