extends Bullet

var target: Node
var turn: float
var accel: float
var max_speed: float

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
	else:
		var time = Client.time()
		var net_frame_latest = _get_net_frame(0)
		var net_frame_next = _get_net_frame(1)
		
		if not net_frame_next:
			hide()
		elif net_frame_next.time > time and net_frame_latest: # Interpolate
			show()
			var time_range = net_frame_next.time - net_frame_latest.time
			var time_offset = time - net_frame_latest.time
			var lerp_factor = float(time_offset) / float(time_range)
			
			lerp_member("position", net_frame_latest, net_frame_next, lerp_factor)
			lerp_angle_member("direction", net_frame_latest, net_frame_next, lerp_factor)
			
		elif net_frame_next.time < time and net_frame_latest: # Extrapolate
			show()
			# Extrapolate by dead reckoning
			var extrapolation_factor = float(time - net_frame_latest.time) / float(net_frame_next.time - net_frame_latest.time) - 1.00
			extrapolate_member("position", net_frame_latest, net_frame_next, extrapolation_factor)
			extrapolate_angle_member("direction", net_frame_latest, net_frame_next, extrapolation_factor)

		else: # Cannot extrapolate - probably waiting on frames
			pass
	$RotationSprite.set_direction(direction)

func _integrate_forces(state):
	set_applied_torque(0)  # No rotation component
	rotation = 0.0
	if (is_network_master()):
		set_linear_velocity(get_limited_velocity_with_thrust())
	else:
		set_linear_velocity(Vector2(0,0))

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

func remove():
	# Hack because they weren't disappearing.
	# Maybe the ship gets killed before the missile hits on the client.
	if is_network_master():
		"Server missile impact; dispatching update"
		for id in get_level().get_player_ids():
			rpc_id(id, "client_remove")
	
	queue_free()

remote func client_remove():
	print("Instructed to remove missile")
	queue_free()

func get_level():
	# What level are we in?
	#      shots ->   -> level 
	return get_parent().get_parent()

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

func _get_net_frame(offset):
	return get_level().get_net_frame(get_node("../").name, name, offset)

func build_net_frame():
	return {
		"position": position,
		"direction": direction
	}

func lerp_member(member, past, future, factor):
	set(member,
		lerp(
			past.state[member], future.state[member], factor
		)
	)
	
func lerp_angle_member(member, past, future, factor):
	set(member,
		lerp_angle(
			past.state[member], future.state[member], factor
		)
	)

func extrapolate_member(member, latest, next, factor):
	var known_delta = next.state[member] - next.state[member]
	set(member,
		next.state[member] + (known_delta * factor)
	)

func extrapolate_angle_member(member, latest, next, factor):
	var known_delta = next.state[member] - next.state[member]
	set(member,
		_anglemod(next.state[member] + (known_delta * factor))
	)
