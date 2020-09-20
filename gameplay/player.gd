extends RigidBody2D

const BULLET_VELOCITY = 500.0 #300

# Values loaded directly from ships.csv
const FLOAT_SHIP_STATS = [
	"max_speed",
	"turn",
	"accel"
]

var max_speed: float
var turn: float
var accel: float

puppet var puppet_pos = Vector2(0,0)
puppet var puppet_dir: float = 0
puppet var puppet_thrusting = false
puppet var puppet_velocity = Vector2(0,0)

var direction: float = 0

var shooting = false
var shot_cooldown = false
var jumping = false
var jump_cooldown = false
var thrusting = false
var health = 20
var puppet_health = 20
var input_state: Node

var type: String

var team_set = []

func _ready():
	if (name == str(Client.client_id)):
		$Camera2D.make_current()
	if(is_network_master()):
		input_state = get_input_state()
	$RotationSprite.set_direction(direction)
	
	# TODO: Handle ships with no engine glow
	if not $EngineGlowSprite.get_sprite_frames():
		var removed = $EngineGlowSprite
		remove_child(removed)
		removed.queue_free()
	# _show_debug_info()
	_apply_stats()
	
func _apply_stats():
	for stat in FLOAT_SHIP_STATS:
		set(stat, _data()[stat])

func _data():
	return Game.ships[type]
	
func _show_debug_info():
	if(OS.is_debug_build()):
		_show_team_set()
	
func _show_team_set():
	$team_set_label.show()
	for team in team_set:
		$team_set_label.text += str(team) + ", "

func _physics_process(delta):
	if (is_network_master()):
		# var input_state = get_input_state()
		
		shooting = input_state.puppet_shooting
		jumping = input_state.puppet_jumping
		thrusting = input_state.puppet_thrusting
		
		handle_rotation(delta)
		handle_thrust(delta)
		
		rset_ex("puppet_dir", direction)
		rset_ex("puppet_pos", position)
		rset_ex("puppet_thrusting", thrusting)
		rset_ex("puppet_velocity", get_linear_velocity())
		rset_ex_cond("puppet_health", health)
		
		if shooting and shot_cooldown:
			Server.fire_shot(self)
			shot_cooldown = false
			$ShotTimer.start()
		
		if jumping and jump_cooldown:
			Server.switch_player_universe(self)
			jump_cooldown = false
			$JumpTimer.start()
	else:
		direction = puppet_dir
		thrusting = puppet_thrusting
		position = puppet_pos # This should be in integrate forces, but for some reason the puppet pos variable does not work there
		health = puppet_health
	if (not is_network_master()):
		# To avoid jitter alledgedly
		pass
		# puppet_pos = position # To avoid jitter
		# puppet_dir = direction
		
	$RotationSprite.set_direction(direction)
	
	if $EngineGlowSprite:
		$EngineGlowSprite.set_direction(direction)
		if thrusting:
			$EngineGlowSprite.show()
		else:
			$EngineGlowSprite.hide()

func handle_rotation(delta):
	if input_state.puppet_direction_change:
		direction = anglemod(((turn  * input_state.puppet_direction_change * delta) + direction))
		
func handle_thrust(delta):
	if thrusting:
		apply_impulse(Vector2(0,0), Vector2(delta * accel, 0).rotated(direction))
		

func get_input_state():
	print(get_tree().get_root().print_tree_pretty())
	return get_tree().get_root().get_node(Game.INPUT).get_node(name)

func get_limited_velocity():
	return get_linear_velocity()

func _integrate_forces(state):
	set_applied_torque(0)  # No rotation component
	rotation = 0.0
	if (is_network_master()):
		pass
		# set_linear_velocity(get_limited_velocity())
	else:
		position = puppet_pos
		set_linear_velocity(puppet_velocity)

func _on_ShotTimer_timeout():
	shot_cooldown = true

func get_shot():
	var shot = preload("res://gameplay/bullet.tscn").instance()
	shot.team_set = team_set
	shot.init(direction, position)
	if not is_network_master():
		shot_effects()
	return shot

func take_damage(damage):
	health -= damage
	if health < 0 and is_network_master():
		server_destroyed()

func server_destroyed():
	print("Server Destroyed")
	Server.set_respawn_timer(int(name))
	for id in get_level().get_node("world").get_player_ids():
		rpc_id(id, "destroyed")

sync func destroyed():
	if not is_network_master():
		explosion_effect()
	var parent = get_node("../")
	parent.remove_child(self)
	var ghost = preload("res://gameplay/ghost.tscn").instance()
	ghost.name = name
	parent.add_child(ghost)
	queue_free()

func get_level():
	# What universe are we in?
	#      players ->   world      -> level 
	return get_parent().get_parent().get_parent()

func _on_JumpTimer_timeout():
	jump_cooldown = true

func anglemod(angle):
	var ARC = 2 * PI
	# TODO: Recursive might be too slow
	return fmod(angle + ARC, ARC)

# TODO: Fill these in
# These get Rset anyway, but it should make the flash of wrongness go away


func serialize():
	return {
		"position": position,
		"direction": direction,
		"team_set": team_set,
		"type": type,
	}

func deserialize(data):
	position = data["position"]
	puppet_pos = position
	direction = data["direction"]
	puppet_dir = direction
	team_set = data["team_set"]
	type = data["type"]

# TODO: Move to superclass

func rset_ex(puppet_var, value):
	# This avoids a whole lot of extra network traffic...
	# and a whole lot of "Invalid packet received. Requested node was not found."
	for id in get_level().get_node("world").get_player_ids():
		rset_id(id, puppet_var, value)
		

func rset_ex_cond(puppet_var, value):
	if self[puppet_var] != value:
		print("Values differ: Rsetting")
		self[puppet_var] = value
		rset_ex(puppet_var, value)

func explosion_effect():
	var explosion = preload("res://effects/explosion.tscn").instance()
	explosion.position = position
	get_level().get_node("world").add_effect(explosion)
	
func shot_effects():
	$shot_sfx.play()
