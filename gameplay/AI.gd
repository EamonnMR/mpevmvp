extends Node

# TODO: This stuff ought to be configured at spawn time, based on present weapons
export var accel_margin = PI / 2
export var accel_distance = 10
export var shoot_margin = PI / 2
export var shoot_distance = 200
export var max_target_distance = 1000
export var destination_margin = 100

var target
var ideal_face
var destination
var parent: Ship
var faction_dat
var arrived: bool

# This is the output of the AI - ship.tscn uses these to move.
var puppet_direction_change: int = 0
var puppet_shooting = false
var puppet_thrusting = false
var puppet_braking = false

# I don't think we'll need these
var puppet_jumping = false
var puppet_selected_system: String = ""
var puppet_landing = false

func _anglemod(angle: float) -> float:
	return fmod(angle, PI * 2)

func _ready():
	parent = get_node("../")
	faction_dat = Game.factions[parent.faction]
	parent.connect("took_damage_from", self, "_ship_took_damage")

func _physics_process(delta):
	if not _hunt(delta):
		_idle_fly(delta)

func _idle_fly(delta):
	if _is_at_destination():
		if not arrived:
			var wait_time = randf()
			print("Arrived, waiting ", wait_time, " seconds before picking a new spob")
			$IdleTimer.start(wait_time)
		arrived = true
	if not destination:
		var spobs = parent.get_level().get_node("world/spobs").get_children()
		if spobs:
			destination = Game.random_select(
				spobs
			).position
		else:
			print("AI: System empty; nowhere to idle to")
			# TODO: Just leaveu
	if destination:
		get_ideal_face_and_direction_change(destination, delta)
		puppet_shooting = false
		puppet_thrusting = _should_thrust_idle()
		puppet_braking = _should_brake_idle()

func _is_at_destination():
	return (destination != null) and parent.position.distance_to(destination) < destination_margin

func _hunt(delta):
	
	if not target or not is_instance_valid(target):  # or is idling:
		target = _find_target()
	puppet_direction_change = 0
	ideal_face = null
	if(target):
		get_ideal_face_and_direction_change(target.position, delta)
		puppet_shooting = _should_shoot()
		puppet_thrusting = _should_thrust()
		puppet_braking = _should_brake()
		return true
	return false
	

func distance_comparitor(lval, rval):
	# For sorting other nodes by how close they are
	var parent = get_node("../")
	var ldist = lval.position.distance_to(parent.position)
	var rdist = rval.position.distance_to(parent.position)
	return ldist < rdist
	
func get_ideal_face_and_direction_change(at: Vector2, delta):
	var impulse = _constrained_point(
		parent, parent.direction, parent.turn * delta, at
	)
	puppet_direction_change = _flatten_to_sign(impulse[0])
	ideal_face = impulse[1]

func _constrained_point(subject, current_rotation, max_turn, position: Vector2):
	# For finding the right direction and amount to turn when your rotation speed is limited
	var ideal_face = _anglemod(subject.get_angle_to(position))
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

func _find_target():
	var level = get_node("../../../")
	var possible_targets = []
	var players = level.get_node("players").get_children()
	# TODO: Probably filter before sorting here
	possible_targets += players
	var npcs = level.get_node("npcs").get_children()
	possible_targets += npcs
	possible_targets.sort_custom(self, "distance_comparitor")
	for possible_target in possible_targets:
		if get_node("../").position.distance_to(possible_target.position) > max_target_distance:
			continue
		if not possible_target.is_alive():
			continue
		if is_instance_valid(possible_target):
			if is_faction_enemy(possible_target) or (possible_target.is_player() and is_player_enemy(possible_target)):
				return possible_target
	return null

func is_faction_enemy(ship):
	return ship.faction != faction_dat["id"] and int(ship.faction) in faction_dat["enemies"]

func is_player_enemy(ship):
	return faction_dat["initial_disposition"] < 0

# TODO: Add a timer for this
func _on_ai_rethink_timer_timeout():
	var target = _find_target()

func _flatten_to_sign(value):
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0

func _should_thrust():
	return (
		target
		and ideal_face
		and _facing_right_way_to_accel()
		and (_far_enough_to_accel() or parent.joust)
	)
	
func _should_thrust_idle():
	return (
		destination != null
		and ideal_face
		and _facing_right_way_to_accel()
	)

func _facing_right_way_to_accel():
	return _facing_within_margin(accel_margin)

func _far_enough_to_accel():
	return parent.position.distance_to(target.position) > accel_distance

func _should_brake():
	return parent.standoff and target and is_instance_valid(target) and parent.position.distance_to(target.position) < shoot_distance

func _should_brake_idle():
	return arrived

func _facing_within_margin(margin):
	""" Relies on 'ideal face' being populated """
	return ideal_face and abs(_anglemod(ideal_face - parent.direction)) < margin

func _should_shoot():
	return target and _facing_within_margin(shoot_margin) and parent.position.distance_to(target.position) < shoot_distance

func _ship_took_damage(source):
	# Just get real mad at anything that does damage
	target = source


func _on_IdleTimer_timeout():
	destination = null
	arrived = false

