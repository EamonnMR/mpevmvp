extends CanvasLayer

func bind(player_input):
	$Panel/LeaveButton.connect("pressed", player_input, "toggle_landing")
	$Store.connect("player_purchased_ship", player_input, "handle_gui_player_ship_purchase")
	
func _on_ShipyardButton_pressed():
	$Store.show()
