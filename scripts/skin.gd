extends Node2D

@onready var character: Node = get_parent()

var skins_material : ShaderMaterial

func _ready() -> void:
	character = get_parent() as BattleCharacter

func set_burn_percentage(percentage: float) -> void:
	skins_material.set_shader_parameter("burn_percentage", percentage)

func set_team_color(color: Color) -> void:
	skins_material.set_shader_parameter("team_color", color)

func set_skins_material(mat: ShaderMaterial) -> void:
	skins_material = mat
	for c in $layers.get_children():
		c.material = mat

func init_skin(skin_layers: Array[BattleShipSkin], team_color: Color) -> void:
	# set skin viewport to fit character size
	$layers.size = Vector2(character.approx_size, character.approx_size)

	# Remove placeholders
	for c in $layers.get_children():
		if not c is Camera2D: c.queue_free()

	# Add a Sprite for each layer of skin
	skins_material = preload("res://resources/implode_effect.tres").duplicate()
	for layer in skin_layers.size():
		var layer_image = Sprite2D.new()
		layer_image.set_texture(skin_layers[layer].texture)
		layer_image.material = skins_material
		layer_image.material.set_shader_parameter("team_color", team_color)
		layer_image.scale = skin_layers[layer].scale
		layer_image.set_rotation(skin_layers[layer].rotation)
		layer_image.z_index = skin_layers[layer].z_index
		$layers.add_child(layer_image)
