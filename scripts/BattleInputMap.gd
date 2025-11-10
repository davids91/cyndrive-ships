extends Node2D

class_name BattleInputMap

#	_FORCE_INLINE_ real_t tdotx(const Vector2 &p_v) const { return columns[0][0] * p_v.x + columns[1][0] * p_v.y; }
static func tdotx(mat, vec):
	return mat.get_scale().x * vec.x  # Let's pretend for now that there is no rotation.. '^^
	
#	_FORCE_INLINE_ real_t tdoty(const Vector2 &p_v) const { return columns[0][1] * p_v.x + columns[1][1] * p_v.y; }
static func tdoty(mat, vec):
	return mat.get_scale().y * vec.y

static func xform(mat, vec):
	return Vector2(tdotx(mat, vec), tdoty(mat, vec)) + mat.get_origin()
"""
Provides the processed control output in a form of a dictionary from the provided data and user input events
Output format is the following: 
	action["intent"]: vector: intent of user control in 2D space (up, down, left right). Vector values are either -1, 0 or 1
	action["cursor"]: vector: normalized direction vector the player points to from the controlled ship
	action["pewpew"]: boolean: true if player shoots laser
"""
static func get_action(viewport, subject_global_position, input_event):
	var action = Dictionary()
	var intent_direction = Vector2(
		(-1. if input_event.is_action_pressed("left") else 0. + 1. if input_event.is_action_pressed("right") else 0.),\
		(1. if input_event.is_action_pressed("down") else 0. + -1. if input_event.is_action_pressed("up") else 0.)
	)
	intent_direction -= Vector2(
		(-1. if input_event.is_action_released("left") else 0. + 1. if input_event.is_action_released("right") else 0.),\
		(1. if input_event.is_action_released("down") else 0. + -1. if input_event.is_action_released("up") else 0.)
	)
	
	action["intent"] = intent_direction
	if(input_event.is_action_pressed("pewpew")):
		var global_mouse_pos = xform(viewport.get_canvas_transform().affine_inverse(), viewport.get_mouse_position())
		action["cursor"] = (global_mouse_pos - subject_global_position).normalized()
		action["pewpew"] = true
	else:
		action["cursor"] = Vector2()
		action["pewpew"] = false
	return action
