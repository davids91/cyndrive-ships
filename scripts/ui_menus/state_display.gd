extends ProgressBar

enum EMOTES {
	ANNOYED, EXCLAIM, ANGRY,
}

@export var max_health: float = 12.
@export var mini_health_bar_offset: Vector2 = Vector2(-64, 64)
@export var emote_offset: Vector2 = Vector2(20, -70)
@export var speech_buble_offset: Vector2 = Vector2(128, 64)
@export var emotes: Array[Rect2] = [
	Rect2(0., 0., 38, 77),
	Rect2(44., 0., 18, 77.),
	Rect2(25., 80., 48., 48.)
]
@export var skin: Node2D
@export var speech_bubbles: Array[CompressedTexture2D] = [
	preload("res://textures/ui/panels/speech_bubble_1.png"),
	preload("res://textures/ui/panels/speech_bubble_2.png"),
	preload("res://textures/ui/panels/speech_bubble_3.png"),
]

@export var line_display_length_sec: float = 5.
@export var line_appear_length_sec: float = 0.5
var speech_tween: Tween = null
func say(line: String) -> void:
	if speech_tween: speech_tween.kill()
	$speech_bubble/border.texture = speech_bubbles.pick_random()
	$speech_bubble/text.set_text("")
	$speech_bubble.set_visible(true)
	speech_tween = create_tween()
	speech_tween.set_parallel(true)
	speech_tween.tween_method(
		func(w: float): $speech_bubble/text.set_text(line.substr(0,int(w))),
		0., float(line.length()), line_appear_length_sec
	)
	speech_tween.tween_method(
		func(w: float):
			$speech_bubble/border.material.set_shader_parameter("pixel_scale", w * 10.)
			$speech_bubble/border.material.set_shader_parameter("burn_percentage", w),
		1., 0.2, line_appear_length_sec
	)
	speech_tween.chain().tween_method(
		func(w: float):
			$speech_bubble/border.material.set_shader_parameter("pixel_scale", 2. + (1. - w) * 20.)
			$speech_bubble/border.material.set_shader_parameter("burn_percentage", w),
		0.2, 1.0, line_appear_length_sec / 2.
	).set_delay(line_display_length_sec)
	speech_tween.chain().tween_callback(func():$speech_bubble.set_visible(false))

@export var angry_distance: float = 5.
func angry_emote() -> void:
	$emote.self_modulate.a = 1.
	$emote.region_rect = emotes[EMOTES.ANGRY]
	var emote_tween = create_tween()
	emote_tween.set_parallel(true)
	emote_tween.chain().tween_interval(0.1)
	emote_tween.tween_method(func(w: float):
		$emote.position =  emote_offset + Vector2(
			(randf() - 0.5) * 2. * w,
			(randf() - 0.5) * 2. * w
		),
		0., angry_distance, 1.5
	)
	emote_tween.tween_callback(func(): $emote.set_visible(true)).set_delay(0.1)
	emote_tween.tween_property($emote, "position", emote_offset, 0.2).set_delay(1.6)
	emote_tween.chain().tween_method(func(w: float): $emote.self_modulate.a = w, 1., 0., 0.3)
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
		func(w: float): $emote.position = emote_offset + Vector2(w / 10., w),
		0., annoyed_distance * 2., annoyed_length_sec
	)
	emote_tween.tween_method(
		func(w: float): $emote.self_modulate.a = w,
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
		func(w: float): $emote.self_modulate.a = w,
		0., 1., exclaim_appear_length_sec
	)
	emote_tween.tween_callback(func(): $emote.set_visible(false)).set_delay(exclaim_appear_length_sec)
	emote_tween.tween_callback(func(): $emote.set_visible(true)).set_delay(exclaim_appear_length_sec + exclaim_show_length_sec * 0.2)
	emote_tween.tween_method(
		func(w: float): $emote.scale = Vector2(w,w),
		1.5, 1.8, exclaim_show_length_sec * 0.05
	).set_delay(exclaim_appear_length_sec + exclaim_show_length_sec * 0.2)
	emote_tween.tween_callback(func(): $emote.set_visible(false)).set_delay(exclaim_appear_length_sec * 2. + exclaim_show_length_sec)
	emote_tween.tween_method(
		func(w: float):
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
	$speech_bubble.position = speech_buble_offset

func _process(_delta):
	if top_level:
		set_global_position(get_parent().get_global_position() + mini_health_bar_offset)

func _on_character_health_changed(percentage: float) -> void:
	set_value_no_signal(percentage * max_value)
