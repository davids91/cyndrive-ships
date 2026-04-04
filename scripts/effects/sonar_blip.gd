class_name SonarBlip extends Node2D

const INFINITE_LIFETIME: float = 69420. # NICE

var lifetime_sec: float = 1.
var parent: Node2D = null
var target: Node2D = null
var parent_offset: int = 0
var color: Color = Color.WHITE
var lifetime_remaining_sec = lifetime_sec

# call after instantiating the scene
func init(p_parent: Node2D, p_parent_offset: int, p_target: Node2D, p_color: Color) -> void:
	lifetime_remaining_sec = lifetime_sec
	parent = p_parent
	target = p_target
	parent_offset = p_parent_offset
	color = p_color
	if "sonar_blip_scale" in p_target: scale = p_target.sonar_blip_scale
	if lifetime_sec == INFINITE_LIFETIME: modulate.a = 1.
	parent.add_child(self)

# called when an already blipped object is detected again
func reinvigorate() -> void: lifetime_remaining_sec = lifetime_sec

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$blip.modulate = color
	$blip.offset = Vector2(0,-parent_offset)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target == null or parent == null:
		queue_free()
		return
	look_at(target.global_position)
	lifetime_remaining_sec -= delta
	if lifetime_remaining_sec <= 0. and lifetime_remaining_sec != INFINITE_LIFETIME: queue_free()
	elif lifetime_remaining_sec != INFINITE_LIFETIME:
		modulate.a = min(lifetime_remaining_sec / lifetime_sec, target.modulate.a)
