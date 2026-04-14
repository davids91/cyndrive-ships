extends Node2D

var age = 0
var lifespan = 10
var speed = 650
var trigger_radius = 64
var p1 = null

const EXPLOSION_FIREY = preload("res://scenes/effects/explosion-firey.tscn")
# hmm null @onready var level = get_node("/root/Main/LevelContainer/battle")

func _ready():
	# maybe use level.get_node() or that team system array of enemies
	p1 = get_tree().get_root().find_child("character", true, false)

func boom():
	#print("boom!")
	explode()
	queue_free()	

var explosion: Explosion = null
func explode() -> void:
	if null == explosion:
		explosion = EXPLOSION_FIREY.instantiate()
		explosion.explosion_damage = 15.
		explosion.explosion_length = 3.
		explosion.explosion_range = 600.
		explosion.shockwave_strength = 200.
		explosion.scale *= 3
		# this is null... hmmms		
		#level.get_node("mush").add_child(explosion)
		get_tree().root.add_child(explosion)
	explosion.global_position = get_global_position()
	explosion.reinit()
	# is_exploded = true
	# correct_temporal_state({"linear_velocity": Vector2.ZERO})
	# await get_tree().create_timer(.2).timeout # give lightning time to draw
	
func _process(delta):
	var forward_dir = Vector2.RIGHT.rotated(rotation)
	position += forward_dir * speed * delta
	
	# see if we hit player
	if p1 != null:
		var d = global_position.distance_to(p1.global_position)
		# print("dist: "+str(d))
		if d <= trigger_radius: boom()
	
	age += delta
	if age > lifespan:
		queue_free()
