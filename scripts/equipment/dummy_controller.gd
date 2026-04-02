extends Node2D

var enabled: bool = true
var intent_direction: Vector2 = Vector2()
var intent_force: Vector2 = Vector2()
var internal_force: Vector2 = Vector2()

func start() -> void: pass
func pause() -> void: pass
func stop() -> void: pass
func apply_impulse(_impulse: Vector2) -> void: pass
func process_input_action(_action: Dictionary) -> void: pass
