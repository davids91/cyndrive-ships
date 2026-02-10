extends BattleShipWeapon

@export var shutdown_time: float = 0.2
@export var startup_time: float = 0.05
@export var handle_speed: float = 0.6
@export var handle_radius: float = 150.
@export var chain_length: float = 25.
@export var grab_length_sec: float = 0.5

@onready var wielder: BattleCharacter = get_parent()

var display_points: Array[Vector2] = []
func _ready() -> void:
	for c in get_children(): if not c is Line2D:
		display_points.push_back(c.get_global_position())

var was_shooting: bool = false
var ships_hurting: Dictionary = {}
var handle_pos: Vector2 = Vector2()
var grabbing_end_until_sec: float = 0.
func _process(delta: float) -> void:
	# Handle hotsaber damage
	if is_shooting: for ship in ships_hurting:
		if ship.has_method("accept_damage"): ship.accept_damage(base_damage * delta)

	# Hotsaber control
	$stem.pos_to_set = wielder.get_global_position()
	$stem.pos_over_time_sec = startup_time
	if 0. < grabbing_end_until_sec:
		grabbing_end_until_sec -= delta
		$end.pos_to_set = wielder.get_global_position() + handle_pos
		$end.pos_over_time_sec = startup_time

	# Handle hotsaber display
	var i: int = 0
	for c in get_children(): if not c is Line2D:
		display_points[i] = c.get_global_position()
		i += 1
	var smooth_points = catmull_rom_spline(display_points)
	$outer_line.points = smooth_points
	$inner_line.points = smooth_points
	
	# Add after-effect of hotsabers
	if is_shooting:
		var after_image = [$outer_line.duplicate(), $inner_line.duplicate()]
		var disappear_tween = create_tween()
		disappear_tween.set_parallel(true)
		for line in after_image:
			line.points = line.points.duplicate()
			line.set_visible(true)
			add_child(line)
			var modulate_to_set = line.self_modulate
			modulate_to_set.a = 0.
			disappear_tween.tween_property(line, "self_modulate", modulate_to_set, shutdown_time)
		disappear_tween.chain().tween_callback(func(): for line in after_image: line.queue_free())

func process_input_action(action: Dictionary) -> void:
	was_shooting = is_shooting
	var shoot_intent = is_shooting
	if "action_direction" in action:
		shoot_intent = 0. < action["action_direction"].length()
		if shoot_intent:
			handle_pos = lerp(handle_pos, action["action_direction"] * handle_radius, handle_speed)
		if not was_shooting: grabbing_end_until_sec = grab_length_sec
	if not shoot_intent and was_shooting:
		shutdown()

	if shoot_intent and not was_shooting:
		var sweep_tween = create_tween()
		sweep_tween.set_parallel(true)
		var handle_len_multiplier: float = 0.
		for c in get_children(): if not c is Line2D:
			c.pos_to_set = wielder.get_global_position() +  handle_pos.normalized() * handle_len_multiplier * chain_length
			c.pos_over_time_sec = startup_time
			handle_len_multiplier += 1.
		sweep_tween.chain().tween_callback(func():
			for c in get_children(): 
				if c is Line2D: c.set_visible(true)
				else: c.get_node("collision_shape").set_deferred("disabled", false)
		)
		is_shooting = true

func shutdown() -> void:
	for c in get_children(): if not c is Line2D:
		c.pos_to_set = wielder.get_global_position()
		c.pos_over_time_sec = shutdown_time
	var shutdown_tween = create_tween()
	shutdown_tween.tween_interval(shutdown_time)
	shutdown_tween.tween_callback(func():
		for c in get_children(): 
			if c is Line2D: c.set_visible(false)
			else: c.get_node("collision_shape").set_deferred("disabled", true)
		is_shooting = false
	)
	shutdown_tween.chain()
	
## https://gist.github.com/JoelBesada/8cb4508dfbcd4e23f639476fd89b1952
## https://www.reddit.com/r/godot/comments/1dlfve1/how_to_make_a_smooth_physicsbased_rope_in_godot_4/
func catmull_rom_spline(
	_points: Array, resolution: int = 10, extrapolate_end_points = true
) -> PackedVector2Array:
	var points = _points.duplicate()
	if extrapolate_end_points:
		points.insert(0, points[0] - (points[1] - points[0]))
		points.append(points[-1] + (points[-1] - points[-2]))

	var smooth_points := PackedVector2Array()
	if points.size() < 4:
		return points

	for i in range(1, points.size() - 2):
		var p0 = points[i - 1]
		var p1 = points[i]
		var p2 = points[i + 1]
		var p3 = points[i + 2]

		for t in range(0, resolution):
			var tt = t / float(resolution)
			var tt2 = tt * tt
			var tt3 = tt2 * tt

			var q = (
				0.5
				* (
				  (2.0 * p1)
				  + (-p0 + p2) * tt
				  + (2.0 * p0 - 5.0 * p1 + 4 * p2 - p3) * tt2
				  + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * tt3
				)
			)
			smooth_points.append(q)
	return smooth_points

func _on_hurt_aura_body_entered(body: Node2D) -> void:
	if(
		not wielder.has_node("team")
		or not body.has_node("team")
		or get_parent().get_node("team").is_enemy(body.get_node("team"))
	): ships_hurting[body] = BattleTimeline.instance.time_msec()

func _on_hurt_aura_body_exited(body: Node2D) -> void:
	if ships_hurting.has(body): ships_hurting.erase(body)
