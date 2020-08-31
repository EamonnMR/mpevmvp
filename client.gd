extends Node

var lobby
var client
var client_id
var player_name

func start(ip, port, new_player_name):
	get_tree().connect("connected_to_server", self, "_client_connected")
	get_tree().connect("network_peer_connected", self, "_player_connected_client")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected_client")
	get_tree().connect("server_disconnected", self, "_server_disconnected_client")
	print("Starting Client")
	
	lobby = load("res://lobby/Lobby.tscn").instance()
	get_tree().get_root().add_child(lobby)
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip, port)
	get_tree().set_network_peer(client)
	client_id = get_tree().get_network_unique_id()
	print("Your player ID is: ", client_id)

remote func remote_lobby_update(players):
	print("Client.remote_lobby_update")
	assert(get_tree().get_rpc_sender_id() != get_tree().get_network_unique_id())
	print(players)
	lobby.update_player_list(players)
	
func lobby_update(player_data):
	print("Client.lobby_update")
	Server.rpc_id(1, "request_lobby_update", player_data)

func client_start_game():
	lobby.queue_free()

func _player_connected_client(id):
	print("Client: Player Connected: ", id)

func _client_connected():
	print("Connected OK")

func disconnect_from_server():
	print("Client trying to disconnect")
	client.disconnect_peer(1, true)
	
func _player_disconnected_client(id):
	print("Client: Player Disconnected")
	
func _server_disconnected_client(id):
	print("Client: Server Disconnected")

remote func start_countdown():
	lobby.start_countdown()
	
remote func start_game():
	get_tree().get_root().remove_child(lobby)
	var verse = preload("res://client_universe.tscn").instance()
	var world = verse.get_node("level1/world")
	var player_scene = preload("res://PlayerInput.tscn").instance()
	player_scene.set_name(str(client_id))
	player_scene.set_network_master(client_id)
	get_tree().get_root().add_child(verse)
	
	var net_players = Node.new()
	net_players.set_name(Game.INPUT)
	net_players.add_child(player_scene)
	
	get_tree().get_root().add_child(net_players)
	
func get_level():
	return get_multiverse().get_level()
	
func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")

remote func spawn_ship(player_id, ship_type, position):
	print("Client.spawn_ship")
	var ship = Game.get_ship(ship_type, player_id)
	get_level().get_node("players").add_child(ship)
	ship.position = position

remote func fire_shot(player_id, shot_name):
	print("Client.fire_shot", player_id)
	var shot = get_level().get_player_entity(player_id).get_shot()
	shot.set_name(shot_name)
	get_level().get_node("shots").add_child(shot)

remote func switch_level(new_level_name, level_data):
	print("clinent switch universe")
	get_multiverse().switch_level(new_level_name, level_data)

remote func remove_entity(destination, ent_name):
	print("client.remove_entity; ", destination, "/", ent_name)
	var entity_to_remove = get_level().get_node(destination + "/" + ent_name)
	get_level().get_node(destination).remove_child(entity_to_remove)

remote func send_entity(destination, entity_data):
	get_level().receive_entity(destination, entity_data)
	get_level().receive_entity(destination, entity_data)
