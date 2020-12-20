extends ShipController

class_name JumpAutopilot

var destination: String  # System it's jumping to
var parent

func _ready():
	parent = get_node("../")

func _physics_process(delta):
	if parent.get_linear_velocity().length() > 0.01:
		puppet_braking = true
	else:
		parent.complete_jump()
	# if not moving and not in blastoff:
	# rotate to face target system
	# else if facing target system and not moving:
	# Blastoff! Accelerate towards space
	# If outside jump radius:
	# complete jump
