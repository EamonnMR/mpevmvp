extends NinePatchRect

func _ready():
	print("Status.ready")
	Client.connect("player_ship_set", self, "_connect")
	
func _connect():
	print("Status._connect")
	if Client.player_ship and Client.player_ship is Ship:
		print("connected stats")
		$health_bar.show()
		Client.player_ship.connect("status_updated", self, "_update")
		Client.player_ship.connect("money_updated", self, "_update")
		Client.player_ship.connect("destroyed", self, "_connect")
		Client.player_ship.connect("tree_exiting", self, "_connect")
		$health_bar.max_value = Client.player_ship.armor
		_update()
	else:
		$health_bar.hide()
		$money_value.hide()

func _update():
	print("Status updated")
	$health_bar.value = Client.player_ship.health
	$money_value.text = str(Client.player_ship.money)
