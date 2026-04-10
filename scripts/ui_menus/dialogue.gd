class_name DialoguePanel
extends CanvasLayer

signal dialouge_finished()

static var active_dialogue: DialoguePanel = null

@onready var dialogText: Label = %main_dialogue
@onready var dialogIcon: TextureRect = %npc_icon
@onready var continue_panel: HBoxContainer = %continue
@onready var continue_button: Button = continue_panel.get_node("continue_button")

@export var portraits: Array = [
	preload("res://textures/entities/npc_1.png"),
	preload("res://textures/entities/npc_2.png"),
	preload("res://textures/entities/npc_3.png"),
	preload("res://textures/entities/npc_5.png"),
	preload("res://textures/entities/npc_4.png")
]

@export var seconds_per_letter: float = 0.01
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
	# Finish any other dialogue in progress, and make this the active dialogue
	if active_dialogue and active_dialogue.is_dialogue_active:
		active_dialogue.finish()
		active_dialogue = self

	signals_shot.clear()
	current_line = 0
	if dialog_lines.is_empty():
		push_error("No dialogue lines loaded for: " + dialog)
		return
	current_line_text = _parse_line(dialog_lines[0])
	dialogText.text = ""
	is_dialogue_active = true
	dialogue_in_progress = true
	line_in_progress = true
	set_visible(true)
	$control.call_deferred("grab_focus")

func finish() -> void:
	current_tempo = seconds_per_letter
	dialogue_in_progress = false
	is_dialogue_active = false
	set_visible(false)
	for signal_idx in unskippable_signals: if not signals_shot.has(signal_idx):
		emit_signal("dialogue_signal_" + str(signal_idx))
	signals_shot.clear()
	dialouge_finished.emit()

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

@export var autostart: bool = false
func _ready() -> void:
	if not dialog_lines.is_empty():
		current_line_text = _parse_line(dialog_lines[0])
	if autostart: start()

@export var skip_line_interval_sec: float = 0.6
@export var skip_line_count_for_finish: int = 4
var lines_skipped_quickly: int = 0
var previous_line_started_at: float = 0.
func start_new_line() -> void:
	if not dialogue_in_progress: return
	if abs(Time.get_ticks_msec() - previous_line_started_at)/ 1000. < skip_line_interval_sec:
		lines_skipped_quickly += 1
		if lines_skipped_quickly >= skip_line_count_for_finish:
			finish()
	else: lines_skipped_quickly = 0
	previous_line_started_at = Time.get_ticks_msec()
	continue_panel.set_visible(false)
	delay_remaining = 0.
	current_letter = 0
	current_line_text = ""
	line_in_progress = true
	var max_pos_of_tempo_change: int = 0
	for i in line_tempo_changes.keys(): if i > max_pos_of_tempo_change:
		max_pos_of_tempo_change = i
	if line_tempo_changes.has(max_pos_of_tempo_change):
		current_tempo = line_tempo_changes[max_pos_of_tempo_change]
	while current_line_text.is_empty() and abs(current_line) < dialog_lines.size():
		current_line += 1
		if abs(current_line) < dialog_lines.size(): current_line_text = _parse_line(dialog_lines[current_line])
	if ( # dialog completed or the last line of the dialog is empty
		current_line >= dialog_lines.size()
		or(current_line == dialog_lines.size() - 1 and dialog_lines[current_line].strip_edges() == "")
	):
		dialogue_in_progress = false
		finish()

@onready var dialogue_in_progress: bool = false
@onready var line_in_progress: bool = false
var current_letter: int = 0
var current_line: int = 0
var current_line_text: String = ""
var current_tempo: float = seconds_per_letter
var delay_remaining: float = 0.0
func _process(delta: float) -> void:
	if not dialogue_in_progress: return

	# decide to even do anything or not based on the actual delay and line progress
	delay_remaining -= delta / Difficulty.gameplay_speed

	if(not line_in_progress or delay_remaining > 0. or abs(current_line) >= dialog_lines.size()):
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
		line_in_progress = false
		continue_panel.set_visible(true)
	else: delay_remaining = current_tempo
