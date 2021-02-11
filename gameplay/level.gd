extends Node2D

export var level_id: String
export var dat: Dictionary
var WAIT_TIME = 5
var net_frames = []

func _ready():
	$FrameTimer.wait_time = 1.0 / Server.net_fps

# TODO: Maybe handle this in enter/exit system funcs on the server?
# Maybe despawn empty systems?
func _physics_process(delta):
	# TODO: This belongs in a timer
	if is_network_master():
		if $players.get_children().size() > 0:
			if $FrameTimer.is_stopped():
				$FrameTimer.start()
			handle_npc_spawns()
			# dispatch_net_frame()
		else:
			remove_npcs_from_empty_system()
			$FrameTimer.stop()
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
	for child in children.get_children():
		if child.has_method("build_net_frame"):
			net_frame[child.name] = child.build_net_frame()
	return net_frame

func net_frames_comparitor(l: NetFrame, r: NetFrame):
	return l.time < r.time

func sort_net_frames():
	net_frames.sort_custom(self, "net_frames_comparitor")
	for net_frame in net_frames:
		print(net_frame.time)

func prune_net_frames():
	# Assumption: net frames are already sorted
	var old_len = len(net_frames)
	var time = Client.time()
	# This loop is fucked.
	# rewrite it
	while len(net_frames) > 2:  # Don't prune us down to nothing, even if the frames are outdated
		if net_frames[1].time < time:  # We want one and only one net frame to be in the past
			print("Pruned frame: ")
			net_frames.pop_front()
		else:
			break
	# if old_len > len(net_frames):
	print("Dropped ", old_len - len(net_frames), " net frames")
	for frame in net_frames:
		print(frame.time)
	
remote func receive_net_frame(time: int, frame: Dictionary):
	var local_time = Client.time()
	if time < local_time:
		var ping = (local_time + Client.latency) - time
		# Discard past frames
		print("Discarded old net frame: ", time, " Client.time: ", local_time, " ping: ", ping)
		return
	else:
		print("Got net frame")
		# if len(net_frames) < 2:
		net_frames.append(NetFrame.new(time, frame))
		# instead of sorting, only insert newer frames and always add to the front?
		sort_net_frames()

func dispatch_net_frame():
	var net_frame = get_net_frame_state()
	print(net_frame.get("npcs", {}).keys())
	var server_time = Server.time()
	for player in get_player_ids():
		rpc_unreliable_id(int(player), "receive_net_frame", server_time, net_frame)

func get_net_frame(parent, child, offset):
	if len(net_frames) >= offset + 1:
		var frame = net_frames[offset]
		var state = frame.state
		var result = state[parent].get(child)
		if result:
			return NetFrame.new(frame.time, result)
		return null
	else:
		return null

func _on_FrameTimer_timeout():
	dispatch_net_frame()
