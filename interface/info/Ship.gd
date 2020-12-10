extends Control

func _enter_tree():
	var mps = Client.player_ship
	if mps is Ship:
		var ship: Ship = mps
		$ShipType.text = ship.data().name
		$Subtitle.text = ship.data().subtitle
		$Readout.texture = ship.data().readout
		$Equipment.text = _format_equipment(ship.upgrades)
		$ShipValue.text = "Ship Value: " + str(ship.get_value())
		$Cash.text = "Cash: " + str(ship.money)

func _format_equipment(upgrades: Dictionary) -> String:
	var equipment_strings = []
	for upgrade_type in upgrades:
		var upgrade_str: String = ""
		var upgrade: Upgrade = Game.upgrades[upgrade_type]
		var count = upgrades[upgrade_type]
		if count > 1:
			upgrade_str = str(count) + " " + upgrade.name + "s"  # Pluralizes
		else:
			upgrade_str = "a " + upgrade.name
		equipment_strings.append(upgrade_str)
	return PoolStringArray(equipment_strings).join(", ")
