extends BattleShipWeapon

@export var startup_time: float = 0.05
@export var handle_speed: float = 0.6
@export var chain_length: float = 70.
@export var swing_arc_width_rad: float = PI / 2.
@export var swing_time: float = 0.2
@export var wielder: BattleCharacter
@export var offset: Vector2 = Vector2.ZERO

var display_points: Array[Vector2] = []
func _ready() -> void:
	if not wielder: wielder = get_parent()
	for c in get_children(): if not c is Line2D:
		display_points.push_back(c.get_global_position() + c.get_node("pin").get_position())

func _physics_process(delta: float) -> void:
	# Hotsaber control
	$stem.pos_to_set = get_stem_position()
	$stem.pos_over_time_sec = delta

func _process(_delta: float) -> void:
	# Handle hotsaber display
	var i: int = 0
	for c in get_children(): if not c is Line2D:
		display_points[i] = c.get_global_position() + c.get_node("pin").get_position()
		i += 1
	var smooth_points = catmull_rom_spline(display_points)
	$outer_line.points = smooth_points
	$inner_line.points = smooth_points
	
	## Add after-effect of hotsabers
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
			disappear_tween.tween_property(line, "self_modulate", modulate_to_set, startup_time * 3.)
		disappear_tween.chain().tween_callback(func(): for line in after_image: line.queue_free())

func get_stem_position() -> Vector2:
	return wielder.get_global_position() + offset.rotated(wielder.get_global_rotation())

var was_shooting: bool = false
var last_shot: Vector2 = Vector2()
func process_input_action(action: Dictionary) -> void:
	was_shooting = is_shooting
	if "action_direction" in action:
		is_shooting = 0. < action["action_direction"].length()
		if is_shooting and action["action_direction"] != last_shot: was_shooting = false
		last_shot = action["action_direction"]

	if not is_shooting and was_shooting:
		shutdown()
	if is_shooting and not was_shooting:
		var handle_len_multiplier: float = 0.
		for c in get_children(): if not c is Line2D:
			c.pos_to_set = wielder.get_global_position() + action["action_direction"] * handle_len_multiplier * chain_length
			c.pos_over_time_sec = startup_time
			handle_len_multiplier += 1.
		var sweep_tween = create_tween()
		sweep_tween.tween_callback(func():
			for c in get_children(): 
				if c is Line2D: c.set_visible(true)
				else: c.get_node("collision_shape").set_deferred("disabled", false)
		).set_delay(startup_time)
		var start_angle: float = action["action_direction"].angle() - swing_arc_width_rad
		sweep_tween.tween_method(
			func(w: float):
				$chain3.pos_to_set = (
					wielder.get_global_position()
					+ Vector2(cos(start_angle + w), sin(start_angle + w)) * float(display_points.size()) * chain_length
				)
				$chain3.pos_over_time_sec = startup_time,
			0., swing_arc_width_rad, swing_time
		).set_ease(Tween.EASE_IN_OUT)

func shutdown() -> void:
	for c in get_children(): if not c is Line2D:
		c.pos_to_set = wielder.get_global_position()
		c.pos_over_time_sec = swing_time
	var shutdown_tween = create_tween()
	shutdown_tween.tween_interval(swing_time)
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
