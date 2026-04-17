extends BaseBattle

const character_template: PackedScene = preload("res://scenes/entities/base_ship.tscn")
const round_start_delay_sec: float = 2.

@export var starting_laupeerium: float = 25.
@export_range(0., 1.) var replay_screen_responsiveness: float = 0.05

@onready var laupeerium_bar: UIEnergyBar = get_node("/root/Main/GUI/%laupeerium_bar")

var init_countdown_sec: float = round_start_delay_sec
var current_laupeerium: float = starting_laupeerium
var living_team_members: Dictionary = {}

func _ready():
	super()
	spawn_position = $combatants/player_carrier.global_position
	GUI.fade_to(Color.from_rgba8(0, 255,255, 200))
	GUI.set_fade_radius(4.)
	_update_laupeerium_bar()
	$combatants/character/controller.stop()

	# Initial count of team members
	living_team_members[2] = 0
	living_team_members[1] = 0
	for combatant in $combatants.get_children():
		living_team_members[combatant.team.team_id] += 1

@export var rewind_battle_laupeerium_cost: float = 3.
@export var slowdown_battle_laupeerium_cost: float = 0.5
func replay_round(rewind_animation: bool = true) -> void:
	if current_laupeerium < rewind_battle_laupeerium_cost: return

	# Handle resource changes with round restart
	if not is_replay: current_laupeerium -= rewind_battle_laupeerium_cost
	_update_laupeerium_bar()
	super(rewind_animation)
	# TechDebt: Await respawn animation
	await get_tree().create_timer(respawn_time).timeout
	living_team_members[1] = 0
	living_team_members[2] = 0
	for c in $combatants.get_children():
		if "is_alive" in c and c.is_alive:
			living_team_members[c.team.team_id] += 1

var replay_viewport = Rect2()
func _process(delta):
	GUI.set_time(BattleTimeline.instance.time_msec() / 1000.)
	GUI.set_fade_radius(4. * Difficulty.slowdown_multiplier)

	# Countdown to battle start
	if 0 < init_countdown_sec:
		init_countdown_sec = max(init_countdown_sec - delta / Difficuilty.gameplay_speed, 0)
		GUI.set_objectives_header("%0.3f" % init_countdown_sec)
		if init_countdown_sec <= 0:
			$combatants/character.set_visible(true)
			$combatants/character/temporal_recorder.start_recording()
			$combatants/player_carrier/temporal_recorder.start_recording()
			for combatant in $combatants.get_children():
				combatant.resume_control()
			$timeline.reset()
			player_input.input_disabled = false
			GUI.set_objectives_header(str(
				living_team_members[1], " vs ", living_team_members[2],
				" - Score: ", int(kill_score * kill_score_multiplier)
			))
		else: return

	# Handle camera while replay
	if is_replay:
		var view_rectangle: Rect2 = Rect2()
		var characters_in_battle = 0
		for c: Node2D in $combatants.get_children():
			if c.in_battle():
				view_rectangle = view_rectangle.expand(c.get_global_position())
				characters_in_battle += 1
		if 2 < characters_in_battle:
			var viewport_size = get_viewport_rect().size
			var zoom_level = min(
				viewport_size.x / min(view_rectangle.size.x, 4096),
				viewport_size.y / min(view_rectangle.size.y, 4096),
			) * 0.9
			replay_viewport.position = lerp(replay_viewport.position, view_rectangle.position, replay_screen_responsiveness)
			replay_viewport.size = lerp(replay_viewport.size, view_rectangle.size, replay_screen_responsiveness)
			$replay_camera.zoom = Vector2(zoom_level, zoom_level)
			$replay_camera.set_global_position(replay_viewport.position + replay_viewport.size / 2.)

	# Handling Timeline reverse
	if BattleTimeline.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		current_laupeerium -= delta * rewind_battle_laupeerium_cost
		_update_laupeerium_bar()
		GUI.get_node("defeat").set_visible(false)
		GUI.get_node("victory").set_visible(false)
		GUI.get_node("restart_round_panel").set_visible(false)

	# Handling Slowdown
	if Difficulty.slowdown_multiplier < 1.:
		current_laupeerium = max(
			0., current_laupeerium - (1. - Difficulty.slowdown_multiplier) * delta * slowdown_battle_laupeerium_cost
		)
		if 0. == current_laupeerium: Difficuilty.slowdown_multiplier = 1.
		_update_laupeerium_bar()

