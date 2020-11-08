extends Panel

func _ready():
	Client.player_input.connect("navigation_updated", self, "_update")
	Client.connect("system_changed", self, "_update")
func _update():
	var own_system_selected = Client.current_system_id() == Client.player_input.selected_system
	$SpobName.text = Client.player_input.selected_spob.name if is_instance_valid(Client.player_input.selected_spob) else ""
	$DestSystem.text = Game.systems[Client.player_input.selected_system]["System Name"] if Client.player_input.selected_system and not own_system_selected else ""
	$System.text = Game.systems[Client.current_system_id()]["System Name"]
