extends CanvasLayer

signal dialouge_finished()

@onready var dialogText = %main_dialogue
@onready var dialogIcon = %npc_icon

@export var portraits: Array = [
	preload("res://textures/entities/npc_1.png"),
	preload("res://textures/entities/npc_2.png"),
	preload("res://textures/entities/npc_3.png"),
	preload("res://textures/entities/npc_5.png"),
	preload("res://textures/entities/npc_4.png")
]

@export var seconds_per_letter: float = 0.025
@export var seconds_after_each_line: float = 1.5
@export_file("*.txt") var dialog: String = ""
@export var dialogue_conditionals: Array[bool] = []
@export var unskippable_signals: Array[int] = []
@export var is_dialogue_active: bool = false

@onready var dialog_lines: PackedStringArray = _load_dialog_lines()

func _load_dialog_lines() -> PackedStringArray:
	var file = FileAccess.open(dialog, FileAccess.READ)
	if file == null:
		push_error("Failed to open dialogue file: " + dialog)
		return PackedStringArray()
	return file.get_as_text().split("\n")

var signals_shot: Dictionary = {}

func start() -> void:
	signals_shot.clear()
	current_line = 0
	if dialog_lines.is_empty():
		push_error("No dialogue lines loaded for: " + dialog)
		return
	current_line_text = _parse_line(dialog_lines[0])
	dialogText.text = ""
	is_dialogue_active = true
	dialogue_in_progress = true
	set_visible(true)

var line_pauses: Dictionary = {}
var line_signal_index_values: Dictionary = {}
var line_tempo_changes: Dictionary = {}
func _parse_token(token:String, at_index: int) -> bool:
	if token[0] == 'd': # Disable line by condition
		var condition_index: int = int(token.substr(1))
		var condition = abs(condition_index) < dialogue_conditionals.size() and dialogue_conditionals[condition_index]
		return not condition
	if token[0] == 'e': # Enable line by condition
		var condition_index: int = int(token.substr(1))
		var condition = abs(condition_index) < dialogue_conditionals.size() and dialogue_conditionals[condition_index]
		return condition

	if token[0] == 'c': 
		dialogIcon.texture = portraits[int(token.substr(1))]
	elif token[0] == 't':
		if token.length() < 2: line_tempo_changes[at_index] = seconds_per_letter
		else: line_tempo_changes[at_index] = max(1.,float(token.substr(1))) / 1000.
	elif token[0] == 'p':
		line_pauses[at_index] =  float(token.substr(1)) / 1000.
	elif token[0] == 's':
		line_signal_index_values[at_index] = int(token.substr(1))
	return true

# Parses tokens from the line and sets internal state based on them
func _parse_line(line: String)-> String:
	line_pauses.clear()
	line_tempo_changes.clear()
	line_signal_index_values.clear()
	var remaining_text: String = line
	var parsed_text: String = ""
	var next_token_start = remaining_text.find("#[")
	while(-1 != next_token_start):
		parsed_text += remaining_text.substr(0, next_token_start)
		remaining_text = remaining_text.substr(next_token_start + 2)
		var token_end = remaining_text.find("]")

		# Do not continue with parsing the dialogue depending on the output of the tokens
		if not _parse_token(remaining_text.substr(0, token_end), parsed_text.length() + 1):
			return parsed_text
		remaining_text = remaining_text.substr(token_end + 1)
		next_token_start = remaining_text.find("#[")
	parsed_text += remaining_text
	return parsed_text

const signals_probably_enough: int = 10
func _init() -> void:
	for sig in range(signals_probably_enough):
		add_user_signal("dialogue_signal_" + str(sig))

func _ready() -> void:
	if not dialog_lines.is_empty():
		current_line_text = _parse_line(dialog_lines[0])

@onready var dialogue_in_progress: bool = false
var current_letter: int = 0
var current_line: int = 0
var current_line_text: String = ""
var current_tempo: float = seconds_per_letter
var delay_remaining: float = 0.0
func _process(delta: float) -> void:
	if not dialogue_in_progress: return

	# decide to even do anything or not based on the actual delay and line progress
	delay_remaining -= delta / Difficulty.gameplay_speed

	if delay_remaining > 0. or abs(current_line) >= dialog_lines.size():
		return

	# Start a new line
	if current_letter > current_line_text.length():
		current_letter = 0
		current_line_text = ""
		while current_line_text.is_empty() and abs(current_line) < dialog_lines.size():
			current_line += 1
			if abs(current_line) < dialog_lines.size(): current_line_text = _parse_line(dialog_lines[current_line])
		if ( # dialog completed or the last line of the dialog is empty
			current_line >= dialog_lines.size()
			or(current_line == dialog_lines.size() - 1 and dialog_lines[current_line].strip_edges() == "")
		):
			$control/content_container/HBoxContainer/VBoxContainer/continue/continue_button.set_text("Press Space to continue..")
			$control/content_container/HBoxContainer/VBoxContainer/continue.set_visible(true)
			dialogue_in_progress = false
			return


	# Set the tempo based on the tokens within the line
	if line_tempo_changes.has(current_letter):
		current_tempo = line_tempo_changes[current_letter]

	# Emit a signal based on the tokens within the line
	if line_signal_index_values.has(current_letter):
		signals_shot[line_signal_index_values[current_letter]] = true
		emit_signal("dialogue_signal_" + str(line_signal_index_values[current_letter]))

	# Set displayed text and prepare next letter
	dialogText.text = current_line_text.substr(0, current_letter)
	current_letter += 1

	# Decide the time to wait until the next letter
	if line_pauses.has(current_letter):
		delay_remaining = line_pauses[current_letter]
	elif current_letter > current_line_text.length():
		delay_remaining = seconds_after_each_line
	else: delay_remaining = current_tempo

var skip_shown: bool = false
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if is_dialogue_active and (not dialogue_in_progress or skip_shown): _on_continue_pressed()
		else:
			skip_shown = true
			$control/content_container/HBoxContainer/VBoxContainer/continue/continue_button.set_text("Press Space to skip..")
			$control/content_container/HBoxContainer/VBoxContainer/continue.set_visible(true)

func _on_continue_pressed() -> void:
	is_dialogue_active = false
	current_tempo = seconds_per_letter
	dialogue_in_progress = false
	set_visible(false)
	skip_shown = false
	$control/content_container/HBoxContainer/VBoxContainer/continue/continue_button.set_text("Press Space to continue..")
	$control/content_container/HBoxContainer/VBoxContainer/continue.set_visible(false)
	for signal_idx in unskippable_signals:
		if not signals_shot.has(signal_idx):
			emit_signal("dialogue_signal_" + str(signal_idx))
	signals_shot.clear()
	dialouge_finished.emit()
