extends Panel

var empty_selection_texture = load("res://sprites/emr_cc_by/empty.png")

func _ready():
	Client.player_input.connect("targeting_updated", self, "_selection_changed")
	Client.connect("system_changed", self, "_selection_changed")

func _selection_changed():
	var ship: Ship = Client.player_input.selected_ship
	if is_instance_valid(ship):
		ship.connect("status_updated", self, "_update")
		ship.connect("destroyed", self, "_selection_changed")
		ship.connect("removed", self, "_selection_changed")
	_update()

func _update():
	var ship: Ship = Client.player_input.selected_ship
	if is_instance_valid(ship):
		$Name.text = ship.data().name
		$Subtitle.text = ship.data().subtitle
		$Readout.texture = ship.data().readout
		$Health.max_value = ship.armor
		$Health.value = ship.health
		if ship.is_player():
			$Faction.text = "player"
		else:
			$Faction.text = Game.factions[ship.faction]["name"]
	else:
		$Name.text = "[no target]"
		$Subtitle.text = "---"
		$Faction.text = "---"
		$Readout.texture = empty_selection_texture
		$Health.value = 0
		$Health.max_value = 1
