class_name ExplosiveMine extends BattleDebris

const EXPLOSION_FIREY = preload("res://scenes/effects/explosion-firey.tscn")

@export var mine_drag_strength: float = 50.
@export var mine_drag_length: float = 25.
@export var fault_chance: float = 0.005

@onready var level = get_tree().current_scene
var is_activated: bool = false
var mount_offset: Vector2 = Vector2(-3., 0.)
var attached_position: Vector2

func _ready() -> void:
	$collide_to_activate.disabled = true

func _process(_delta: float) -> void:
	$chain.points[0] = get_global_position()
	if not null == attached_to: $chain.points[1] = attached_to.get_global_position()
	else: $chain.points[1] = get_global_position()

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

var explosion: ShipExplosion = null
func explode_mine() -> void:
	if null == explosion:
		explosion = EXPLOSION_FIREY.instantiate()
		explosion.explosion_damage = 15.
		explosion.explosion_length = 3.
		explosion.explosion_strength = 3000.
		explosion.explosion_range = 600.
		level.get_node("mush").add_child(explosion)
	explosion.global_position = get_global_position()
	explosion.reinit()
	explosion.scale = Vector2(3,3)
	await get_tree().create_timer(.2).timeout #give lightning time to draw
	queue_free()

func accept_damage(_strength: float, _source: BattleCharacter = null) -> void:
	if is_activated: explode_mine()

func run_deployed_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), .5)
	tween.tween_property(self, "scale", Vector2(1, 1), .5)
	tween.set_loops(0)

func deploy_mine(activation_delay_msec : float = 0.0) -> void:
	var delay_tween = create_tween()
	delay_tween.tween_interval(activation_delay_msec)
	delay_tween.tween_callback(
		func():
			$collide_to_activate.disabled = false
			run_deployed_tween()
			is_activated = fault_chance < randf()
			attached_to = null
	)

var attached_to: BattleCharacter = null
func attach_mine(ship: BattleCharacter, attached_length: float = ship.approx_size) -> void:
	attached_to = ship
	mine_drag_length = attached_length
	set_global_position(ship.get_global_position() + mount_offset)
	
func _on_explode_radius_body_entered(body: Node2D) -> void:
	if body.has_node("team") and is_activated:
		var body_team_id = body.get("team_id")
		if body_team_id != 1:
			explode_mine()
