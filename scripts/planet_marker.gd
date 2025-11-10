extends CollisionObject2D

func _ready():
	pass

func _on_mouse_entered():
	get_node("marker_small").hide()
	get_node("marker_large").show()

func _on_mouse_exited():
	get_node("marker_large").hide()
	get_node("marker_small").show()
