extends Item

class_name Upgrade

var mass: int
var effects: Dictionary

func _init(csv_row: Dictionary):
	id = int(csv_row["id"])
	name = csv_row["name"]
	mass = int(csv_row["mass"])
	icon = csv_row["icon"]
	desc = csv_row["desc"]
	effects = {}
	
	var effect_counter = 0
	while true:
		var col_name = "effect_" + str(effect_counter)
		if not col_name in csv_row:
			break
		var effect_type: String = csv_row[col_name]
		if not effect_type:
			break
		var effect_value: String = csv_row["value_" + str(effect_counter)]
		effects[effect_type] = effect_value
		effect_counter += 1

func can_add(ship, count: int) -> bool:
	if ship.free_mass >= mass:
		return true
	return false

func apply(ship, count: int):
	for effect in effects:
		if effect == "weapon":
			var weapon_id = effects[effect]
			if weapon_id in ship.weapons:
				ship.weapons[weapon_id] += count
			else:
				ship.weapons[weapon_id] = count
		if effect == "armor":
			ship.armor += float(effects[effect]) * count
