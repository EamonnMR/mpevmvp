extends Control

func _ready():
	var mps = Client.player_ship
	if mps is Ship:
		var ship: Ship = mps
		$ShipType.text = ship.data().name
		$Subtitle.text = ship.data().subtitle
		$Readout.texture = ship.data().readout
		$Equipment.text = _format_equipment(ship.upgrades)
		$ShipValue.text = "Ship Value: " + str(ship.get_value())
		$Cash.text = "Cash: " + str(ship.money)
		
func _format_equipment(upgdares: Dictionary) -> String:
	return "TODO: Equipment"
