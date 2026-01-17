@tool
class_name Meteor extends BattleDebris

@export var skin_idx: int
@export var collision_shape: Array[Shape2D]
@export var collision_rotation: Array[float]

func _ready() -> void:
	$skin.region_rect.position.y = skin_idx * $skin.region_rect.size.y
	$collision_shape.shape = collision_shape[skin_idx]
	$collision_shape.set_rotation(collision_rotation[skin_idx])

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
			$skin.region_rect.position.y = skin_idx * $skin.region_rect.size.y
			$collision_shape.shape = collision_shape[skin_idx]
			$collision_shape.set_rotation(collision_rotation[skin_idx])
