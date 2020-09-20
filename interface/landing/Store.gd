extends Panel

signal player_purchased_ship(type)

var selected = null

func _ready():	
	var button_class = preload("res://interface/landing/IconButton.tscn")
	
	for child in $Left/IconGrid.get_children():
		child.queue_free()
	for ship_type in Game.ships:
		var button = button_class.instance()
		button.ship_data = Game.ships[ship_type]
		button.connect("pressed", self, "on_grid_button_pressed", [ship_type])
		$Left/IconGrid.add_child( button )

func on_grid_button_pressed(id):
	update_selection(id)
	
func update_selection(id):
	var data = Game.ships[id]
	selected = id
	$ShipName.text = data["name"]
	$desc.text = data["desc"]
	print("Selected item: ", id)

func _on_leave_pressed():
	hide()

func _on_BuyButton_pressed():
	emit_signal("player_purchased_ship", selected)
	hide()
