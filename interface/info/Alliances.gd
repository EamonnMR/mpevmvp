extends Control

func _ready():
	Client.connect("player_added", self, "_update")
	Client.connect("player_left", self, "_update")
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
	for player_id in Client.players:
		var player = Client.players[player_id]
		$Grid.add_child(_get_label(player["nick"]))
