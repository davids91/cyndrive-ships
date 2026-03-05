extends Node2D

@onready var character: Node = get_parent()

func _ready() -> void:
	character = get_parent() as BattleCharacter

func set_burn_percentage(percentage: float) -> void:
	$skin_image.material.set_shader_parameter("burn_percentage", percentage)
	set_visible(percentage < 0.99)

func set_team_color(color: Color) -> void:
	$skin_image.material.set_shader_parameter("team_color", color)

func set_skins_material(mat: ShaderMaterial) -> void:
	$skin_image.material = mat.duplicate()
	$skin_image.material.set_shader_parameter("team_color", team_color)

var team_color: Color = Color.WHITE
func init_skin(skin_layers: Array[BattleShipSkin], init_team_color: Color) -> void:
	set_visible(true)
	# set skin viewport to fit character size
	$layers.size = Vector2(character.approx_size, character.approx_size)
	team_color = init_team_color

	# Remove placeholders
	for c in $layers.get_children():
		if not c is Camera2D: c.queue_free()

	# Add a Sprite for each layer of skin
	set_team_color(team_color)
	for layer in skin_layers.size():
		var layer_image = Sprite2D.new()
		layer_image.set_texture(skin_layers[layer].texture)
		layer_image.scale = skin_layers[layer].scale
		layer_image.set_rotation(skin_layers[layer].rotation)
		layer_image.z_index = skin_layers[layer].z_index
		layer_image.offset = skin_layers[layer].offset
		# TechDebt: Subviewport is needed to produce the $skin_image, but this is duplicate work. There must be a better system!
		# --> $skin_image is required for the phase_effect
		$layers.add_child(layer_image)
		var actual_skin = layer_image.duplicate()
		actual_skin.material = $skin_image.get_material()
		add_child(actual_skin)
