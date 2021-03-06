extends ShipController

class_name PlayerInput

var target = null  # Not a puppet var, but set remotely

var direction_change: int = 0
var shooting = false
var thrusting = false
var map = null
var info = null
var selected_system: String = ""
var spobs

var landing = null

var selected_spob: Spob
var selected_ship: Ship

signal navigation_updated()
signal targeting_updated()

const MAX_LAND_DISTANCE = 100
const MAX_LAND_SPEED = 20

func _ready():
	if is_network_master():
		map = preload("res://interface/map/Map.tscn").instance()
		info = preload("res://interface/info/Info.tscn").instance()
		landing = preload("res://interface/landing/landing_main.tscn").instance()
		# landing.bind(self)
		spobs = _get_spobs()
		$SelectionSound.stream.loop_mode = AudioStreamSample.LOOP_DISABLED

func switch_system():
	spobs = _get_spobs()

func _get_entity():
	# TODO: Ungross this
	var root = get_tree().get_root()
	var world = root.get_node("Multiverse").get_level()
	var players = world.get_node("players")
	return Server.get_level_for_player(name)

func _physics_process(delta):
	if (is_network_master()):
		direction_change = _get_direction_change()
		shooting = Input.is_action_pressed("fire_primary")
		thrusting = Input.is_action_pressed("thrust")
		_handle_show_map()
		_handle_show_info()
		_handle_show_landing_menu()
		_handle_spob_select()
		_handle_jump()
		
		rset_unreliable_id(1, "puppet_direction_change", direction_change)
		rset_unreliable_id(1, "puppet_shooting", shooting)
		rset_unreliable_id(1, "puppet_thrusting", thrusting)
		
func select_spob(new_selected_spob: Spob):
	if new_selected_spob != selected_spob:
		if is_instance_valid(selected_spob):
			selected_spob.remove_selection()
		selected_spob = new_selected_spob
		selected_spob.add_selection()
		$SelectionSound.play()
		emit_signal("navigation_updated")
	
func select_ship(new_selected_ship: Ship, play_sound:bool = true):
	if selected_ship != new_selected_ship:
		if is_instance_valid(selected_ship):
			selected_ship.remove_selection()
		if new_selected_ship != Client.player_ship:
			selected_ship = new_selected_ship
			if is_instance_valid(selected_ship):
				selected_ship.add_selection()
				selected_ship.connect("destroyed", self, "select_ship", [null, false])
				rpc_id(1, "update_target_selection", selected_ship.name, selected_ship.get_node("../").name)
		else:
			selected_ship = null
			rpc_id(1, "update_target_selection", null, null)
		if play_sound:
			$SelectionSound.play()
		emit_signal("targeting_updated")
		
remote func update_target_selection(target_name, destination):
	if target_name:
		var player_level = Server.get_level_for_player(int(name))
		var path = destination + "/" + target_name
		target = player_level.get_node(path)
	else:
		target = null

func _get_direction_change():
	var dc = 0
	if Input.is_action_pressed("turn_left"):
		dc -= 1
	if Input.is_action_pressed("turn_right"):
		dc += 1
	return dc

func _get_spobs():
	var level = Game.get_multiverse().get_level()
	if level:
		return level.get_node("spobs").get_children()
	else:
		return []

func _handle_spob_select():
	var i = 0
	for spob in spobs:
		i += 1
		if Input.is_action_pressed("spob_" + str(i)):
			select_spob(spob)
	

func _handle_show_landing_menu():
	if Input.is_action_just_pressed("land"):
		if not selected_spob:
			var spobs = _get_spobs()
			if (spobs.size()):
				select_spob(spobs[0])
		elif is_instance_valid(selected_spob):
			toggle_landing()
			
func _handle_jump():
	if Input.is_action_just_pressed("jump"):
		Client.player_ship.rpc_id(1, "try_jump")

func toggle_landing():
	if landing.is_inside_tree():
		liftoff()
	else:
		if selected_spob.position.distance_to(Client.player_ship.position) < MAX_LAND_DISTANCE:
			if Client.player_ship.get_linear_velocity().length() < MAX_LAND_SPEED:
				land()
			else:
				Client.complain_local("Moving too fast to land on " + selected_spob.name)
		else:
			Client.complain_local("Cannot land on " + selected_spob.name + ", too far away.")
			
func land():
	rset_id(1, "puppet_landing", true)
	set_process_input(false)
	landing.set_spob(selected_spob)
	get_tree().get_root().add_child(landing)
	Server.rpc_id(1, "do_landing", selected_spob)
	
func liftoff():
	rset_id(1, "puppet_landing", false)
	set_process_input(true)
	get_tree().get_root().remove_child(landing)
	Server.rpc_id(1, "do_liftoff", selected_spob)

func _handle_show_map():
	if Input.is_action_just_pressed("show_map"):
		_toggle_map()
		
func _handle_show_info():
	if Input.is_action_just_pressed("show_info"):
		_toggle_info()

func _toggle_map():
	var root = get_tree().get_root()
	if map.is_inside_tree():
		set_process_input(true)
		root.remove_child(map)
	else:
		set_process_input(false)
		root.add_child(map)

func _toggle_info():
	var root = get_tree().get_root()
	if info.is_inside_tree():
		set_process_input(true)
		root.remove_child(info)
	else:
		set_process_input(false)
		root.add_child(info)

func map_select_system(system_id):
	selected_system = system_id
	rset_id(1, "puppet_selected_system", system_id)
	map.update()
	emit_signal("navigation_updated")
	
func handle_gui_player_ship_purchase(id):
	Server.rpc_id(1, "purchase_ship", id)
	
func handle_gui_player_ship_upgrade_buy(id, count):
	Server.rpc_id(1, "purchase_upgrade", id, count)

func handle_gui_player_ship_upgrade_sell(id, count):
	Server.rpc_id(1, "sell_upgrade", id, count)

func purchase_commodity(commodity_id, quantity, trading_partner):
	Server.rpc_id(1, "purchase_commodity", commodity_id, quantity, trading_partner)
	
func sell_commodity(commodity_id, quantity, trading_partner):
	Server.rpc_id(1, "sell_commodity", commodity_id, quantity, trading_partner)
