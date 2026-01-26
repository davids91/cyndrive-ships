extends BattleShipWeapon

class ChainHit:
	var from_pos: Vector2
	var to_pos: Vector2
	var victim: Node2D
	var damage: float

	func _init(from: Vector2, to: Vector2, target: Node2D, dmg: float):
		from_pos = from
		to_pos = to
		victim = target
		damage = dmg

class ChainSegment:
	var from_node: Node2D
	var to_node: Node2D
	var seed_value: int
	var cached_from: Vector2
	var cached_to: Vector2

	func _init(from: Node2D, to: Node2D, seed_val: int):
		from_node = from
		to_node = to
		seed_value = seed_val
		cached_from = Vector2.ZERO
		cached_to = Vector2.ZERO

@export var wielder: BattleCharacter
@export var chain_radius: float = 300.0
@export var max_bounces: int = 4
@export_range(0.0, 1.0) var damage_falloff: float = 0.75  # 25% reduction per jump

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var target_position: Vector2 = Vector2()

var beam_lines: Array[Line2D] = []
var active_chain: Array[ChainSegment] = []

func _ready() -> void:
	for i in range(max_bounces + 1):
		var line = Line2D.new()
		line.name = "chain_segment_%d" % i
		line.top_level = true
		line.width = 0.0
		line.default_color = Color(0.6, 0.9, 1.0, 1.0)  # Electric blue
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
		add_child(line)
		beam_lines.append(line)

func process_input_action(action: Dictionary) -> void:
	if "pewpew_target" in action and null != action["pewpew_target"] and wielder != action["pewpew_target"]:
		target_position = action["pewpew_target"].get_global_position()
		is_shooting = true

func _physics_process(_delta: float) -> void:
	if active_chain.is_empty() and $sound.playing: $sound.stop()
	else: for i in range(active_chain.size()):
		if i >= beam_lines.size():
			break
		var beam_line = beam_lines[i]
		if beam_line.width <= 0 or beam_line.points.size() < 2:
			continue

		if not is_instance_valid(active_chain[i].from_node) or not is_instance_valid(active_chain[i].to_node):
			continue

		var segment = active_chain[i]
		var from_pos = _get_segment_position(segment.from_node, beam_line.points[0])
		var to_pos = _get_segment_position(segment.to_node, beam_line.points[beam_line.points.size() - 1])

		if from_pos != segment.cached_from or to_pos != segment.cached_to:
			segment.cached_from = from_pos
			segment.cached_to = to_pos
			beam_line.points = _generate_jagged_path(from_pos, to_pos, segment.seed_value)

	if not is_shooting:
		return

	is_shooting = false
	var chain_targets = _execute_chain_attack()
	_animate_chain(chain_targets)
	$sound.play(randf() * 5.)

func _get_segment_position(node: Node2D, fallback: Vector2) -> Vector2:
	if node != null and is_instance_valid(node):
		return node.get_global_position()
	return fallback

func _execute_chain_attack() -> Array[Dictionary]:
	"""Execute the chain lightning attack and return hit data for visualization."""
	var chain_hits: Array[Dictionary] = []
	var current_pos = get_global_position()
	var already_hit: Array = []
	var current_damage = base_damage
	var space_state = get_world_2d().direct_space_state

	var first_hit = _perform_first_hit(space_state, current_pos)
	chain_hits.append(first_hit)
	if first_hit["victim"] == null:
		return chain_hits

	already_hit.append(first_hit["victim"])
	current_pos = first_hit["to"]

	for _bounce in range(max_bounces):
		current_damage *= damage_falloff
		var bounce_hit = _perform_chain_bounce(space_state, current_pos, already_hit, current_damage)
		if bounce_hit.is_empty():
			break
		chain_hits.append(bounce_hit)
		already_hit.append(bounce_hit["victim"])
		current_pos = bounce_hit["to"]

	return chain_hits

func _perform_first_hit(space_state: PhysicsDirectSpaceState2D, current_pos: Vector2) -> Dictionary:
	"""Raycast to target position and apply damage if hit."""
	var result = _raycast_to_position(space_state, current_pos, target_position)
	if result.is_empty() or not result.has("collider"):
		return {"from": current_pos, "to": target_position, "victim": null, "damage": 0}

	var victim = result["collider"]
	if victim != wielder and victim.has_method("accept_damage"):
		victim.accept_damage(base_damage, wielder)
	

	return {"from": current_pos, "to": result["position"], "victim": victim, "damage": base_damage}

