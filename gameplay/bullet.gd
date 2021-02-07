extends RigidBody2D

class_name Bullet

# The position of bullets isn't sent over the network except at init
# We use dead reckoning (via the physics engine) to get the position.

var damage: float = 0

var direction: float = 0.0

var team_set = []

var type = "todo_shot_types"

var source: Node

var in_aoe = []

var dat

func apply_stats(type):
	pass

func init(dat: WeaponData, direction, position, velocity, source):
	$RotationSprite.set_direction(direction)
	set_linear_velocity(Vector2(dat.projectile_velocity, 0).rotated(direction) + velocity)
	self.position = position
	self.direction = direction
	$Timer.wait_time = dat.projectile_lifetime
	self.source = source
	self.damage = dat.damage
	if dat.aoe:
		var shape = CircleShape2D.new()
		shape.radius = dat.aoe
		$Aoe/CollisionShape2D.shape = shape
	#_show_debug_info()
	
func _show_debug_info():
	if(OS.is_debug_build()):
		_show_team_set()
	
func _show_team_set():
	$team_set_label.show()
	for team in team_set:
		$team_set_label.text += str(team) + ", "

func _on_shot_body_entered(body):
	print("begin impact")
	for team_flag in team_set:
		if body.team_set.has(team_flag):
			print("Team Flag: ", team_flag, " Flag: ", body.team_set)
			print("Friendly - no impact")
			return
	if( body.has_method("take_damage") ):
		body.take_damage(damage, source)
	for aoe_body in in_aoe:
		if( aoe_body.has_method("take_damage") ):
			aoe_body.take_damage(damage, source)
	remove()
	print("end impact")
	
func remove():
	# Override this for long lived projectiles or ones that seem sticky.
	# Also maybe handle "ghost bullet/beam" logic.
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

func _on_Aoe_body_entered(body):
	in_aoe.append(body)

func _on_Aoe_body_exited(body):
	in_aoe.erase(body)
