extends Node

var players = {}
var player_ship: Node

var client
var client_id
var player_nick
var player_input: PlayerInput
var hud: Hud

signal system_changed
signal player_ship_set
signal player_added
signal player_left

var latency = 100

var time: int

func time():
	# return OS.get_system_time_msecs() - latency
	return time

func time_update():
	time = OS.get_system_time_msecs() - latency
	return time

func start(ip, port, player_nick):
	get_tree().connect("connected_to_server", self, "_client_connected")
	get_tree().connect("network_peer_connected", self, "_player_connected_client")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected_client")
	get_tree().connect("server_disconnected", self, "_server_disconnected_client")
	print("Starting Client")
	
	_setup_net_client(ip, port)
	_setup_client_world()
	self.player_nick = player_nick

remote func update_player_nick(player_id, new_nick):
	players[str(player_id)]["nick"] = new_nick
	print("Player nick updated: ", player_id, ": ", new_nick)
	
remote func update_player_list(players):
	self.players = players
	print("Players: ", players)
	print("My client id:", client_id)
	emit_signal("player_added")
	
remote func add_net_player(player_id):
	players[str(player_id)] = {"nick": str(player_id)}
	emit_signal("player_added")
	
remote func remove_net_player(player_id):
	players.erase(str(player_id))
	emit_signal("player_left")

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
	print("In Client Connected")
	player_input = preload("res://gameplay/PlayerInput.tscn").instance()
	hud = preload("res://interface/hud/Hud.tscn").instance()
	player_input.set_name(str(client_id))
	player_input.set_network_master(client_id)
	var net_players = Node.new()
	net_players.set_name(Game.INPUT)
	net_players.add_child(player_input)
	get_tree().get_root().add_child(net_players)
	get_tree().get_root().add_child(hud)
	Server.rpc_id(1, "set_player_nick", player_nick)

func disconnect_from_server():
	print("Client trying to disconnect")
	client.disconnect_peer(1, true)
	
func _player_disconnected_client(id):
	print("Client: Player Disconnected")
	
func _server_disconnected_client(id):
	print("Client: Server Disconnected")
	
func set_player_ship(player_ship):
	self.player_ship = player_ship
	print("Client.set_player_ship")
	emit_signal("player_ship_set")

func get_level():
	return get_multiverse().get_level()
	
func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")

remote func fire_shot(appointed_time, entity_name, destination, weapon_id, shot_name, angle, velocity):
	delay_until(appointed_time)
	var shot = get_level().get_node(destination + "/" + entity_name).get_shot(weapon_id, angle)
	shot.set_linear_velocity(velocity)
	shot.set_name(shot_name)
	get_level().get_node("shots").add_child(shot)
	if shot.name != shot_name:
		var real_name = shot.name
		print("SYNC BUG: UNABLE TO SET NAME: ", shot_name)

remote func switch_level(new_level_name, level_data):
	get_multiverse().switch_level(new_level_name, level_data)
	player_input.switch_system()
	
	emit_signal("system_changed")

remote func remove_entity(time, destination, ent_name):
	delay_until(time)
	var entity_to_remove = get_level().get_node(destination + "/" + ent_name)
	# Hacky.
	# if entity_to_remove is Ship:
		# TODO: Does this need to be before or after?
		# entity_to_remove.emit_signal("removed")
	get_level().get_node(destination).remove_child(entity_to_remove)
	
remote func send_entity(time, destination, entity_data):
	delay_until(time)
	get_level().receive_entity(destination, entity_data)

remote func replace_entity(time, destination, entity_data):
	delay_until(time)
	var entity_to_remove = get_level().get_node(destination + "/" + entity_data["name"])
	get_level().get_node(destination).remove_child(entity_to_remove)
	get_level().receive_entity(destination, entity_data)

func complain_local(text):
	hud.get_node("messages").display(text)
	
remote func complain(appointed_time, text):
	delay_until(appointed_time)
	hud.get_node("messages").display(text)
	
func current_system_id():
	return get_level().get_node("../").name

func delay_until(appointed_time):
	# https://godotengine.org/qa/1660/execute-a-function-after-a-time-delay
	var delay = appointed_time - time()
	if delay > 0:
		yield(get_tree().create_timer(delay), "timeout")
	else:
		print("Arrived late!")
