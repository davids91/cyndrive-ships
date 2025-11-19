extends ColorRect

@export var radius = 250.

func set_display_visibility(yesno):
	set_visible(yesno)

func set_display_rotation(rot): 
	get_material().set_shader_parameter("angle", rot)

func erase_node(node):
	node.queue_free()

func add_display_object(relative_pos, modulate_color):
	if relative_pos.length() < radius or !is_visible():
		return
		
	var screen_center = get_viewport_rect().size / 2.
	var direction = relative_pos.normalized();
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://textures/arrow.png")
	sprite.set_position(screen_center + direction * radius)
	sprite.set_rotation(direction.angle() + PI/2.)
	sprite.modulate = modulate_color
	$"..".add_child(sprite)	

	# make sprite disappear
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.,1.,1.,0.), 0.9)
	tween.tween_callback(erase_node.bind(sprite))
