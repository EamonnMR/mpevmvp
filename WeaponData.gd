extends DataRow
class_name WeaponData

var id: int
var damage: int
var projectile_velocity: int
var projectile_lifetime: float
var cooldown: float
var arc: int
var projectile_scene: PackedScene
var sound_effect: AudioStream

func _init(data: Dictionary):
	init(data)
