extends CanvasLayer

func bind(player_input):
	$Panel/LeaveButton.connect("pressed", player_input, "toggle_landing")

func _on_ShipyardButton_pressed():
	$Store.show()
