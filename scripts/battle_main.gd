extends Node2D

@onready var character_template = preload("res://scenes/character.tscn")

var sonar_visible = false
var sonar_speed = 0.
var sonar_slow_speed = 0.
var init_countdown = 2.

func _ready():
	$combatants/character.accepts_user_input(true)
	$combatants/character/controller.stop()
	sonar_speed = $sonar_sensor.rotation_speed
	sonar_slow_speed = $sonar_sensor.rotation_speed / 4.
	
	for combatant in $combatants.get_children():
		combatant.move_to_spawn_position()
		$timeline.connect("round_reset", combatant.respawn)
		$timeline.connect("rewind_started", combatant.pause_control)
		$timeline.connect("rewind_stopped", combatant.resume_control)

	for debris in $debris.get_children():
		$timeline.connect("round_reset", debris.respawn)
	
var reverse_hold_time = 0.
var reverse_being_held = false
var reverse_initiated = false
const short_reverse_hold_time_sec = 0.15 # How long to hold down the reverse action to start reversing time, instead of restarting the round

var debug_lines = []
func display_line(from: Vector2, to: Vector2, color: Color) -> void:
	debug_lines.push_back({"from": from, "to": to, "color": color})
	var erasure_tween = create_tween()
	erasure_tween.tween_interval(0.8)
	erasure_tween.tween_callback(func() : debug_lines.pop_front())
	erasure_tween.chain()
	queue_redraw()
	
func _draw() -> void:
	for line in debug_lines:
		draw_line(line.from, line.to, line.color, 3.0)

func _process(delta):
	# Countdown to battle start
	if 0 < init_countdown:
		init_countdown = max(init_countdown - delta, 0)
		$GUI/score.set_text("%0.3f" % init_countdown)
		if 0 >= init_countdown:
			for combatant in $combatants.get_children():
				combatant.resume_control()
			$timeline.reset()
		return
	
	# Team size label update
	var counts = Dictionary()
	counts[1] = 0
	counts[2] = 0
	for c in $combatants.get_children():
		if "is_alive" in c and c.is_alive():
			counts[c.get_node("team").team_id] += 1
	$GUI/score.set_text(str(counts[1], " vs ", counts[2]))
	$target_assist.set_position(get_global_mouse_position())
	$GUI/sonar_display.set_display_visibility(sonar_visible)
	if $sonar_sensor.direct_control:
		var direction = (get_global_mouse_position() - $combatants/character.get_global_position()).normalized()
		$sonar_sensor.set_manual_rotation(direction.angle())
	
	# Handling Timeline reverse
	if reverse_being_held:
		reverse_hold_time += delta
		if reverse_hold_time > short_reverse_hold_time_sec:
			$timeline.reverse(delta)
			$GUI/rewind_effects.material.set_shader_parameter("rewind_amount", BattleTimeline.instance.player_rewind_amount_sec)
	if reverse_initiated:
		if not reverse_being_held:
			# Short rewind press: assign the recorded moves to puppets and reset the battleground
			if reverse_hold_time <= short_reverse_hold_time_sec:
				create_new_puppet($combatants/character)
				$timeline.reset()
				debug_lines.clear()
				queue_redraw()
			else: 
				$timeline.finish_reverse()
			reverse_hold_time = 0.
			reverse_initiated = false

func create_new_puppet(predecessor):
	var records = predecessor.get_node("temporal_recorder").stop_recording()
	var puppet = character_template.instantiate();
	var replayer = Node2D.new()
	puppet.init_clone(predecessor)
	replayer.set_script(preload("res://scripts/temporal_replayer.gd"))
	replayer.name = "replayer"
	replayer.usec_records = records["actions"]
	replayer.msec_records = records["motion"]
	$timeline.connect("round_reset", puppet.respawn)
	$timeline.connect("rewind_started", puppet.pause_control)
	$timeline.connect("rewind_stopped", puppet.resume_control)
	$timeline.connect("round_reset", replayer.reset)
	$timeline.connect("round_reset", replayer.start_replay)
	replayer.reset()
	puppet.add_child(replayer, true)
	
	$combatants.add_child(puppet)
	predecessor.get_node("temporal_recorder").start_recording()

func _unhandled_input(event):
	var just_pressed = event.is_pressed() and not event.is_echo()

	if event.is_action_pressed("replay") and just_pressed:
		reverse_being_held = true
		$GUI/reverse_marker.visible = true
		$GUI/rewind_effects.visible = true
		$GUI/rewind_effects.material.set_shader_parameter("rewind_amount", BattleTimeline.instance.player_rewind_amount_sec + short_reverse_hold_time_sec)
		create_tween().tween_method(
			func(value): $GUI/rewind_effects.material.set_shader_parameter("rewind_intensity", value),
			0.0, 1.0, short_reverse_hold_time_sec
		)
	if event.is_action_released("replay"):
		reverse_being_held = false
		$GUI/reverse_marker.visible = false
		var rewind_over_tween = create_tween()
		rewind_over_tween.tween_method(
			func(value): $GUI/rewind_effects.material.set_shader_parameter("rewind_intensity", value),
			1.0, 0.0, short_reverse_hold_time_sec
		)
		rewind_over_tween.tween_callback(func () : $GUI/rewind_effects.visible = false)
		rewind_over_tween.chain()
	reverse_initiated = reverse_initiated or reverse_being_held

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
