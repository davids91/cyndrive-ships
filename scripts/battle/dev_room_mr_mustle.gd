extends Node2D

var god_mode_active: bool = false
var infinite_ammo_active: bool = false
var infinite_boost_active: bool = false


@export var gui_visible: bool = true
@export var spawn_position: Vector2 = Vector2()
@export var spawn_radius: float = 500

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
	#puppet.dead.connect(_on_battle_character_dead)
	#puppet.resurrected.connect(_on_battle_character_resurrected)

	# set new spawn position for the predecessor
	predecessor.spawn_snapshot["transform"].origin = (
		spawn_position + (predecessor.get_global_position() - spawn_position).normalized() * spawn_radius
	)

	# Add the new puppet to battle
	$combatants.add_child(puppet)
	predecessor.get_node("temporal_recorder").start_recording()

 # Dummy functions as there is no time travel here yet
func time_control_triggered() -> void: pass
func replay_game() -> void: pass
func reset_game() -> void: pass
func replay_round() -> void: pass

func _on_character_dead(_itsme: BattleCharacter) -> void:
	create_new_puppet($combatants/character)
	$timeline.reset()
