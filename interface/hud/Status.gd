extends Panel

func _ready():
	# Client.connect("system_changed", self, "_connect")
	Client.connect("player_ship_set", self, "_connect")
	
func _connect(_ship):
	print("Display got player ship set")
	if Client.player_ship and Client.player_ship is Ship:
		print("connected stats")
		$health_bar.show()
		Client.player_ship.connect("status_updated", self, "_update")
		Client.player_ship.connect("money_updated", self, "_update")
		$health_bar.max_value = Client.player_ship.max_health
		_update()
	else:
		$health_bar.hide()
		$money_value.hide()

func _update():
	print("Status updated")
	$health_bar.value = Client.player_ship.health
	$money_value.text = str(Client.player_ship.money)
