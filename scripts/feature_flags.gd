extends Node
## Feature flag system for trunk-based development.
## Production flags are loaded from feature_flags.json (tracked in git).
## In the editor, feature_flags.dev.json (gitignored) is merged on top for local overrides.
## All flags default to false if not defined.

var _flags: Dictionary = {}


func _ready() -> void:
	_detect_auto_flags()
	_load_flags()

func _load_flags() -> void:
	if not FileAccess.file_exists("res://feature_flags.json"):
		print("feature_flags.json not found: creating file with default settings...")
		var dir = DirAccess.open("res://")
		if dir.copy("res://feature_flags.example.json", "res://feature_flags.json") != OK:
			print("ERROR copying file!")
	var base := _parse_json_file("res://feature_flags.json")
	_flags = base
	if OS.has_feature("editor") and FileAccess.file_exists("res://feature_flags.dev.json"):
		var overrides := _parse_json_file("res://feature_flags.dev.json")
		_flags.merge(overrides, true)

func _detect_auto_flags() -> void:
	if OS.has_feature("web"): _flags["auto__WEB"] = { "enabled": true }
	else: _flags["auto__WEB"] = { "enabled": false }

func _parse_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json is Dictionary:
			return json
	return {}


func is_enabled(flag_name: String) -> bool:
	var flag = _flags.get(flag_name, {})
	if flag is Dictionary:
		return flag.get("enabled", false)
	return false
