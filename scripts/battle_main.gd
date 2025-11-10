extends Node2D

@onready var character_template = preload("res://scenes/character.tscn")

var combatants = [] # Every object taking part of the battle
var ships = [] # Not including control characters
var ship_moves = []

var sonar_visible = false
var sonar_speed = 0.
var sonar_slow_speed = 0.


var init_countdown = 4.
func _ready():
	$character.init_control_character()
	$enemy.init_control_character()
	combatants.push_back($character)
	combatants.push_back($enemy)
	$character/controller.move_to_spawn_pos()
	$enemy/controller.move_to_spawn_pos()
	$character.accepts_input(false)
	sonar_speed = $sonar_sensor.rotation_speed
	sonar_slow_speed = $sonar_sensor.rotation_speed / 4.
	$enemy/ai_control.enabled = false
	
func _process(delta):
	if 0 < init_countdown:
		init_countdown -= delta
		$GUI/score.set_text("%0.3f" % init_countdown)
		if 0 >= init_countdown:
			$character.accepts_input(true)
			$character/move_recorder.start_recording()
			$enemy/move_recorder.start_recording()
			$enemy/ai_control.enabled = true
		return
	
	var counts = Dictionary()
	counts[1] = 0
	counts[2] = 0
	for c in combatants:
		if c.is_alive():
			counts[c.get_node("team").team_id] += 1
	$GUI/score.set_text(str(counts[1], " vs ", counts[2]))
	$target_assist.set_position(get_global_mouse_position())
	$GUI/sonar_display.set_display_visibility(sonar_visible)
	if $sonar_sensor.direct_control:
		var direction = (get_global_mouse_position() - $character.get_global_position()).normalized()
		$sonar_sensor.set_manual_rotation(direction.angle())
	
func create_new_puppet(predecessor):
	var records = predecessor.get_node("move_recorder").stop_recording()
	var puppet = character_template.instantiate();
	puppet.init_clone(predecessor)
	var replayer = Node2D.new()
	replayer.set_script(preload("res://scripts/replayable.gd"))
	replayer.name = "replayer"
	replayer.start_time_usec = Time.get_ticks_usec()
	replayer.correction_interval_sec = 0.5
	replayer.actions = records["actions"]
	replayer.transforms = records["transforms"]
	puppet.add_child(replayer, true)
	
	add_child(puppet)
	ships.push_back(puppet)
	combatants.push_back(puppet)
	ship_moves.push_back(records) 
	predecessor.get_node("move_recorder").start_recording()

func _unhandled_input(event):
	var just_pressed = event.is_pressed() and not event.is_echo()
	if event.is_action_pressed("radar") and just_pressed:
		$sonar_sensor.rotation_speed = sonar_speed
		sonar_visible = true
	elif event.is_action_pressed("radar-slow") and just_pressed:
		$sonar_sensor.rotation_speed = sonar_slow_speed
		sonar_visible = true
		
	elif event.is_action_pressed("radar-control"):
		$sonar_sensor.direct_control = true
		sonar_visible = true

	if event.is_action_released("radar"):
		sonar_visible = false	

	if event.is_action_released("radar-slow"):
		sonar_visible = false

	if event.is_action_released("radar-control"):
		sonar_visible = false
		$sonar_sensor.direct_control = false
		
	if event.is_action_pressed("replay"):
		# assign the recorded moves to puppets
		create_new_puppet($character)
		create_new_puppet($enemy)

		# reset battleground
		$character.respawn()
		$enemy.respawn()
		for i in ship_moves.size():
			ships[i].respawn()
			if ships[i].has_node("replayer"):
				ships[i].get_node("replayer").reset()
