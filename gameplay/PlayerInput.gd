extends Node2D

# This captures input and displays the cursor

puppet var puppet_direction_change: int = 0
puppet var puppet_shooting = false
puppet var puppet_thrusting = false
puppet var puppet_jumping = false
puppet var puppet_selected_system: String = ""
puppet var puppet_landing = false

var direction_change: int = 0
var shooting = false
var thrusting = false
var jumping = false
var map_debounce = true
var map = null
var selected_system: String = ""
var spobs

var landing = null
var land_debounce = true

var selected_spob = null

func _ready():
	if is_network_master():
		map = preload("res://interface/map/Map.tscn").instance()
		landing = preload("res://interface/landing/landing_main.tscn").instance()
		# landing.bind(self)
		spobs = _get_spobs()

func switch_system():
	spobs = _get_spobs()

func _get_entity():
	# TODO: Ungross this
	var root = get_tree().get_root()
	var world = root.get_node("Multiverse").get_level()
	var players = world.get_node("players")
	return players.get_node(name)

func _physics_process(delta):
	if (is_network_master()):
		direction_change = _get_direction_change()
		shooting = Input.is_action_pressed("fire_primary")
		jumping = Input.is_action_pressed("jump")
		thrusting = Input.is_action_pressed("thrust")
		_handle_show_map()
		_handle_show_landing_menu()
		_handle_spob_select()
		
		rset_id(1, "puppet_direction_change", direction_change)
		rset_id(1, "puppet_shooting", shooting)
		rset_id(1, "puppet_thrusting", thrusting)
		rset_id(1, "puppet_jumping", jumping)
		
func _select_spob(new_selected_spob):
	print("Select Spob: ", new_selected_spob)
	if is_instance_valid(selected_spob):
		selected_spob.remove_selection()
	selected_spob = new_selected_spob
	selected_spob.add_selection()

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
			print("Select pressed: ", i)
			_select_spob(spob)
	

func _handle_show_landing_menu():
	if Input.is_action_pressed("land") and land_debounce:
		land_debounce = false
		if not selected_spob:
			var spobs = _get_spobs()
			if (spobs.size()):
				_select_spob(spobs[0])
		elif is_instance_valid(selected_spob):
			toggle_landing()

func toggle_landing():
	var root = get_tree().get_root()
	if landing.is_inside_tree():
		rset_id(1, "puppet_landing", false)
		set_process_input(true)
		root.remove_child(landing)
	else:
		rset_id(1, "puppet_landing", true)
		set_process_input(false)
		landing.set_spob(selected_spob)
		root.add_child(landing)

func _on_LandDebounce_timeout():
	land_debounce = true

func _handle_show_map():
	if Input.is_action_pressed("show_map") and map_debounce:
		map_debounce = false
		_toggle_map()

func _toggle_map():
	var root = get_tree().get_root()
	if map.is_inside_tree():
		set_process_input(true)
		root.remove_child(map)
	else:
		set_process_input(false)
		root.add_child(map)

func _on_MapDebounce_timeout():
	map_debounce = true

func map_select_system(system_id):
	selected_system = system_id
	rset_id(1, "puppet_selected_system", system_id)
	map.update()
	
func handle_gui_player_ship_purchase(id):
	Server.rpc_id(1, "purchase_ship", id)
