extends CanvasLayer

func bind(player_input):
	$Panel/LeaveButton.connect("pressed", player_input, "toggle_landing")
