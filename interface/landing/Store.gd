extends Panel

func _ready():	
	var button_class = preload("res://interface/landing/IconButton.tscn")
	for ship_type in Game.ships:
		var button = button_class.instance()
		button.ship_data = Game.ships[ship_type]
		$Left/IconGrid.add_child( button )


func _on_Button_pressed():
	hide()
