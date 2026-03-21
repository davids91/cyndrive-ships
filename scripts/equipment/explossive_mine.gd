class_name ExplosiveMine extends BattleDebris

const EXPLOSION_FIREY = preload("res://scenes/effects/explosion-firey.tscn")

@export var mine_drag_strength: float = 50.
@export var mine_drag_length: float = 25.
@export var fault_chance: float = 0.005
@export var seeking_speed: float = 2000.
@export var seeking_warmup_msec: float = 5000.
@export var seek_responsiveness: float = 0.75

# Mines are seeking any team they are not assigned to
@export var team: Team = preload("res://resources/player_team.tres")

@onready var level = get_node("/root/Main/LevelContainer/battle")

var is_activated: bool = false
var is_exploded: bool = false
var mount_offset: Vector2 = Vector2(-3., 0.)
var attached_to: BattleCharacter = null

# Overwrites function from BattleDebris
func get_snapshot() -> Dictionary:
	var snapshot = super()
	snapshot["is_activated"] = is_activated
	snapshot["is_exploded"] = is_exploded
	snapshot["attached_to"] = attached_to
	return snapshot

# Overwrites function from BattleDebris
func correct_temporal_state(snapshot: Dictionary, over_time_msec: float = 0.001) -> void:
	if "is_activated" in snapshot:
		is_activated = snapshot["is_activated"]
		$collide_to_activate.disabled = not is_activated
	if "is_exploded" in snapshot: is_exploded = snapshot["is_exploded"]
	if "attached_to" in snapshot:
		if ( # The mine should belong to the object in the snapshot
			snapshot["attached_to"] and "held_mine" in snapshot["attached_to"]
			and not snapshot["attached_to"].held_mine
		): attached_to = snapshot["attached_to"]
		if snapshot["attached_to"] and not attached_to: # Couldn't re-attach mine to the ship it used to belong to, bye!
			create_tween().tween_method(func(w: float): $skin.set_burn_percentage(w), 0., 1., 0.5).finished.connect(
				func(): queue_free()
			)
	super(snapshot, over_time_msec)

# Overwrites function from BattleDebris
func in_battle() -> bool:
	return super() and not is_exploded

var seek_velocity: Vector2 = Vector2.ZERO
func _process(delta: float) -> void:
	super(delta)
	$chain.points[0] = get_global_position()
	if not null == attached_to:
		is_activated = false # TechDebt: Mine shouldn't be active when attached to a ship!
		$chain.points[1] = attached_to.get_global_position()
	else: $chain.points[1] = get_global_position()

	if is_activated and not is_exploded: # Mine is deployed!
		# Check for any ships to seek out
		var to_ship: Vector2
		var seeking_since_msec: float = 0.
		for ship in enemies_to_seek:
			var to_ship_: Vector2 = (ship.global_position - global_position)
			if not to_ship or to_ship.length() > to_ship_.length():
				seeking_since_msec = BattleTimeline.instance.time_since_msec(enemies_to_seek[ship])
				to_ship = to_ship_
		if to_ship: seek_velocity = lerp(
			linear_velocity,
			to_ship.normalized() * seeking_speed * clamp(seeking_since_msec / seeking_warmup_msec, 0., 1.),
			seek_responsiveness
		)

		# Check for any friendly ships to attach back to
		for ship in friendlies_in_proximity:
			if (
				"held_mine" in ship and not ship.held_mine
				and "ready_to_receive_mine" in ship and ship.ready_to_receive_mine
			):
				attached_to = ship
				ship.held_mine = self

	# Check for any ships in explosion proximity
	if is_activated and not enemies_in_proximity.is_empty(): explode_mine()

func _physics_process(_delta: float) -> void:
	# Handle dragging the attached mine behind ship
	if not null == attached_to:
		# Calculate the direction the mine should be dragged, including the velocity of the mine
		var mine_pull_vector = (
			attached_to.get_global_position() + mount_offset.rotated(attached_to.get_global_rotation())
			- (get_global_position() + get_linear_velocity() * 0.1)
		)
		# Cut the pull strength in case the mine is close to the ship
		var mine_pull_near_coeff = min(mine_drag_length, mine_pull_vector.length()) * smoothstep(0., mine_drag_length, mine_pull_vector.length())

		# Amplify the pull strength if the mine is far away from the ship
		var mine_pull_far_coeff = smoothstep(mine_drag_length, 0., mine_pull_vector.length())
		mine_pull_vector = mine_pull_vector.normalized() * mine_pull_near_coeff / max(0.1, mine_pull_far_coeff)

		# Only apply any force if the mine os far away
		if mine_pull_vector.length() > mine_drag_length:
			apply_impulse(mine_pull_vector)

var explosion: Explosion = null
func explode_mine() -> void:
	if null == explosion:
		explosion = EXPLOSION_FIREY.instantiate()
		explosion.explosion_damage = 15.
		explosion.explosion_length = 3.
		explosion.explosion_strength = 500.
		explosion.explosion_range = 600.
		explosion.scale *= 3
		level.get_node("mush").add_child(explosion)
	explosion.global_position = get_global_position()
	explosion.reinit()
	is_exploded = true
	correct_temporal_state({"linear_velocity": Vector2.ZERO})
	await get_tree().create_timer(.2).timeout # give lightning time to draw

func accept_damage(_strength: float, _source: Node = null) -> void:
	if is_activated: explode_mine()

func deploy_mine(activation_delay_msec : float = 0.0) -> void:
	create_tween().tween_callback(
		func():
			is_activated = true
			attached_to = null
			$collide_to_activate.disabled = false
			var pulsating_tween: Tween = create_tween()
			pulsating_tween.tween_property($skin, "scale", Vector2(1.3, 1.3), .5)
			pulsating_tween.tween_property($skin, "scale", Vector2(1, 1), .5)
			pulsating_tween.set_loops(0)
	).set_delay(activation_delay_msec)

func spawn_mine_attached_to(ship: BattleCharacter, attached_length: float = ship.approx_size) -> void:
	attached_to = ship
	mine_drag_length = attached_length
	$temporal_recorder.start_recording()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	super(state)
	if is_exploded: state.linear_velocity = Vector2.ZERO
	elif 0.1 < seek_velocity.length():
		state.linear_velocity = lerp(state.linear_velocity, seek_velocity, seek_responsiveness)

var friendlies_in_proximity: Dictionary[Node2D, float] = {}
var enemies_in_proximity: Dictionary[Node2D, float] = {}
func _on_explode_radius_body_entered(body: Node2D) -> void:
	if "team" in body and team.is_enemy(body.team):
		enemies_in_proximity[body] = BattleTimeline.instance.time_msec()
	elif "team" in body and not team.is_enemy(body.team):
		friendlies_in_proximity[body] = BattleTimeline.instance.time_msec()

func _on_explode_radius_body_exited(body: Node2D) -> void:
	if enemies_in_proximity.has(body): enemies_in_proximity.erase(body)
	if friendlies_in_proximity.has(body): friendlies_in_proximity.erase(body)

var enemies_to_seek: Dictionary[Node2D, float] = {}
func _on_seeking_aura_body_entered(body: Node2D) -> void:
	if "team" in body and team.is_enemy(body.team):
		enemies_to_seek[body] = BattleTimeline.instance.time_msec()

func _on_seeking_aura_body_exited(body: Node2D) -> void:
	if enemies_to_seek.has(body): enemies_to_seek.erase(body)