func _perform_chain_bounce(space_state: PhysicsDirectSpaceState2D, current_pos: Vector2,
		already_hit: Array, current_damage: float) -> Dictionary:
	"""Find and hit next chain target. Returns empty dict if chain ends."""
	var next_target = _find_next_chain_target(current_pos, already_hit)
	if next_target == null:
		return {}

	var raycast_result = _raycast_to_position(space_state, current_pos,
			next_target.get_global_position(), already_hit)
	if raycast_result.is_empty() or raycast_result.get("collider") != next_target:
		return {}

	next_target.accept_damage(current_damage, wielder)
	return {
		"from": current_pos,
		"to": raycast_result["position"],
		"victim": next_target,
		"damage": current_damage
	}

func _raycast_to_position(space_state: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2, exclude: Array = []) -> Dictionary:
	"""Perform raycast from one position toward another, excluding specified objects."""
	var direction = (to - from).normalized()
	var extended_to = from + direction * 5000.0

	var query = PhysicsRayQueryParameters2D.create(from, extended_to)	
	var exclude_rids: Array[RID] = []
	for obj in exclude:
		if obj is CollisionObject2D:
			exclude_rids.append(obj.get_rid())
	query.exclude = exclude_rids

	return space_state.intersect_ray(query)

func _is_valid_chain_target(combatant: Node2D, exclude: Array, my_team: Node) -> bool:
	"""Check if a combatant is a valid chain lightning target."""
	if not combatant.has_method("accept_damage"):
		return false
	if combatant in exclude:
		return false
	if combatant.has_method("in_battle") and not combatant.in_battle():
		return false
	if my_team != null and combatant.has_node("team"):
		if not combatant.get_node("team").is_enemy(my_team):
			return false	
	return true

func _find_next_chain_target(from_pos: Vector2, exclude: Array) -> Node2D:
	"""Find the nearest valid chain target within radius."""
	var my_team = wielder.get_node("team") if wielder.has_node("team") else null
	var candidates: Array[Dictionary] = []

	for combatant in get_tree().get_nodes_in_group("combatants"):
		if not _is_valid_chain_target(combatant, exclude, my_team):
			continue

		var distance = from_pos.distance_to(combatant.get_global_position())
		if distance > chain_radius:
			continue

		candidates.append({
			"target": combatant,
			"distance": distance		
		})	
	if candidates.is_empty():
		return null

	candidates.sort_custom(func(a, b): return a["distance"] < b["distance"])  # Deterministic for replay
	return candidates[0]["target"]

func _animate_chain(chain_hits: Array[Dictionary]) -> void:
	"""Animate the chain lightning visual effect."""
	for beam_line in beam_lines:
		beam_line.width = 0.0
		beam_line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])

	var prev_victim: Node2D = null
	for i in range(chain_hits.size()):
		if i >= beam_lines.size():
			break

		var hit = chain_hits[i]
		var beam_line = beam_lines[i]

		var from_node: Node2D = self if i == 0 else prev_victim
		var to_node: Node2D = hit["victim"]
		var segment_seed = i * 1000 + int(BattleTimeline.instance.time_msec()) % 10000

		var segment = ChainSegment.new(from_node, to_node, segment_seed)
		segment.cached_from = hit["from"]
		segment.cached_to = hit["to"]
		active_chain.append(segment)

		beam_line.points = _generate_jagged_path(hit["from"], hit["to"], segment_seed)
		prev_victim = to_node

		var tween = create_tween()
		tween.tween_property(beam_line, "width", 15, 0.03)
		tween.tween_property(beam_line, "width", 0, 0.12)
		tween.tween_callback(func(): active_chain.pop_back())

func _generate_jagged_path(from: Vector2, to: Vector2, path_seed: int = -1) -> PackedVector2Array:
	"""Generate a jagged lightning path using midpoint displacement."""
	var points: PackedVector2Array = PackedVector2Array()
	points.append(from)

	var seed_value = path_seed if path_seed >= 0 else int(from.x + from.y * 1000 + to.x * 100 + to.y)
	_rng.seed = seed_value

	var segments = 6
	var direction = to - from
	var perpendicular = direction.normalized().rotated(PI / 2)

	for i in range(1, segments):
		var base_point = from + direction * (float(i) / segments)
		var displacement = perpendicular * _rng.randf_range(-30, 30)
		points.append(base_point + displacement)

	points.append(to)
	return points
