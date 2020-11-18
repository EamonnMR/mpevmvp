extends Item

class_name ShipDat

var max_speed: float
var turn: float
var accel: float
var max_cargo: int
var free_mass: int
var standoff: bool
var subtitle: String
var armor: float
var faction: String
var upgrades: Dictionary
var scene: PackedScene
var readout: Texture

func _init(data: Dictionary):
	print("Ship Init")
	for i in data:
		var value = data[i]
		if i == "scene":
			set(i, load("res://gameplay/ships/" + value + ".tscn"))
		elif i == "readout":
			set(i, load("res://" + value))
		elif i == "standoff":
			set(i, Game.parse_bool(value))
		elif i == "upgrades":
			set(i, Game.parse_x_dict(value))
		elif (i in self):
			set(i, value)
	print("Ship init successful")
