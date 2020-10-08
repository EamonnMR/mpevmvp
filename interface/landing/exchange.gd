extends Panel

func setup_for(spob):
	reset_exchange(spob)
	_bind_ship_updates(spob)
	
func reset_exchange(spob):
	_clear_rows()
	_create_rows(spob)
	
func _bind_ship_updates(spob):
	Client.player_ship.connect("cargo_updated", self, "reset_exchange", [spob])

func _clear_rows():
	for child in $Rows.get_children():
		$Rows.remove_child(child)
		
func _get_label(text):
	var label = Label.new()
	label.text = text
	return label
	
func _get_button(button_text, func_name, spob, enabled):
	var button = Button.new()
	button.text = button_text
	button.disabled = not enabled
	button.connect("pressed", Client.player_input, func_name, [1, "spobs/" + spob.name])
	return button

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
		var price = type_data["prices"][price_factor]
		$Rows.add_child(_get_label(
			str(Client.player_ship.bulk_cargo_amount(commodity_id))
		))
		$Rows.add_child(_get_label(type_data["name"]))
		$Rows.add_child(_get_label(str(price)))
		$Rows.add_child(_get_label(Game.comodity_price_factor_names[price_factor]))
		$Rows.add_child(_get_button(
			"buy", "purchase_commodity", spob,
			Client.player_ship.free_cargo() > 1 and Client.player_ship.money >= price
		))
		$Rows.add_child(_get_button(
			"sell", "sell_commodity", spob,
			Client.player_ship.bulk_cargo_amount(commodity_id) > 0
		))

func _on_leave_pressed():
	hide()
