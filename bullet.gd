extends RigidBody2D

# The position of bullets isn't sent over the network except at init
# We use dead reckoning (via the physics engine) to get the position.

var SPEED = 50

var DAMAGE = 10

var direction: float = 0.0

func init(start_angle, new_position):
	print("Start angle: ", start_angle)
	$RotationSprite.set_direction(start_angle)
	set_linear_velocity(Vector2(SPEED, 0).rotated(start_angle))
	position = new_position
	direction = start_angle

func _on_shot_body_entered(body):
	if( body.has_method("take_damage") ):
		body.take_damage(DAMAGE)
	queue_free()

func serialize():
	return {
		"position": position,
		"velocity": get_linear_velocity(),
		"direction": direction
	}

func deserialize(data):
	position = data["position"]
	set_linear_velocity(data["velocity"])
	$RotationSprite.set_direction(data["direction"])
