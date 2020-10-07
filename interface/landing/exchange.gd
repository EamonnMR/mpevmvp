extends Panel

func setup_for(spob):
	_clear_rows()
	_create_rows(spob)

func _clear_rows():
	for child in $Rows.get_children():
		$Rows.remove_child(child)
		
func _get_label(text):
	var label = Label.new()
	label.text = text
	return label
	

func _create_rows(spob):
	for header in [
		"Owned",
		"",
		"Price",
		"",
		"Buy",
		"Sell",
	]:
		$Rows.add_child(_get_label(header))

	for commodity_id in spob.commodities:
		var price_factor = spob.commodities[commodity_id]
		var type_data = Game.commodities[commodity_id]

		$Rows.add_child(_get_label("0"))  # TODO: ship.commodities[commodity_id]
		$Rows.add_child(_get_label(type_data["name"]))
		$Rows.add_child(_get_label(str(type_data["prices"][price_factor])))
		$Rows.add_child(_get_label(Game.comodity_price_factor_names[price_factor]))

		var buy_button = Button.new()
		buy_button.text = "buy"
		buy_button.connect("pressed", Client.player_input, "purchase_commodity", [1])
		$Rows.add_child(buy_button)

		var sell_button = Button.new()
		sell_button.text = "sell"
		sell_button.connect("pressed", Client.player_input, "sell_commodity", [1])
		$Rows.add_child(sell_button)


func _on_leave_pressed():
	hide()
