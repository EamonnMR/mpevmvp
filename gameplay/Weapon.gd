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
	"turret",
	"gimbal"
]

var damage: int
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
	if gimbal:
		print("Gimbal is true")


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
	if (not turret) and (not gimbal):
		return null
	var target = ship.get_target()
	var angle = anglemod(ship.get_angle_to(target.position))
	if turret:
		return angle
	elif gimbal and within_quadrent(angle, ship.direction):
		return angle
	else:
		return null

func within_quadrent(angle: float, direction: float) -> bool:
	return abs(anglemod(angle - anglemod(direction - (PI / 4)))) < PI / 2

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
