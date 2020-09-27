extends Node

var server
var players = {}
var players_in_systems = {}
var net_players

var WAIT_TIME = 5

const MAX_PLAYERS = 6

func start(game_name, max_players):
	print("Starting Server: ", game_name, ", ", max_players)
	
	get_tree().connect("network_peer_connected", self, "_client_connected")
	get_tree().connect("network_peer_disconnected", self,"_client_disconnected")
	
	var server = NetworkedMultiplayerENet.new()
	server.create_server(ServerTracker.DEFAULT_PORT, max_players)
	get_tree().set_network_peer(server)
	
	call_deferred("_setup_server_nodes", game_name)

func _setup_server_nodes(game_name):
	# Needs to be called deferred to avoid
	# ERROR: add_child: Condition "data.blocked > 0" is true.

	print("Adding Universe")
	var verse = preload("res://server_multiverse.tscn").instance()
	verse.set_network_master(1)
	get_tree().get_root().add_child(verse)
	
	print("Adding net players")
	net_players = preload("res://server_input_handler.tscn").instance()
	net_players.set_name(Game.INPUT)
	get_tree().get_root().add_child(net_players)
	
	ServerTracker.register_game(game_name)

func _client_connected(id):
	print("Server: Client_Connected: ", id)
	players[id] = {"name": id, "ship_type": 0}
	
	var player_input = preload("res://gameplay/PlayerInput.tscn").instance()
	player_input.set_name(str(id))
	player_input.set_network_master(id)
	net_players.add_child(player_input)
	
	spawn_player(id)
	
func _client_disconnected(id):
	print("Server._client_disconnected: ", id)
	_remove_player_entity_by_id(id)
	players.erase(id)
	net_players.remove_child(net_players.get_node(str(id)))

func send_level(client_id, new_level_name, new_level):
	assert(new_level != null)
	Client.rpc_id(client_id, "switch_level", new_level_name, new_level.serialize())

func send_entity(level, destination, entity):
	for id in level.get_player_ids():
		Client.rpc_id(id, "send_entity", destination, {
			"name": entity.name,
			"scene": entity.filename,
			"state": entity.serialize()
		})

func replace_entity(level, destination, entity, replace_on_server=false):
	for id in level.get_player_ids():
		Client.rpc_id(id, "replace_entity", destination, {
			"name": entity.name,
			"scene": entity.filename,
			"state": entity.serialize()
		})
	if replace_on_server:
		print("Also removing entity on server")
		var dest = level.get_node(destination)
		var old_node = dest.get_node(entity.name)
		dest.remove_child(old_node)
		old_node.queue_free()
		dest.add_child(entity)

func remove_entity(level, destination, entity_name, remove_on_server=false):
	if remove_on_server:
		print("Also removing entity on server")
		var old_node = level.get_node(destination).get_node(entity_name)
		level.get_node(destination).remove_child(old_node)
		old_node.queue_free()
	print('remove entity: ', entity_name, 'from level: ', level.get_node('../').name)
	for id in level.get_player_ids():
		print("Remove entity: ", destination, "/", entity_name, " from client: ", id)
		Client.rpc_id(id, "remove_entity", destination, entity_name)
	
func get_level(level):
	return get_multiverse().get_level(level)

func get_level_for_player(player_id):
	return get_level(players[player_id]["level"])
	
func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")

func set_respawn_timer(player_id):
	# TODO: Stick this right into world.tscn and show/hide it?
	var timer = Timer.new()
	timer.connect("timeout", self, "_respawn_player", [player_id, timer]) 
	add_child(timer)
	timer.set_wait_time(WAIT_TIME)
	timer.one_shot = true
	timer.start()
	print("Set respawn timer for player")
	
func _respawn_player(player_id, timer):
	if not _is_player_alive(player_id):
		_remove_player_entity_by_id(player_id)
		spawn_player(player_id)
	else:
		print("Tried to respawn already spawned player: ", player_id)
	remove_child(timer)
	timer.queue_free()
	
remote func purchase_ship(id):
	var player_id = get_tree().get_rpc_sender_id()
	players[player_id]["ship_type"] = id
	var level = get_level_for_player(player_id)
	var player = level.get_node("players/" + str(player_id))
	var new_player = create_ship(player_id, id, player.position)
	print("Player purchased ship! New Ship type: ", id)
	print("New Ship Data:" )
	print(new_player.serialize())
	replace_entity(level, "players", new_player, true)

func spawn_player(player_id, level="128"):
	print("Server.spawn_player: ", player_id)
	var SPAWN_LEVEL = "128"
	players[player_id]["level"] = SPAWN_LEVEL
	print("level: ", SPAWN_LEVEL, " (", get_level(SPAWN_LEVEL), ")")
	send_level(player_id, SPAWN_LEVEL, get_level(SPAWN_LEVEL))
	var ship = create_ship(player_id, players[player_id]["ship_type"], Vector2(0.0, 0.0), SPAWN_LEVEL)
	send_entity(get_level(SPAWN_LEVEL), "players", ship)
	
func spawn_npc(level):
	print("Server.spawn: ")
	print("level: ", level, " (", get_level(level), ")")
	var ship = create_npc("0", Vector2(0.0, 0.0), level)
	ship.team_set = ["pirates"]
	send_entity(get_level(level), "npcs", ship)

func create_ship(player_id, type, position, level=null):
	print("Server Spawn Ship on level: ", level)
	var ship = Game.get_ship(type, player_id)
	if level:
		get_level(level).get_node("players").add_child(ship)
	ship.position = position
	ship.team_set = [player_id]
	return ship
	
func create_npc(type, position, level=null):
	print("Server Spawn Ship on level: ", level)
	var ship = Game.get_npc_ship(type)
	ship.add_child(preload("res://gameplay/AI.tscn").instance())
	ship.team_set = ["pirates"]
	if level:
		get_level(level).get_node("npcs").add_child(ship)
	ship.position = position
	return ship
	
func fire_shot(ship):
	# print("Server.fire_shot")
	var shot = ship.get_shot()
	shot.set_network_master(1)
	ship.get_level().get_node("world/shots").add_child(shot)
	Client.rpc("fire_shot", ship.name, ship.get_node("../").name, shot.name)

func switch_player_universe(player):
	var old_level = player.get_level().get_node("world")
	var old_level_name = player.get_level().name
	
	var new_level_name = player.get_input_state().puppet_selected_system
	print("Impulse: ", new_level_name, " --> ", old_level_name)
	if new_level_name != old_level_name:
		var new_level = get_level(new_level_name)
		send_entity(new_level, "players", player)
		get_multiverse().switch_player_level(player, new_level_name)
		send_level(int(player.name), new_level_name, new_level)
		remove_entity(old_level, "players", player.name)

func _remove_player_entity_by_id(id, remove_on_server=true):
	print("Removing player entity by ID")
	var level = get_level_for_player(id)
	remove_entity(level, "players", str(id), remove_on_server)
	return level

func _is_player_alive(id):
	return _get_player_node(id).is_alive()

func _get_player_node(id):
	var level = get_level_for_player(id)
	return level.get_node("players/" + str(id))