func _unhandled_input(event: InputEvent) -> void:
	if is_replay: return 
	var just_pressed = event.is_pressed() and not event.is_echo()
	
	# Infinite ammo toggle (F7)
	if FeatureFlags.is_enabled("infinite_ammo"):
		if event is InputEventKey and event.physical_keycode == KEY_F7 and just_pressed:
			infinite_ammo_active = !infinite_ammo_active
			GUI.get_node("debug_stats/infinite_ammo_label").visible = infinite_ammo_active
			
	# Infinite boost toggle (F8)
	if FeatureFlags.is_enabled("infinite_boost"):
		if event is InputEventKey and event.physical_keycode == KEY_F8 and just_pressed:
			infinite_boost_active = !infinite_boost_active
			GUI.get_node("debug_stats/infinite_boost_label").visible = infinite_boost_active
	
	# God mode toggle (F9)
	if FeatureFlags.is_enabled("god_mode"):
		if event is InputEventKey and event.physical_keycode == KEY_F9 and just_pressed:
			god_mode_active = !god_mode_active
			GUI.get_node("debug_stats/god_mode_label").visible = god_mode_active

func player_defeated() -> bool:
	return (
		# character is deleted upon replaying the round
		$combatants.has_node("character")
		and( 
			(
				not $combatants/player_carrier.is_alive
				and not $combatants/character.is_alive
			) or (
				0. == current_laupeerium
				and not $combatants/character.is_alive
			)
		)
	)

func are_you_winning_son() -> bool:
	return (
		not player_defeated()
		and 0 == living_team_members[2]
	)

var kill_score: float = 0.
@export var kill_score_multiplier: float = 100.
@export var resource_score_multiplier: float = 500.
func _on_battle_character_dead(character: BattleCharacter) -> void:
	if is_replay: return
	var dead_character_team = character.team
	living_team_members[dead_character_team.team_id] -= 1
	if $combatants/character.team.is_enemy(dead_character_team):
		kill_score += character.starting_health * Difficuilty.gameplay_speed
	GUI.set_objectives_header(str(
		living_team_members[1], " vs ", living_team_members[2],
		" - Score: ", int(kill_score * kill_score_multiplier)
	))
	if player_defeated():
		GUI.get_node("victory").set_visible(false)
		GUI.get_node("restart_round_panel").set_visible(false)
		GUI.get_node("defeat").set_visible(true)
	elif are_you_winning_son():
		GUI.get_node("restart_round_panel").set_visible(false)
		GUI.get_node("defeat").set_visible(false)
		GUI.get_node("victory").set_visible(true)
		GUI.set_objectives_header(str(
			living_team_members[1], " vs ", living_team_members[2],
			" - Score: ", int(kill_score * kill_score_multiplier + current_laupeerium * resource_score_multiplier)
		))
	elif $combatants.has_node("character") and not $combatants/character.is_alive:
		GUI.get_node("victory").set_visible(false)
		GUI.get_node("defeat").set_visible(false)
		GUI.get_node("restart_round_panel").set_visible(true)

func _on_battle_character_resurrected(character: BattleCharacter) -> void:
	if is_replay: return
	if $combatants.has_node("character") and $combatants/character.is_alive:
		GUI.get_node("restart_round_panel").set_visible(false)
	living_team_members[character.team.team_id] += 1
	GUI.set_objectives_header(str(
		living_team_members[1], " vs ", living_team_members[2],
		" - Score: ", int(kill_score * kill_score_multiplier)
	))

var is_replay = false
func replay_game() -> void:
	is_replay = true
	replay_viewport = Rect2()
	for c in $combatants.get_children():
		replay_viewport.expand(c.get_global_position())
		if c.has_node("ai_control"):
			c.ai_fallback = false
			c.get_node("ai_control").set_disabled(true)
		if c is BattleCharacter: entangle_ship_with_player(c)
		if c.has_node("target_assist"):
			c.get_node("target_assist").set_disabled(true)
	replay_round(false)
	player_input.input_disabled = true
	$combatants/character.queue_free()
	$replay_camera.make_current()
	GUI.get_node("restart_during_replay").set_visible(true)
	GUI.get_node("score").set_visible(false)

func time_control_triggered(action: Dictionary) -> void:
	if not (
		"rewind_toggled" in action and action["rewind_toggled"] and 0. >= current_laupeerium
		or (
			"checkpoint_reset_triggered" in action and action["checkpoint_reset_triggered"]
			and rewind_battle_laupeerium_cost >= current_laupeerium
		)  # There are enough resources to control time!
	):
		if "checkpoint_reset_triggered" in action: current_laupeerium -= 1.
		super(action)

func _update_laupeerium_bar() -> void:
	GUI.set_laupeerium_indicator(round(float(UIEnergyBar.max_bars) * (current_laupeerium / starting_laupeerium)))

func _on_silo_doors_toggled(is_open: bool) -> void:
	if is_open:
		%character.explosion_shake(100.)
		if already_used_laupeerium and $debris/silo/payload_trigger/payload:
			$debris/silo/payload_trigger/payload.queue_free()

var already_used_laupeerium: bool = false
func _on_silo_payload_reached() -> void:
	create_tween().tween_method(func(w: float):
		current_laupeerium += w
		_update_laupeerium_bar(),
		0., 1., 0.5
	)
	already_used_laupeerium = true
