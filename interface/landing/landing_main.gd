extends CanvasLayer

var spob: Node

func set_spob(new_spob: Node):
	spob = new_spob
	$Panel/Label.text = new_spob.name
	$Panel/Info.text = """
Type: %s %s
Faction: %s
	""" % [
		Game.spob_types[new_spob.spob_type]["biome"],
		Game.spob_types[new_spob.spob_type]["kind"],
		Game.factions[new_spob.faction]["name"] if new_spob.faction else "uninhabited"
	]
	$Panel/Picture.texture = new_spob.landing
	$Exchange.setup_for(spob)
	# TODO: Refresh store with available ships
	# TODO: Refessh outfitter with available outfits
	$Panel/TradeButton.show() if new_spob.commodities.size() else $Panel/TradeButton.hide()
	$Panel/ShipyardButton.show() if new_spob.faction else $Panel/ShipyardButton.hide()

func _ready():
	$Panel/LeaveButton.connect("pressed", Client.player_input, "toggle_landing")
	$ShipStore.connect("player_purchased_ship", Client.player_input, "handle_gui_player_ship_purchase")
	
func _on_ShipyardButton_pressed():
	$ShipStore.show()


func _on_Trade_Button_pressed():
	$Exchange.show()
