extends Node

var server
var players = {}
var players_in_systems = {}

var WAIT_TIME = 10

const MAX_PLAYERS = 6

var min_players

func start(game_name, min_players_input, max_players):
	print("Starting Server")
	
	min_players = min_players_input
	
	get_tree().connect("network_peer_connected", self, "_client_connected")
	get_tree().connect("network_peer_disconnected", self,"_client_disconnected")
	
	ServerTracker.register_game(game_name)
	
	var server = NetworkedMultiplayerENet.new()
	server.create_server(ServerTracker.DEFAULT_PORT, max_players)
	get_tree().set_network_peer(server)
	print("Awaiting Clients")

remote func request_lobby_update(player_data):
	print("Server.request_lobby_update")
	players[get_tree().get_rpc_sender_id()] = player_data
	push_lobby_update()

func push_lobby_update():
	print("Server.push_lobby_update")
	Client.rpc("remote_lobby_update", players)

func _client_connected(id):
	print("Server: Client_Connected: ", id)
	players[id] = {"ship": 0, "team": 0, "name": id}
	push_lobby_update()
	if len(players) >= min_players:
		start_countdown()
	

func _client_disconnected(id):
	print("Server._client_disconnected: ", id)
	players.erase(id)
	push_lobby_update()
	
func start_countdown():
	var game_start_countdown = Timer.new()
	game_start_countdown.connect("timeout", self, "_on_game_start_countdown_timeout") 
	add_child(game_start_countdown)
	game_start_countdown.set_wait_time(WAIT_TIME)
	game_start_countdown.one_shot = true
	game_start_countdown.start()
	Client.rpc("start_countdown")
	
func _on_game_start_countdown_timeout():
	print("Starting game")
	Client.rpc("start_game")
	var verse = preload("res://server_multiverse.tscn").instance()
	var world = verse.get_node("level1")
	verse.set_network_master(1)
	get_tree().get_root().add_child(verse)
	
	var net_players = preload("res://server_input_handler.tscn").instance()
	net_players.set_name(Game.INPUT)
	get_tree().get_root().add_child(net_players)
	print("ADDED NET PLAYERS")

	var spawn_position = Vector2(10,10)
	var spawn_position_counter = 0
	for player_id in players:
		spawn_position_counter += 1
		var player = preload("res://PlayerInput.tscn").instance()
		player.set_name(str(player_id))
		player.set_network_master(player_id)
		net_players.add_child(player)
		spawn_ship(player_id, spawn_position * spawn_position_counter, "level1")
	
func send_entity(level, destination, entity):
	for id in level.get_player_ids():
		Client.rpc_id(id, "send_entity", destination, entity.serialize())

func remove_entity(level, destination, entity):
	for id in level.get_player_ids():
		Client.rpc_id(id, "remove_entity", destination, entity.name)
	
func get_level(level):
	return get_multiverse().get_level(level)
	
func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")
	
func spawn_ship(player_id, position, level):
	print("Server Spawn Ship on level: ", level)
	var ship_type = players[player_id]["ship"]
	var ship = Game.get_ship(ship_type, player_id)
	get_level(level).get_node("players").add_child(ship)
	ship.position = position
	Client.rpc("spawn_ship", player_id, ship_type, position)
	
func fire_shot(player):
	print("Server.fire_shot")
	var shot = player.get_shot()
	shot.set_network_master(1)
	player.get_level().get_node("world/shots").add_child(shot)
	Client.rpc("fire_shot", int(player.name), shot.name)

var test_level = false

func switch_player_universe(player):
	test_level = not test_level
	print("server switch player universe")
	var new_level_name = "level2" if  test_level else "level1" # TODO: Specify destination universe
	var new_level = get_level(new_level_name)
	var old_level = player.get_level().get_node("world")
	send_entity(new_level, "players", player)
	
	get_multiverse().switch_player_level(player, new_level_name)
	
	Client.rpc_id(int(player.name), "switch_level", new_level_name, new_level.serialize())
	
	remove_entity(old_level, "players", player.name)
