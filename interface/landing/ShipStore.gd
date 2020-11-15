extends Store

signal player_purchased_ship(type)

func items():
	return Game.ships

func _on_BuyButton_pressed():
	emit_signal("player_purchased_ship", selected)
	hide()
