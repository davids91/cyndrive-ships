class_name BaseBattle
extends Node2D

@export var god_mode_active: bool = false
@export var infinite_ammo_active: bool = false
@export var infinite_boost_active: bool = false

@export var GUI: BattleShipGUI
@export var gui_visible: bool = true
@export var spawn_position: Vector2 = Vector2()
@export var spawn_radius: float = 500
@export var respawn_time: float = 1.

@onready var player_input: PlayerInput = get_node("/root/Main/player_input")

func create_new_puppet(predecessor: BattleCharacter) -> void:
	var records = predecessor.get_node("temporal_recorder").stop_recording()
	var puppet =  preload("res://scenes/entities/base_ship.tscn").instantiate();
	var replayer = Node2D.new()
	puppet.init_clone(predecessor, Color.from_rgba8(29, 191, 0, 104))
	replayer.set_script(preload("res://scripts/battle/temporal_replayer.gd"))
	replayer.name = "replayer"
	replayer.usec_records = records["action"]
	replayer.msec_records = records["temporal_snapshots"]
	$timeline.connect("round_reset", puppet.respawn)
	$timeline.connect("rewind_started", puppet.pause_control)
	$timeline.connect("rewind_stopped", puppet.resume_control)
	replayer.reset()
	puppet.add_child(replayer, true)
	puppet.dead.connect(_on_battle_character_dead)
	puppet.resurrected.connect(_on_battle_character_resurrected)

	# set new spawn position for the predecessor
	predecessor.spawn_snapshot["transform"].origin = (
		spawn_position + (predecessor.get_global_position() - spawn_position).normalized() * spawn_radius
	)

	# Add the new puppet to battle
	$combatants.add_child(puppet)
	predecessor.get_node("temporal_recorder").start_recording()

func entangle_ship_with_player(ship: BattleCharacter) -> void:
	if ship.has_node("replayer") or ship.name == "character": return # Nothing to do when ship is already entangled
	var records = ship.get_node("temporal_recorder").stop_recording()
	var replayer = Node2D.new()
	replayer.set_script(preload("res://scripts/battle/temporal_replayer.gd"))
	replayer.name = "replayer"
	replayer.usec_records = records["action"]
	replayer.msec_records = records["temporal_snapshots"]
	replayer.temporal_scope_changed.connect(ship._on_replayer_temporal_scope_changed)
	$timeline.connect("round_reset", replayer.reset)
	$timeline.connect("round_reset", replayer.start_replay)
	replayer.reset()
	ship.add_child(replayer)
	if ship.has_node("ai_control"):
		ship.get_node("ai_control").set_disabled(true)

func reset_game() -> void:
	for explosion in $mush.get_children():
		explosion.queue_free()
	get_tree().call_deferred("reload_current_scene")

func view_control_triggered(_action: Dictionary) -> void: pass
func replay_game() -> void: pass
func replay_round(rewind_animation: bool = true) -> void:
	#TechDebt: Eliminate mine after round end
	if not $combatants/character.held_mine == null:
		$combatants/character.held_mine.queue_free()

	# Stop the fighting
	for combatant in $combatants.get_children():
		if "pause_control" in combatant:
			combatant.pause_control()

	# Create a clone of the ship
	create_new_puppet($combatants/character)

	# Handle temporal entanglement for affected ships
	for c in $combatants.get_children():
		if(
			"entangled" in c and c.entangled and not c.has_node("replayer")
			and "team" in c and c.team.is_enemy($combatants/character.team)
		): entangle_ship_with_player(c)

	if not rewind_animation:
		for combatant in $combatants.get_children():
			if "pause_control" in combatant:
				combatant.resume_control()
		$timeline.reset()
		queue_redraw()
		GUI.get_node("defeat").set_visible(false)
		GUI.get_node("victory").set_visible(false)
		GUI.get_node("restart_round_panel").set_visible(false)
		return

	# Set up UI for the new round
	GUI.get_node("rewind_effects").set_visible(true)

	# Move the player to its spawn position
	var player_move_tween: Tween = create_tween()
	player_move_tween.tween_method(
		func(pos):
			$combatants/character.set_global_position(pos)
			GUI.get_node("rewind_effects").material.set_shader_parameter(
				"rewind_amount",
				-(pos - $combatants/character.spawn_snapshot["transform"].origin).length() / 500.
			),
		$combatants/character.get_global_position(),
		$combatants/character.spawn_snapshot["transform"].origin,
		respawn_time
	)
	player_move_tween.tween_callback(func():
		for combatant in $combatants.get_children():
			if "pause_control" in combatant:
				combatant.resume_control()
		GUI.get_node("rewind_effects").set_visible(false)
		$timeline.reset()
		queue_redraw()
		GUI.get_node("defeat").set_visible(false)
		GUI.get_node("victory").set_visible(false)
		GUI.get_node("restart_round_panel").set_visible(false)
	)

func time_control_triggered(action: Dictionary) -> void:
	if "slowdown" in action:
		Difficuilty.slowdown_multiplier = action["slowdown"]

	if "rewind_toggled" in action:
		if action["rewind_toggled"]: $timeline.start_reverse()
		else: $timeline.finish_reverse()

	if "checkpoint_reset_triggered" in action and action["checkpoint_reset_triggered"]:
		replay_round()

func _ready() -> void:
	for combatant in $combatants.get_children():
		$timeline.connect("round_reset", combatant.respawn)
		$timeline.connect("rewind_started", combatant.pause_control)
		$timeline.connect("rewind_stopped", combatant.resume_control)
		combatant.dead.connect(_on_battle_character_dead)
		combatant.resurrected.connect(_on_battle_character_resurrected)

	for debris in $debris.get_children(): if debris.has_method("respawn"):
		$timeline.connect("round_reset", debris.respawn)
	$combatants/player_carrier.phase_in()

func _on_battle_character_resurrected(_character: BattleCharacter) -> void: pass
func _on_battle_character_dead(_character: BattleCharacter) -> void: pass
