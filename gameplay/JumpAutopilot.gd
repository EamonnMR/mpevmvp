extends ShipController

class_name JumpAutopilot

const FACE_MARGIN = PI / 10.0

var parent
var fixed_ideal_face: float
var slowdown_completed = false

func _ready():
	parent = get_node("../")
	fixed_ideal_face = _get_hyperjump_angle()

func rotate_to_face_destination(delta):
	var impulse = _constrained_point(
		null, # Dummied out because we override get ideal point
		parent.direction, parent.turn * delta,
		Vector2(0,0) # Dummied out because we override get ideal point
	)
	puppet_direction_change = _flatten_to_sign(impulse[0])

func _get_ideal_face(_from: Node2D, _to: Vector2):
	return fixed_ideal_face

func _facing_within_margin():
	return abs(_anglemod(fixed_ideal_face - parent.direction)) < FACE_MARGIN

func _physics_process(delta):
	if not slowdown_completed:
		var moving = parent.get_linear_velocity().length() > 0.01
		if moving:
			puppet_braking = true
		else:
			slowdown_completed = true
	else:
		puppet_braking = false
		
		var facing_destination = _facing_within_margin()
		if not facing_destination:
			rotate_to_face_destination(delta)
		else:
			if parent.get_linear_velocity().length() > (parent.max_speed * 0.9):
				parent.complete_jump()
			else:
				puppet_direction_change = 0
				puppet_thrusting = true

func _get_hyperjump_angle():
	var current_system = Game.systems[parent.current_system()]["position"]
	var destination_system = Game.systems[puppet_selected_system]["position"]
	
	return _anglemod(current_system.angle_to_point(destination_system))
