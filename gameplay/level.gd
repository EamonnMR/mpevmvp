extends Node2D

export var level_id: String
export var dat: Dictionary
var WAIT_TIME = 5
var net_frames = []
var latency_ms = 100

# handle NPC spawning and despawning
# TODO: Maybe handle this in enter/exit system funcs on the server?
# Maybe despawn empty systems?
func _physics_process(delta):
	# TODO: This belongs in a timer
	if is_network_master():
		if $players.get_children().size() > 0:
			handle_npc_spawns()
			dispatch_net_frame()
		else:
			remove_npcs_from_empty_system()
	else:
		prune_net_frames()

func get_player_entity(player_id):
	return $players.get_node(str(player_id))

func handle_npc_spawns():
	if "npc_spawns" in dat and $npcs.get_children().size() < dat["npc_count"]:
		randomize()
		var faction_id = dat["npc_spawns"][randi() % dat["npc_spawns"].size()]
		var faction = Game.factions[faction_id]
		print("System: ", get_node("../").name, " needs an NPC, spawn a ", faction["name"])
		var ship_type = Game.random_ship_for_faction(int(faction_id))
		randomize()
		var x_pos = randi() % 20
		randomize()
		var y_pos = randi() % 20
		Server.spawn_npc(get_node("../").name, ship_type, faction_id)

func remove_npcs_from_empty_system():
	for child in $npcs.get_children():
		$npcs.remove_child(child)
		child.queue_free()

func serialize():
	var children = {}
	for child in [
		"shots",
		"players",
		"npcs"
	]:
		children[child] = get_each_serialized(get_node(child))
	return children
	
func get_each_serialized(node):
	var list = []
	for child in node.get_children():
		list.append({
			"name": child.name,
			"scene": child.filename,
			"state": child.serialize(),
			"type": child.type
		})
	return list

func deserialize(data):
	for key in data.keys():
		var node = get_node(key)
		for serial_data in data[key]:
			receive_entity(key, serial_data)

func receive_entity(destination, serial_data):
	var node = get_node(destination)
	# TODO: Is `load` the smartest thing to use here?
	var object = load(serial_data["scene"]).instance()
	object.apply_stats(serial_data["type"])
	object.deserialize(serial_data["state"])
	object.name = serial_data["name"]
	node.add_child(object)

func remove_entity(destination, name):
	var node = get_node(destination)
	var node_to_remove = get_node(name)
	node.remove_child(node_to_remove)

func get_player_ids():
	var ids = []
	for node in $players.get_children():
		ids.append(int(node.name))
	return ids

func add_effect( effect ):
	$effects.add_child(effect)

func get_net_frame_state():
	var net_frame = {}
	for child in [
		"shots",
		"players",
		"npcs"
	]:
		net_frame[child] = get_net_frame_from_each(get_node(child))
	return net_frame

func get_net_frame_from_each(children: Node):
	var net_frame = {}
	for child in children:
		if child.hash_method("get_net_frame"):
			children[child.name] = child.get_net_frame()
	return net_frame

class NetFrame:
	var time: int
	var state: Dictionary
	func _init(time, state):
		self.time = time
		self.state = state

func net_frames_comparitor(l: NetFrame, r: NetFrame):
	return l.time < r.time

func sort_net_frames():
	net_frames.sort_custom(self, "net_frames_comparitor")

func prune_net_frames():
	# Assumption: net frames are already sorted
	var time = Client.time()
	while len(net_frames) > 2:  # Don't prune us down to nothing, even if the frames are outdated
		if net_frames[0].time > time:
			net_frames.pop_front()
	
remote func receive_net_frame(time: int, frame: Dictionary):
	if time < Client.time():
		# Discard past frames
		return
	else:
		net_frames.append(NetFrame.new(time, frame))
		sort_net_frames()

func dispatch_net_frame():
	var server_time = Server.time()
	var net_frame = get_net_frame_state()
	for player in get_player_ids():
		rpc_unreliable_id(int(player), "receive_net_frame", server_time, net_frame)

func get_net_frame(parent, child, offset):
	return net_frames[0].data[parent][child]
