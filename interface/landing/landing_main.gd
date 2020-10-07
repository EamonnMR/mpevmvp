extends CanvasLayer

var spob: Node

func set_spob(new_spob: Node):
	spob = new_spob
	$Panel/Label.text = new_spob.name
	$Panel/Picture.texture = new_spob.landing
	$Exchange.setup_for(spob)
	# TODO: Refresh store with available ships
	# TODO: Refessh outfitter with available outfits
	# TODO: Refresh trade center with prices

func _ready():
	$Panel/LeaveButton.connect("pressed", Client.player_input, "toggle_landing")
	$Store.connect("player_purchased_ship", Client.player_input, "handle_gui_player_ship_purchase")
	
func _on_ShipyardButton_pressed():
	$Store.show()


func _on_Trade_Button_pressed():
	$Exchange.show()
