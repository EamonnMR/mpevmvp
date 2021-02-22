extends Node2D

# Rather than having a seperate 'type', these are keyed into Game.weapons by name.

class_name Weapon

var cooldown = true
export var count: int = 1
var turret = false
var gimbal = false

var arc: int
var arc_radians: float
var projectile_scene: PackedScene
var spread_radians: float
var momentum: bool

func apply_stats():
	var data = dat()
	arc = data.arc
	projectile_scene = data.projectile_scene
	momentum = not data.no_momentum

	# Stacking weapons
	$CooldownTimer.wait_time = data.cooldown / count
	$shot_sfx.stream = data.sound_effect
	arc_radians = 2 * PI * (float(arc) / 360)
	spread_radians = 2 * PI * (float(data.spread) / 360)


func get_ship():
	return get_node("../../")

func try_shooting():
	if cooldown:
		cooldown = false
		Server.fire_shot(get_ship(), name)
		$CooldownTimer.start()

func _on_CooldownTimer_timeout():
	cooldown = true

func shot_effects():
	$shot_sfx.play()

func _parent_ship():
	return get_node("../../")
	
func _turret_facing_if_applicable(ship):
	if not arc:
		return null
	var target = ship.get_target()
	if not is_instance_valid(target):
		return null
	var angle = anglemod(ship.get_angle_to(target.position))
	if within_arc(angle, ship.direction):
		return angle
	else:
		return null

func within_arc(angle: float, direction: float) -> bool:
	print("Direction: ", direction, ", angle: ", angle, ", normalized_angle: ", abs(anglemod(angle - anglemod(direction - (PI / 4)))), ", arc: ", arc, ", arc_radians: ", arc_radians, ", in_arc: ", abs(anglemod(angle - anglemod(direction - (PI / 4)))) < arc_radians)
	return abs(anglemod(angle - anglemod(direction - (PI / 4)))) < arc_radians

func _get_angle(angle, ship) -> float:
	if angle:
		return angle
	else:
		var spread_angle = _get_spread()
		var turret_facing = _turret_facing_if_applicable(ship)
		if turret_facing:
			return anglemod(turret_facing + spread_angle)
		return anglemod(ship.direction + spread_angle)

func _get_spread():
	return anglemod((randf() * spread_radians) - (spread_radians/2))

func get_shot(angle):
	var shot = projectile_scene.instance()
	var ship = get_ship()
	shot.team_set = get_ship().team_set
	shot.init(
		dat(),
		_get_angle(angle, ship),
		ship.position,
		ship.get_linear_velocity() if momentum else Vector2(0,0),
		_parent_ship()  # The ship node
	)
	if not ship.is_network_master():
		shot_effects()
	return shot

func anglemod(angle):
	"""I wish this was a builtin"""
	var ARC = 2 * PI
	# TODO: Recursive might be too slow
	return fmod(angle + ARC, ARC)
	
func dat():
	return Game.weapons[name]
