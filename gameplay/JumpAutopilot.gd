extends ShipController

class_name JumpAutopilot

const FACE_MARGIN = PI / 10.0

var parent
var fixed_ideal_face: float

func _ready():
	parent = get_node("../")
	fixed_ideal_face = PI # TODO: Calculate jump angle

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
	var moving = parent.get_linear_velocity().length() > 0.01
	if moving:
		puppet_braking = true
	else:
		puppet_braking = false
		var facing_destination = _facing_within_margin()
		if not facing_destination:
			rotate_to_face_destination(delta)
		else:
			parent.complete_jump()
			# Blastoff! Accelerate towards space
			# If outside jump radius:
			# complete jump
