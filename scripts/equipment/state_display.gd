extends ProgressBar

enum EMOTES {
	ANNOYED, EXCLAIM, ANGRY,
}

@export var max_health: float = 12.
@export var mini_health_bar_offset: Vector2 = Vector2(-64, 64)
@export var emote_offset: Vector2 = Vector2(20, -70)
@export var emotes: Array[Rect2] = [
	Rect2(0., 0., 38, 77),
	Rect2(44., 0., 18, 77.),
	Rect2(25., 80., 48., 48.)
]
@export var skin: Node2D

@export var angry_distance: float = 5.
func angry_emote() -> void:
	$emote.self_modulate.a = 1.
	$emote.region_rect = emotes[EMOTES.ANGRY]
	var emote_tween = create_tween()
	emote_tween.set_parallel(true)
	emote_tween.chain().tween_interval(0.1)
	emote_tween.tween_method(func(w):
		$emote.position =  emote_offset + Vector2(
			(randf() - 0.5) * 2. * w,
			(randf() - 0.5) * 2. * w
		),
		0., angry_distance, 1.5
	)
	emote_tween.tween_callback(func(): $emote.set_visible(true)).set_delay(0.1)
	emote_tween.tween_property($emote, "position", emote_offset, 0.2).set_delay(1.6)
	emote_tween.chain().tween_method(func(w): $emote.self_modulate.a = w, 1., 0., 0.3)
	emote_tween.chain().tween_callback(func(): $emote.set_visible(false))

@export var annoyed_distance: float = 25.
@export var annoyed_length_sec: float = 2.
func annoyed_emote() -> void:
	$emote.set_visible(true)
	$emote.self_modulate.a = 0.2
	$emote.scale = Vector2(1., 1.5)
	$emote.region_rect = emotes[EMOTES.ANNOYED]
	$emote.position = emote_offset + Vector2(0., annoyed_distance)
	var emote_tween = create_tween()
	emote_tween.set_parallel(true)
	emote_tween.tween_method(
		func(w): $emote.position = emote_offset + Vector2(w / 10., w),
		0., annoyed_distance * 2., annoyed_length_sec
	)
	emote_tween.tween_method(
		func(w): $emote.self_modulate.a = w,
		0.2, 1., annoyed_length_sec
	)
	emote_tween.chain().tween_callback(func():
		$emote.set_visible(false)
		$emote.scale = Vector2(1.5, 1.5)
		$emote.position = emote_offset
	)

@export var exclaim_appear_length_sec: float = 0.05
@export var exclaim_show_length_sec: float = 1.
func exclaim_emote() -> void:
	$emote.set_visible(true)
	$emote.self_modulate.a = 0.
	$emote.scale = Vector2(1.5, 1.5)
	$emote.region_rect = emotes[EMOTES.EXCLAIM]
	var emote_tween = create_tween()
	emote_tween.set_parallel(true)
	emote_tween.tween_method(
		func(w): $emote.self_modulate.a = w,
		0., 1., exclaim_appear_length_sec
	)
	emote_tween.tween_callback(func(): $emote.set_visible(false)).set_delay(exclaim_appear_length_sec)
	emote_tween.tween_callback(func(): $emote.set_visible(true)).set_delay(exclaim_appear_length_sec + exclaim_show_length_sec * 0.2)
	emote_tween.tween_method(
		func(w): $emote.scale = Vector2(w,w),
		1.5, 1.8, exclaim_show_length_sec * 0.05
	).set_delay(exclaim_appear_length_sec + exclaim_show_length_sec * 0.2)
	emote_tween.tween_callback(func(): $emote.set_visible(false)).set_delay(exclaim_appear_length_sec * 2. + exclaim_show_length_sec)
	emote_tween.tween_method(
		func(w):
			$emote.self_modulate.a = w
			$emote.position.y -= w * 2.,
		1., 0., exclaim_appear_length_sec
	).set_delay(exclaim_show_length_sec)
	emote_tween.chain().tween_callback(func(): $emote.scale = Vector2(1.5, 1.57))

func process_input_action(action: Dictionary) -> void:
	if "emote_1" in action and action["emote_1"]:
		angry_emote()

	if "emote_2" in action and action["emote_2"]:
		annoyed_emote()

	if "emote_3" in action and action["emote_3"]:
		exclaim_emote()


func _ready() -> void:
	max_value = max_health
	$emote.position = emote_offset

func _process(_delta):
	if top_level:
		set_global_position(get_parent().get_global_position() + mini_health_bar_offset)

func _on_character_health_changed(percentage: float) -> void:
	set_value_no_signal(percentage * max_value)
