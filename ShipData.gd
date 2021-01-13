extends Item

class_name ShipDat

var max_speed: float
var turn: float
var accel: float
var max_cargo: int
var free_mass: int
var standoff: bool
var joust: bool
var wimpy: bool
var subtitle: String
var armor: float
var faction: int
var upgrades: Dictionary
var scene: PackedScene
var readout: Texture

func _init(data: Dictionary):
	init(data)
	upgrades = parse_x_dict(data["upgrades"])

func apply(ship):
	for stat in get_keys():
		if stat in ship:
			var dat = get(stat)
			if dat is Dictionary:
				dat = dat.duplicate()
			ship.set(stat, dat)

func pdb():
	breakpoint
