extends Node

var player_ship: Node

var client
var client_id
var player_name
var player_input: PlayerInput
var hud: Hud

signal system_changed

func start(ip, port, new_player_name):
	get_tree().connect("connected_to_server", self, "_client_connected")
	get_tree().connect("network_peer_connected", self, "_player_connected_client")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected_client")
	get_tree().connect("server_disconnected", self, "_server_disconnected_client")
	print("Starting Client")
	
	_setup_net_client(ip, port)
	_setup_client_world()

func _setup_net_client(ip, port):
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip, port)
	get_tree().set_network_peer(client)
	client_id = get_tree().get_network_unique_id()
	print("Your player ID is: ", client_id)


func _setup_client_world():
	var root = get_tree().get_root()
	var verse = preload("res://client_universe.tscn").instance()
	var background = preload("res://environment/starfield.tscn").instance()
	
	root.add_child(background)
	root.add_child(verse)

func _player_connected_client(id):
	print("Client: Player Connected: ", id)

func _client_connected():
	player_input = preload("res://gameplay/PlayerInput.tscn").instance()
	hud = preload("res://interface/hud/Hud.tscn").instance()
	player_input.set_name(str(client_id))
	player_input.set_network_master(client_id)
	var net_players = Node.new()
	net_players.set_name(Game.INPUT)
	net_players.add_child(player_input)
	get_tree().get_root().add_child(net_players)
	get_tree().get_root().add_child(hud)

func disconnect_from_server():
	print("Client trying to disconnect")
	client.disconnect_peer(1, true)
	
func _player_disconnected_client(id):
	print("Client: Player Disconnected")
	
func _server_disconnected_client(id):
	print("Client: Server Disconnected")

func get_level():
	return get_multiverse().get_level()
	
func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")

remote func fire_shot(entity_name, destination, weapon_id, shot_name):
	# print("Client.fire_shot", entity_name)
	var shot = get_level().get_node(destination + "/" + entity_name).get_shot(weapon_id)
	shot.set_name(shot_name)
	get_level().get_node("shots").add_child(shot)

remote func switch_level(new_level_name, level_data):
	get_multiverse().switch_level(new_level_name, level_data)
	player_input.switch_system()
	
	emit_signal("system_changed")

remote func remove_entity(destination, ent_name):
	print("client.remove_entity; ", destination, "/", ent_name)
	var entity_to_remove = get_level().get_node(destination + "/" + ent_name)
	# Hacky.
	if entity_to_remove is Ship:
		# TODO: Does this need to be before or after?
		entity_to_remove.emit_signal("removed")
	get_level().get_node(destination).remove_child(entity_to_remove)
	
remote func send_entity(destination, entity_data):
	print("client.send_entity: ", destination, "/", entity_data)
	get_level().receive_entity(destination, entity_data)

remote func replace_entity(destination, entity_data):
	var entity_to_remove = get_level().get_node(destination + "/" + entity_data["name"])
	get_level().get_node(destination).remove_child(entity_to_remove)
	get_level().receive_entity(destination, entity_data)

remote func complain(text):
	# TODO: HUD.Show text on screen
	# TODO: Play Sound
	print("Complain: ", text)

func current_system_id():
	return get_level().get_node("../").name
