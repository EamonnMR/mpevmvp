extends Node2D

# Rather than having a seperate 'type', these are keyed into Game.weapons by name.

class_name Weapon

var cooldown = true
export var count: int = 1
var turret = false
var gimbal = false

const STATS = [
	"damage",
	"projectile_velocity",
	"projectile_lifetime",
	"projectile_scene",
	"arc"
]

var damage: int
var arc: int
var arc_radians: float
var projectile_velocity: float
var projectile_lifetime: float
var projectile_scene: PackedScene

func apply_stats():
	var data = Game.weapons[name]
	for stat in STATS:
		set(stat, data[stat])
	# Stacking weapons
	$CooldownTimer.wait_time = data["cooldown"] / count
	$shot_sfx.stream = data["sound_effect"]
	arc_radians = 2 * PI * (float(arc) / 360)


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
	var turret_facing = _turret_facing_if_applicable(ship)
	if turret_facing:
		return turret_facing
	return ship.direction

func get_shot(angle):
	var shot = projectile_scene.instance()
	var ship = get_ship()
	shot.team_set = get_ship().team_set
	shot.init(
		projectile_velocity,
		damage,
		projectile_lifetime,
		_get_angle(angle, ship),
		ship.position,
		ship.get_linear_velocity(),
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
