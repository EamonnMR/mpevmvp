extends Node2D

func _on_CancelButton_pressed():
	$JoinScreen.hide()
	$FindScreen.hide()
	$HostScreen.hide()
	$MainScreen.show()

func _on_FindGameButton_pressed():
	$FindScreen.show()
	$MainScreen.hide()
	ServerTracker.connect("get_completed", self, "update_games_list")
	ServerTracker.get_game_list()

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_JoinButton_pressed():
	$JoinScreen.show()
	$MainScreen.hide()

func update_games_list(games):
	var game_rows = []
	var row_node = preload("res://interface/JoinScreenRow.tscn")
	for game in games:
		var game_row = row_node.instance()
		game_row.apply_game(game)
		game_row.connect("join_game_pressed", self, "_join_game")
		game_rows.append(game_row)
	for node in $FindScreen/GamesList.get_children():
		node.queue_free()
	for game_row in game_rows:
		$FindScreen/GamesList.add_child(game_row)
		
func _join_game(game):
	$MainScreen.hide()
	$FindScreen.hide()
	Client.start(game["address"], game["port"], $MainScreen/EnterName.text)

func _on_HostOnlineGame_pressed():
	$MainScreen.hide()
	$HostScreen.show()

func _on_Start_pressed():
	$HostScreen.hide()
	Server.start($HostScreen/ServerName.text, int($HostScreen/ServerPort.text), 100)


func _on_JoinLocalServer_pressed():
	$MainScreen.hide()
	Client.start("localhost", 26000, $MainScreen/EnterName.text)

