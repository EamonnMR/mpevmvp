extends RigidBody2D

# The position of bullets isn't sent over the network except at init
# We use dead reckoning (via the physics engine) to get the position.

var SPEED = 50

var DAMAGE = 10

var direction: float = 0.0

var team_set = []

func init(start_angle, new_position):
	print("Start angle: ", start_angle)
	$RotationSprite.set_direction(start_angle)
	set_linear_velocity(Vector2(SPEED, 0).rotated(start_angle))
	position = new_position
	direction = start_angle

func _on_shot_body_entered(body):
	for team_flag in team_set:
		if body.team_set.has(team_flag):
			print("Ignoring friendly fire")
			return
	if( body.has_method("take_damage") ):
		body.take_damage(DAMAGE)
	queue_free()

func serialize():
	return {
		"position": position,
		"velocity": get_linear_velocity(),
		"direction": direction,
		"team_set": team_set  # TODO: This needs to be further compressed.
	}

func deserialize(data):
	position = data["position"]
	set_linear_velocity(data["velocity"])
	$RotationSprite.set_direction(data["direction"])
	team_set = data["team_set"]
	

func _on_Timer_timeout():
	queue_free()
