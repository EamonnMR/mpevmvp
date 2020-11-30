extends Node2D

# Rather than having a seperate 'type', these are keyed into Game.weapons by name.

class_name Weapon

var cooldown = true
export var count: int = 1

const STATS = [
	"damage",
	"projectile_velocity",
	"projectile_lifetime",
	"projectile_scene"
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


func get_ship():
	return get_node("../../")

func try_shooting():
	if cooldown:
		print("Server: Firing: ", name)
		cooldown = false
		Server.fire_shot(get_ship(), name)
		$CooldownTimer.start()

func _on_CooldownTimer_timeout():
	cooldown = true

func shot_effects():
	$shot_sfx.play()

func _parent_ship():
	return get_node("../../")

func get_shot():
	print("Get shot")
	var shot = projectile_scene.instance()
	var ship = get_ship()
	shot.team_set = get_ship().team_set
	shot.init(
		projectile_velocity,
		damage,
		projectile_lifetime,
		ship.direction,
		ship.position,
		ship.get_linear_velocity(),
		_parent_ship()  # The ship node
	)
	if not ship.is_network_master():
		shot_effects()
	return shot

