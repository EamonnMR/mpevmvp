extends Node

var server
var players = {}
var players_in_systems = {}
var net_players

var WAIT_TIME = 10

const MAX_PLAYERS = 6

func start(game_name, max_players):
	print("Starting Server")
	
	get_tree().connect("network_peer_connected", self, "_client_connected")
	get_tree().connect("network_peer_disconnected", self,"_client_disconnected")
	
	ServerTracker.register_game(game_name)
	
	var server = NetworkedMultiplayerENet.new()
	server.create_server(ServerTracker.DEFAULT_PORT, max_players)
	get_tree().set_network_peer(server)
	
	var verse = preload("res://server_multiverse.tscn").instance()
	verse.set_network_master(1)
	get_tree().get_root().add_child(verse)
	
	net_players = preload("res://server_input_handler.tscn").instance()
	net_players.set_name(Game.INPUT)
	get_tree().get_root().add_child(net_players)

func _setup_networking(max_players):
	var server = NetworkedMultiplayerENet.new()
	server.create_server(ServerTracker.DEFAULT_PORT, max_players)
	get_tree().set_network_peer(server)
	
func _setup_multiverse():
	var verse = preload("res://server_multiverse.tscn").instance()
	verse.set_network_master(1)
	get_tree().get_root().add_child(verse)
	
func _setup_net_players():
	net_players = preload("res://server_input_handler.tscn").instance()
	net_players.set_name(Game.INPUT)
	get_tree().get_root().add_child(net_players)
	

func _client_connected(id):
	print("Server: Client_Connected: ", id)
	var SPAWN_LEVEL = "level1"
	players[id] = {"ship": 0, "team": 0, "name": id}
	
	var player_input = preload("res://PlayerInput.tscn").instance()
	player_input.set_name(str(id))
	player_input.set_network_master(id)
	net_players.add_child(player_input)
	send_level(id, SPAWN_LEVEL, get_level(SPAWN_LEVEL))
	var ship = spawn_ship(id, Vector2(0.0, 0.0), SPAWN_LEVEL)
	send_entity(get_level(SPAWN_LEVEL), "players", ship)

func _client_disconnected(id):
	print("Server._client_disconnected: ", id)
	# TODO remove player input and entity
	players.erase(id)
	net_players.remove_child(net_players.get_child(str(id)))

func send_level(client_id, new_level_name, new_level):
	Client.rpc_id(client_id, "switch_level", new_level_name, new_level.serialize())

func send_entity(level, destination, entity):
	for id in level.get_player_ids():
		Client.rpc_id(id, "send_entity", destination, {
			"name": entity.name,
			"scene": entity.filename,
			"state": entity.serialize()
		})

func remove_entity(level, destination, entity_name):
	print('remove entity: ', entity_name, 'from level: ', level.get_node('../').name)
	for id in level.get_player_ids():
		print("Remove entity: ", destination, "/", entity_name, " from client: ", id)
		Client.rpc_id(id, "remove_entity", destination, entity_name)
	
func get_level(level):
	return get_multiverse().get_level(level)
	
func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")
	
func spawn_ship(player_id, position, level):
	print("Server Spawn Ship on level: ", level)
	var ship_type = 0
	var ship = Game.get_ship(ship_type, player_id)
	ship.team_set = [player_id]
	get_level(level).get_node("players").add_child(ship)
	ship.position = position
	return ship
	
func fire_shot(player):
	print("Server.fire_shot")
	var shot = player.get_shot()
	shot.set_network_master(1)
	player.get_level().get_node("world/shots").add_child(shot)
	Client.rpc("fire_shot", int(player.name), shot.name)

func switch_player_universe(player):
	var old_level = player.get_level().get_node("world")
	var old_level_name = player.get_level().name
	
	var new_level_name = tmp_get_other_level(old_level_name)
	print("server switch player level from ", old_level_name, " to ", new_level_name)
	var new_level = get_level(new_level_name)
	send_entity(new_level, "players", player)
	get_multiverse().switch_player_level(player, new_level_name)
	send_level(int(player.name), new_level_name, new_level)
	remove_entity(old_level, "players", player.name)

func tmp_get_other_level(old_level_name):
	# This assumes that we've got a world with exactly two levels.
	# Replace this with an overworld map, doors, etc.
	var new_level_name = "level2" if old_level_name == "level1" else "level1" # TODO: Specify destination universe
	assert(new_level_name != old_level_name)
	return new_level_name
