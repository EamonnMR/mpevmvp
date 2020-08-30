extends RigidBody2D

# The position of bullets isn't sent over the network except at init
# We use dead reckoning (via the physics engine) to get the position.

var SPEED = 500

var DAMAGE = 10

func init(start_angle, new_position):
	$RotationSprite.set_direction(start_angle)
	set_linear_velocity(Vector2(SPEED, 0).rotated(start_angle))
	position = new_position

func _on_shot_body_entered(body):
	if( body.has_method("take_damage") ):
		body.take_damage(DAMAGE)

	queue_free()

func serialize():
	return {}

func deserialize(data):
	pass
