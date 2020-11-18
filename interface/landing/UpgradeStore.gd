extends Store

signal player_purchased_upgrade(type, quantity)
signal player_sold_upgrade(type, quantity)

func items():
	return Game.upgrades

func _on_BuyButton_pressed():
	emit_signal("player_purchased_upgrade", selected, 1)

func _on_SellButton_pressed():
	emit_signal("player_sold_upgrade", selected, 1)
