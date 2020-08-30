extends Node2D

# This captures input and displays the cursor

puppet var puppet_direction_change: int = 0
puppet var puppet_shooting = false
puppet var puppet_thrusting = false
puppet var puppet_jumping = false

var direction_change: int = 0
var shooting = false
var thrusting = false
var jumping = false

func _get_entity():
	# TODO: Ungross this
	var root = get_tree().get_root()
	var world = root.get_node("Multiverse").get_level()
	var players = world.get_node("players")
	return players.get_node(name)

func _physics_process(delta):
	if (is_network_master()):
		direction_change = _get_direction_change()
		shooting = Input.is_key_pressed(KEY_SPACE)
		jumping = Input.is_key_pressed(KEY_J)
		thrusting = Input.is_key_pressed(KEY_W)
		
		rset_id(1, "puppet_direction_change", direction_change)
		rset_id(1, "puppet_shooting", shooting)
		rset_id(1, "puppet_thrusting", thrusting)
		rset_id(1, "puppet_jumping", jumping)

func _get_direction_change():
	var dc = 0
	if Input.is_key_pressed(KEY_A):
		dc -= 1
	if Input.is_key_pressed(KEY_D):
		dc += 1
	return dc
