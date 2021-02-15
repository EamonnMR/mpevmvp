extends Node

var server
var players = {}
var players_in_systems = {}
var net_players

var WAIT_TIME = 5
var net_fps = 20

const MAX_PLAYERS = 6

const STARTING_MONEY = 20000

func time():
	return OS.get_system_time_msecs()

func start(game_name, port, max_players):
	print("Starting Server: ", game_name, ", ", max_players)
	
	get_tree().connect("network_peer_connected", self, "_client_connected")
	get_tree().connect("network_peer_disconnected", self,"_client_disconnected")
	
	var server = NetworkedMultiplayerENet.new()
	server.create_server(port, max_players)
	get_tree().set_network_peer(server)
	
	call_deferred("_setup_server_nodes", game_name, port)

func _setup_server_nodes(game_name, port):
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
	
	ServerTracker.register_game(game_name, port)

func _client_connected(id):
	print("Server: Client_Connected: ", id)
	players[id] = {
		"nick": str(id),
		"name": id,
		"ship_type": 0,
		"money": STARTING_MONEY  # Really not in love with storing this here (only when the player is unspawned) 
	}
	
	var player_input = preload("res://gameplay/PlayerInput.tscn").instance()
	player_input.set_name(str(id))
	player_input.set_network_master(id)
	net_players.add_child(player_input)
	Client.rpc_id(id, "update_player_list", _get_public_players())
	Client.rpc("add_net_player", id)
	for faction_id in Game.factions:
		Game.factions[faction_id].add_player(id)
	spawn_player(id)

func _get_public_players():
	var public = {}
	# Returns a dict with just the public-facing information about all players in the game
	for player in players.keys():
		public[str(player)] = {
			"nick": players[player]["nick"]
		}
	return public

func _client_disconnected(id):
	print("Server._client_disconnected: ", id)
	_remove_player_entity_by_id(id)
	players.erase(id)
	Client.rpc("remove_net_player", id)
	net_players.remove_child(net_players.get_node(str(id)))
	for faction_id in Game.factions:
		Game.factions[faction_id].remove_player(id)

remote func set_player_nick(new_nick):
	var player_id = get_tree().get_rpc_sender_id()
	# TODO: Abuse Filter here
	players[player_id]["nick"] = new_nick
	Client.rpc("update_player_nick", player_id, new_nick)
	print("New Nickname: ", new_nick)

func send_level(client_id, new_level_name, new_level):
	assert(new_level != null)
	Client.rpc_id(client_id, "switch_level", new_level_name, new_level.serialize())

func send_entity(level, destination, entity):
	for id in level.get_player_ids():
		Client.rpc_id(id, "send_entity", destination, {
			"name": entity.name,
			"scene": entity.filename,
			"state": entity.serialize(),
			"type": entity.type
		})

func replace_entity(level, destination, entity, replace_on_server=false):
	for id in level.get_player_ids():
		Client.rpc_id(id, "replace_entity", destination, {
			"name": entity.name,
			"scene": entity.filename,
			"state": entity.serialize(),
			"type": entity.type
		})
	if replace_on_server:
		var dest = level.get_node(destination)
		var old_node = dest.get_node(entity.name)
		dest.remove_child(old_node)
		old_node.queue_free()
		dest.add_child(entity)

func remove_entity(level, destination, entity_name, remove_on_server=false):
	if remove_on_server:
		var old_node = level.get_node(destination).get_node(entity_name)
		level.get_node(destination).remove_child(old_node)
		old_node.queue_free()
	print('remove entity: ', entity_name, 'from level: ', level.get_node('../').name)
	for id in level.get_player_ids():
		Client.rpc_id(id, "remove_entity", destination, entity_name)
	
func get_level(level):
	return get_multiverse().get_level(level)

func get_level_for_player(player_id):
	if not player_id in players:
		return null
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
	new_player.bulk_cargo = player.bulk_cargo
	new_player.money = player.money
	
	print("Player purchased ship! New Ship type: ", id)
	print("New Ship Data:" )
	print(new_player.serialize())
	replace_entity(level, "players", new_player, true)
	

remote func purchase_commodity(commodity_id, quantity, trading_partner_path):
	var player_id = get_tree().get_rpc_sender_id()
	if _is_player_alive(player_id):
		var player = _get_player_node(player_id)
		var trading_partner = player.get_level().get_node(trading_partner_path)

		var price_factor = trading_partner.commodities[commodity_id]
		var type_data = Game.commodities[commodity_id]
		var price = type_data["prices"][price_factor] * quantity
		
		# TODO: Probably move this to ship?
		
		player.purchase_commodity(commodity_id, quantity, price)
		
