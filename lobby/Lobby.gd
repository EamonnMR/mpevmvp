extends Node2D

var team_lists
var player_id

func _ready():
	team_lists = {
		0: $Panel/TeamZero,
		1: $Panel/TeamOne,
	}
	
	$Panel/ChooseTeam.add_item("Red Team", 0)
	$Panel/ChooseTeam.add_item("Blue Team", 1)
	
	for ship_type_id in Game.SHIP_TYPES:
		var ship_type = Game.SHIP_TYPES[ship_type_id]
		$Panel/ChooseShip.add_item(ship_type["name"], ship_type_id)
	
	push_player_selections()

func set_player_id(id):
	player_id = id;
	
func update_player_selections(player_data):
	$Panel/ChooseTeam.selected = player_data["team"]
	$Panel/ChooseShip.selected = player_data["ship"]

func push_player_selections():
	Client.lobby_update({
		"team": $Panel/ChooseTeam.selected,
		"ship": $Panel/ChooseShip.selected,
		"name": Main.player_name
	})

func update_player_list(players):
	# Clear player lists
	for list in team_lists.values():
		for child in list.get_children():
			child.queue_free()
	for id in players:
		var player = players[id]
		var player_line = preload("res://lobby/LobbyPlayer.tscn").instance()
		player_line.player = player
		
		team_lists[player["team"]].add_child(player_line)
		
		if id == Main.client_id:
			update_player_selections(player)

func _on_Leave_pressed():
	Client.disconnect_from_server()

func _on_ChooseTeam_item_selected(index):
	push_player_selections()

func _on_ChooseShip_item_selected(index):
	push_player_selections()
	
func start_countdown():
	$Panel/countdown_progress.show()
	$Panel/countdown_progress/Timer.start()
	$Panel/countdown_progress/ProgressBar.max_value = Server.WAIT_TIME
	$Panel/countdown_progress/ProgressBar.value = Server.WAIT_TIME

func _on_countdown_progress_timeout():
	$Panel/countdown_progress/ProgressBar.value -= 1
