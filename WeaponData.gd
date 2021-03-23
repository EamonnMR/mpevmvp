extends DataRow
class_name WeaponData

var id: int
var damage: int
var projectile_velocity: int
var projectile_lifetime: float
var cooldown: float
var arc: int
var projectile_scene: PackedScene
var sound_effect: Resource
var aoe: int
var guided_turn: float
var guided_accel: float
var spread: float
var no_momentum: bool
var count: int
var use_ammo: bool
var ammo_oft: int

func _init(data: Dictionary):
	init(data)
