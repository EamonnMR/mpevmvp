extends Bullet

var target: Node
var turn: float
var accel: float
var max_speed: float
puppet var puppet_dir: float
puppet var puppet_pos: Vector2 = Vector2(0,0)
puppet var puppet_velocity: Vector2 = Vector2(0,0)

func init(dat: WeaponData, direction, position, velocity, source):
	.init(dat, direction, position, velocity, source)
	target = source.get_target()
	turn = dat.guided_turn
	accel = dat.guided_accel
	max_speed = dat.projectile_velocity

func _physics_process(delta):
	if (is_network_master()):
		if is_instance_valid(target):
			handle_rotation(delta)
		
		rset_ex("puppet_dir", direction)
		rset_ex("puppet_pos", position)
		rset_ex("puppet_velocity", get_linear_velocity())

	else:
		direction = puppet_dir
		position = puppet_pos # This should be in integrate forces, but for some reason the puppet pos variable does not work there

	$RotationSprite.set_direction(direction)

func _integrate_forces(state):
	set_applied_torque(0)  # No rotation component
	rotation = 0.0
	if (is_network_master()):
		set_linear_velocity(get_limited_velocity_with_thrust())
	else:
		state.transform.origin = puppet_pos
		set_linear_velocity(puppet_velocity)

func get_direction_change(delta):
	var impulse = _constrained_point(
		self, direction, turn * delta, target.position
	)
	return _flatten_to_sign(impulse[0])

func handle_rotation(delta):
	direction = _anglemod(((turn * get_direction_change(delta) * delta) + direction))

func get_limited_velocity_with_thrust():
	var vel = get_linear_velocity()
	vel += Vector2(accel, 0).rotated(direction)
	if vel.length() > max_speed:
		return Vector2(max_speed, 0).rotated(vel.angle())
	else:
		return vel

func rset_ex(puppet_var, value):
	# TODO: Uncopypasta this
	# Unreliable!
	# This avoids a whole lot of extra network traffic...
	# and a whole lot of "Invalid packet received. Requested node was not found."
	for id in get_level().get_node("world").get_player_ids():
		rset_unreliable_id(id, puppet_var, value)
	set(puppet_var, value)


func get_level():
	# What universe are we in?
	#      players ->   world      -> level 
	return get_parent().get_parent().get_parent()

# TODO: Dedupe, copied from ship controller:

static func _anglemod(angle: float) -> float:
	return fmod(angle, PI * 2)

static func _get_ideal_face(from: Node2D, to: Vector2):
	return _anglemod(from.get_angle_to(to))

static func _constrained_point(subject, current_rotation, max_turn, position: Vector2):
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

static func _flatten_to_sign(value):
	# For getting puppet direction change
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0
