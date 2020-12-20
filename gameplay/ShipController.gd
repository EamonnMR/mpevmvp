extends Node

class_name ShipController

puppet var puppet_direction_change: int = 0
puppet var puppet_shooting = false
puppet var puppet_thrusting = false
puppet var puppet_braking = false
puppet var puppet_selected_system: String = ""
puppet var puppet_landing = false

func _anglemod(angle: float) -> float:
	return fmod(angle, PI * 2)

func _get_ideal_face(from: Node2D, to: Vector2):
	return _anglemod(from.get_angle_to(to))

func _constrained_point(subject, current_rotation, max_turn, position: Vector2):
	# For finding the right direction and amount to turn when your rotation speed is limited
	var ideal_face = _get_ideal_face(subject, position)
	var ideal_turn = _anglemod(ideal_face - current_rotation)
	if(ideal_turn > PI):
		ideal_turn = _anglemod(ideal_turn - 2 * PI)

	elif(ideal_turn < -1 * PI):
		ideal_turn = _anglemod(ideal_turn + 2 * PI)
	
	max_turn = sign(ideal_turn) * max_turn  # Ideal turn in the right direction
	
	if(abs(ideal_turn) > abs(max_turn)):
		return [max_turn, ideal_face]
	else:
		return [ideal_turn, ideal_face]

func _flatten_to_sign(value):
	# For getting puppet direction change
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0
