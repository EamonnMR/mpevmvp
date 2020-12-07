extends RigidBody2D

# The position of bullets isn't sent over the network except at init
# We use dead reckoning (via the physics engine) to get the position.

var damage: float = 0

var direction: float = 0.0

var team_set = []

var type = "todo_shot_types"

var source: Node

func apply_stats(type):
	pass

func init(speed, new_damage, lifetime, start_angle, new_position, new_velocity, new_source):
	$RotationSprite.set_direction(start_angle)
	set_linear_velocity(Vector2(speed, 0).rotated(start_angle) + new_velocity)
	position = new_position
	direction = start_angle
	damage = new_damage
	$Timer.wait_time = lifetime
	source = new_source
	#_show_debug_info()
	
func _show_debug_info():
	if(OS.is_debug_build()):
		_show_team_set()
	
func _show_team_set():
	$team_set_label.show()
	for team in team_set:
		$team_set_label.text += str(team) + ", "


func _on_shot_body_entered(body):
	for team_flag in team_set:
		if body.team_set.has(team_flag):
			#print("Ignoring friendly fire")
			#print("Shot Flags: ", team_set, " Target Flags: ", body.team_set)
			return
	#print("Shot Hit")
	#print("Shot Flags: ", team_set, " Target Flags: ", body.team_set)
	if( body.has_method("take_damage") ):
		body.take_damage(damage, source)
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
