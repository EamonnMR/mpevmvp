extends Control

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

func _disposition_text(disposition):
	if disposition >= 0:
		return "Neutral"
	if disposition < 0:
		return "Hostile"

func _fill_Grid():
	for header in [
		"Faction",
		"Disposition",
		# "Autoattack"
	]:
		$Grid.add_child(_get_label(header))

	for faction_id in Game.factions:
		var faction = Game.factions[faction_id]
		var label_name = _get_label(faction.name)
		label_name.add_color_override("font_color", faction.color)
		$Grid.add_child(label_name)
		$Grid.add_child(_get_label(_disposition_text(faction.initial_disposition)))
		# Grid.autoattack button
