extends Node2D

@export_range(0., 1.) var color_mix: float = 1.
@export var skin_material: Material = preload("res://resources/implode_effect.tres").duplicate()

func set_burn_percentage(percentage: float) -> void:
	skin_material.set_shader_parameter("burn_percentage", percentage)
	set_visible(percentage < 0.99)

func display_color(color: Color) -> void:
	skin_material.set_shader_parameter("team_color", color)

func set_skins_material(mat: ShaderMaterial) -> void:
	skin_material = mat.duplicate()
	skin_material.set_shader_parameter("team_color", team_color)

var team_color: Color = Color.TRANSPARENT
func init_skin(skin_layers: Array[BattleShipSkin], init_team_color: Color) -> void:
	set_visible(true)
	# set skin viewport to fit character size
	$layers.size = Vector2(get_parent().approx_size, get_parent().approx_size)
	team_color = lerp(team_color, init_team_color, color_mix)

	# Remove placeholders
	for c in $layers.get_children():
		if not c is Camera2D: c.queue_free()

	# Add a Sprite for each layer of skin
	display_color(team_color)
	for layer in skin_layers.size():
		var layer_image = Sprite2D.new()
		layer_image.set_texture(skin_layers[layer].texture)
		layer_image.scale = skin_layers[layer].scale
		layer_image.set_rotation(skin_layers[layer].rotation)
		layer_image.z_index = skin_layers[layer].z_index
		layer_image.offset = skin_layers[layer].offset
		# TechDebt: Subviewport is needed to produce the $skin_image, but this is duplicate work. There must be a better system!
		# --> Multiple sprites are added per layer to enable z index ordering, instead of using skin_image
		# --> $skin_image is required for the phase_effect
		$layers.add_child(layer_image)
		var actual_skin = layer_image.duplicate()
		actual_skin.offset = Vector2.ZERO
		actual_skin.material = skin_material
		add_child(actual_skin)
