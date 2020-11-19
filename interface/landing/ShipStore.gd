extends Store

signal player_purchased_ship(type)

func items():
	return Game.ships

func _on_BuyButton_pressed():
	emit_signal("player_purchased_ship", selected)
	hide()

func get_count(type) -> int:
	print("ShipStore getcount")
	if Client.player_ship.type == type:
		return 1
	else:
		return 0
