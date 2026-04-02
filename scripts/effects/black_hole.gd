class_name BlackHole
extends Area2D

const DAMAGE: float = 666.

var bodies_within: Dictionary
func _on_body_entered(body: Node2D) -> void:
	bodies_within[body] = BattleTimeline.instance.time_msec()

func _on_body_exited(body: Node2D) -> void:
	bodies_within.erase(body)
@export var strength: float = 1000.
@export var time_to_die_msec: float = 500.
@export var death_radius: float = 250
func _process(_delta: float) -> void:
	for body in bodies_within:
		var body_to_center = (get_global_position() - body.get_global_position())
		var pull_force = body_to_center.normalized()
		pull_force *= strength * (BattleTimeline.instance.time_msec() - bodies_within[body]) / time_to_die_msec
		if body.has_node("ai_control"): pull_force *= 500. # TechDebt: snappy playercontroller works on different force amounts
		body.apply_impulse(pull_force)
		if body_to_center.length() < death_radius:
			if body.has_method("accept_damage"): body.accept_damage(DAMAGE)
			else:
				bodies_within.erase(body)
				body.queue_free()