remote func sell_commodity(commodity_id, quantity, trading_partner_path):
	var player_id = get_tree().get_rpc_sender_id()
	if _is_player_alive(player_id):
		var player = _get_player_node(player_id)
		var trading_partner = player.get_level().get_node(trading_partner_path)

		var price_factor = trading_partner.commodities[commodity_id]
		var type_data = Game.commodities[commodity_id]
		var price = type_data["prices"][price_factor] * quantity
		
		# TODO: Probably move this to ship?
		player.sell_commodity(commodity_id, quantity, price)

remote func purchase_upgrade(upgrade_id, quantity):
	print("Server.purchase_upgrade")
	var player_id = get_tree().get_rpc_sender_id()
	var upgrade: Upgrade = Game.upgrades[upgrade_id]
	if _is_player_alive(player_id):
		var player = _get_player_node(player_id)
		player.purchase_upgrade(upgrade, quantity)
		
remote func sell_upgrade(upgrade_id, quantity):
	print("Server.sell_upgrade. id: ", upgrade_id, " , quantity: ", quantity)
	var player_id = get_tree().get_rpc_sender_id()
	var upgrade: Upgrade = Game.upgrades[upgrade_id]
	if _is_player_alive(player_id):
		var player = _get_player_node(player_id)
		player.sell_upgrade(upgrade, quantity)

func spawn_player(player_id, level="128"):
	print("Server.spawn_player: ", player_id)
	var SPAWN_LEVEL = "128"
	players[player_id]["level"] = SPAWN_LEVEL
	print("level: ", SPAWN_LEVEL, " (", get_level(SPAWN_LEVEL), ")")
	send_level(player_id, SPAWN_LEVEL, get_level(SPAWN_LEVEL))
	var ship = create_ship(player_id, players[player_id]["ship_type"], Vector2(0.0, 0.0), SPAWN_LEVEL, players[player_id]["money"])
	send_entity(get_level(SPAWN_LEVEL), "players", ship)
	
func spawn_npc(level, type, faction):
	print("Server.spawn: ")
	print("level: ", level, " (", get_level(level), ")")
	var ship = create_npc(type, faction, Vector2(rand_range(-500,500), rand_range(-500,500)), level)
	ship.team_set = [faction]
	ship.money = ship.get_npc_carried_money()
	send_entity(get_level(level), "npcs", ship)

func create_ship(player_id, type, position, level=null, money=0):
	print("Server Spawn Ship on level: ", level)
	var ship = Game.get_ship(type, player_id)
	if level:
		get_level(level).get_node("players").add_child(ship)
	ship.position = position
	ship.team_set = [player_id]
	ship.money = money
	return ship

func create_npc(type, faction, position, level=null):
	print("Server Spawn Ship on level: ", level)
	var ship = Game.get_npc_ship(type, faction)
	ship.add_child(preload("res://gameplay/AI.tscn").instance())
	ship.team_set = []
	# So, there's a bit of a story here.
	# If you just let it auto assign a name, it will be something like
	# @ship@nn@
	# However, if you assign a name with `.name = ` that contains `@`
	# the `@` will be ignored!
	# The client name needs to match the server name, so we can't use the
	# auto-assigned @ names.
	# If this proves to be inefficient, it's probably fine to only generate th
	# first two or three characters or so and verify that it does not already
	# exist in the system.
	ship.name = Uuid.v4()
	if level:
		get_level(level).get_node("npcs").add_child(ship)
	ship.position = position
	return ship
	
func fire_shot(ship, weapon_id):
	var shot = ship.get_shot(weapon_id)
	shot.set_network_master(1)
	shot.set_name(Uuid.v4())
	ship.get_level().get_node("shots").add_child(shot)
	Client.rpc("fire_shot", time(), ship.name, ship.get_node("../").name, weapon_id, shot.name, shot.direction, shot.get_linear_velocity())

func switch_system(ship):
	var old_level = ship.get_level()
	var old_level_name = ship.get_system().name
	
	var new_level_name = ship.get_input_state().puppet_selected_system
	if new_level_name != old_level_name:
		var parent_name = ship.get_node("../").name
		var new_level = get_level(new_level_name)
		send_entity(new_level, parent_name, ship)
		get_multiverse().switch_ship_level(ship, new_level_name)
		if ship.is_player():
			send_level(int(ship.name), new_level_name, new_level)
		remove_entity(old_level, parent_name, ship.name)
		if ship.is_player():
			players[int(ship.name)]["level"] = new_level_name

func _remove_player_entity_by_id(id, remove_on_server=true):
	print("Removing player entity by ID")
	var level = get_level_for_player(id)
	remove_entity(level, "players", str(id), remove_on_server)
	return level

func _is_player_alive(id):
	var player_node = _get_player_node(id)
	
	return player_node and player_node.is_alive()

func _get_player_node(id):
	var level = get_level_for_player(id)
	return level.get_node("players/" + str(id))
