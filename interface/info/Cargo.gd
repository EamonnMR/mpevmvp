extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _enter_tree():
	_update()

func _update():
	_clear_Grid()
	_fill_Grid()

func _clear_Grid():
	for child in $Grid.get_children():
		$Grid.remove_child(child)

func _get_label(text):
	var label = Label.new()
	label.text = text
	return label

func _fill_Grid():
	for header in [
		"Carried",
		"",
	]:
		$Grid.add_child(_get_label(header))

	for commodity_id in Client.player_ship.bulk_cargo:
		var type_data = Game.commodities[commodity_id]
		$Grid.add_child(_get_label(
			str(Client.player_ship.bulk_cargo_amount(commodity_id))
		))
		$Grid.add_child(_get_label(type_data["name"]))
