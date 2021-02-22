extends Panel

var empty_selection_texture = load("res://sprites/emr_cc_by/empty.png")

func _ready():
	Client.player_input.connect("targeting_updated", self, "_selection_changed")
	Client.connect("system_changed", self, "_selection_changed")

func _get_ship() -> Ship:
	var ship: Ship = Client.player_input.selected_ship
	if is_instance_valid(ship):
		return ship
	else:
		return null

func _selection_changed():
	var ship = _get_ship()
	if ship:
		ship.connect("status_updated", self, "_update")
		ship.connect("destroyed", self, "_selection_changed")
		ship.connect("disappeared", self, "_selection_changed")
	_update()

func _physics_process(delta):
	var ship = _get_ship()
	if ship:
		update_health(ship)
		
func update_health(ship):
	$Health.value = ship.health
	if ship.is_disabled():
		$Subtitle.text = "<disabled>"
	
func _update():
	var ship = _get_ship()
	if ship:
		$Name.text = ship.data().name
		$Subtitle.text = ship.data().subtitle
		$Readout.texture = ship.data().readout
		$Health.max_value = ship.armor
		update_health(ship)
		var players = Client.players
		var ship_name = ship.name
		if ship.is_player() and ship.name in players:
			$Faction.text = Client.players[ship.name]["nick"]
		else:
			$Faction.text = Game.factions[ship.faction].name
	else:
		$Name.text = "[no target]"
		$Subtitle.text = "---"
		$Faction.text = "---"
		$Readout.texture = empty_selection_texture
		$Health.value = 0
		$Health.max_value = 1
