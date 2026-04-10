extends Node2D

var age = 0
var lifespan = 10
var speed = 400

func _process(delta):
	var forward_dir = Vector2.RIGHT.rotated(rotation)
	position += forward_dir * speed * delta
	
	# TODO: raycast to see if we hit player

	age += delta
	if age > lifespan:
		queue_free()
