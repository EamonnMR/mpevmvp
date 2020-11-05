extends RigidBody2D

const JUMP_DISTANCE = 600

# Values loaded directly from ships.csv
const SHIP_STATS = [
	"max_speed",
	"turn",
	"accel",
	"max_cargo",
	"price",
	"standoff"
]

var max_speed: float
var turn: float
var accel: float
var max_cargo: int
var price: int
var standoff: bool

puppet var puppet_pos = Vector2(0,0)
puppet var puppet_dir: float = 0
puppet var puppet_thrusting = false
puppet var puppet_velocity = Vector2(0,0)
puppet var puppet_braking = false

var direction: float = 0

var shooting = false
var shot_cooldown = false
var jumping = false
var thrusting = false
var braking = false
var health = 20
puppet var puppet_health = 20
var input_state: Node
var landing = false

export var bulk_cargo = {}
export var money = 0

export var type: String

export var team_set = []
export var faction = ""

signal destroyed
signal cargo_updated

func _ready():
	if (name == str(Client.client_id)):
		$Camera2D.make_current()
		Client.player_ship = self
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
	_create_weapons()
	
func is_alive():
	return true

func _apply_stats():
	for stat in SHIP_STATS:
		set(stat, _data()[stat])
		
func _create_weapons():
	for weapon_id in _data()["weapons"]:
		var weapon = preload("res://gameplay/Weapon.tscn").instance()
		weapon.name = weapon_id
		weapon.count = _data()["weapons"][weapon_id]
		weapon.apply_stats()
		$weapons.add_child(weapon)

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
		thrusting = input_state.puppet_thrusting and not input_state.puppet_braking
		landing = input_state.puppet_landing
		braking = input_state.puppet_braking
		
		handle_rotation(delta)
		
		rset_ex("puppet_dir", direction)
		rset_ex("puppet_pos", position)
		rset_ex("puppet_thrusting", thrusting)
		rset_ex("puppet_braking", braking)
		rset_ex("puppet_velocity", get_linear_velocity())
		rset_ex_cond("puppet_health", health)
		
		if shooting:
			for weapon in $weapons.get_children():
				weapon.try_shooting()
	else:
		direction = puppet_dir
		thrusting = puppet_thrusting
		braking = puppet_braking
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
		# TODO: Fade in/out to avoid AI jitter (and just generally look better)
		if thrusting:
			$EngineGlowSprite.show()
		else:
			$EngineGlowSprite.hide()

func handle_rotation(delta):
	if input_state.puppet_direction_change:
		direction = anglemod(((turn  * input_state.puppet_direction_change * delta) + direction))

func get_input_state():
	if has_node("AI"):
		return get_node("AI")
	else:
		return get_tree().get_root().get_node(Game.INPUT).get_node(name)

func get_limited_velocity_with_thrust():
	# TODO: Slowly slow down for landing
	if landing:
		return Vector2(0,0)
	
	var vel = get_linear_velocity()
	if thrusting:
		vel += Vector2(accel, 0).rotated(direction)
	if braking:
		vel -= (Vector2(min(accel, vel.length()), 0).rotated(vel.angle()))
	if vel.length() > max_speed:
		return Vector2(max_speed, 0).rotated(vel.angle())
	else:
		return vel

func wrap_position_with_transform(state):
	var transform = state.get_transform()
	if transform.origin.length() > Game.PLAY_AREA_RADIUS:
		transform.origin = Vector2(Game.PLAY_AREA_RADIUS / 2, 0).rotated(anglemod(transform.origin.angle() + PI))
		state.set_transform(transform)

func _integrate_forces(state):
	set_applied_torque(0)  # No rotation component
	rotation = 0.0
	if (is_network_master()):
		wrap_position_with_transform(state)
		set_linear_velocity(get_limited_velocity_with_thrust())
	else:
		state.transform.origin = puppet_pos
		set_linear_velocity(puppet_velocity)
	
func is_far_enough_to_jump():
	return JUMP_DISTANCE < position.length()

func selected_valid_system_to_jump_to():
	return get_input_state().puppet_selected_system in Game.systems[current_system()].links
	
func current_system():
	return get_level().name
	
func _on_ShotTimer_timeout():
	shot_cooldown = true

func get_shot(weapon_id):
	return $weapons.get_node(weapon_id).get_shot()

func take_damage(damage):
	health -= damage
	if health < 0 and is_network_master():
		server_destroyed()

func server_destroyed():
	print("Server Destroyed")
	if is_player():
		print(name, " is considered a player because it does not have an AI node")
		Server.set_respawn_timer(int(name))
		Server.players[int(self.name)]
	for id in get_level().get_node("world").get_player_ids():
		rpc_id(id, "destroyed")
	destroyed()

sync func destroyed():
	if not is_network_master():
		explosion_effect()
	emit_signal("destroyed")
	
	var parent = get_node("../")
	parent.remove_child(self)
	if is_player():
		var ghost = preload("res://gameplay/ghost.tscn").instance()
		ghost.name = name
		parent.add_child(ghost)
		ghost.position = position
	queue_free()
	print("Destroyed: ", name)
	
func is_player():
	return not has_node("AI")

func get_level():
	# What universe are we in?
	#      players ->   world      -> level 
	return get_parent().get_parent().get_parent()

func anglemod(angle):
	"""I wish this was a builtin"""
	var ARC = 2 * PI
	# TODO: Recursive might be too slow
	return fmod(angle + ARC, ARC)

func explosion_effect():
	var explosion = preload("res://effects/explosion.tscn").instance()
	explosion.position = position
	get_level().get_node("world").add_effect(explosion)

# General purpose networking functions.
func serialize():
	return {
		"position": position,
		"direction": direction,
		"team_set": team_set,
		"type": type,
		"money": money,
		"bulk_cargo": bulk_cargo
	}

func deserialize(data):
	# Maybe use 'set' and some reflection to simplify this?
	position = data["position"]
	puppet_pos = position
	direction = data["direction"]
	puppet_dir = direction
	team_set = data["team_set"]
	type = data["type"]
	money = data["money"]
	bulk_cargo = data["bulk_cargo"]

func rset_ex(puppet_var, value):
	# This avoids a whole lot of extra network traffic...
	# and a whole lot of "Invalid packet received. Requested node was not found."
	for id in get_level().get_node("world").get_player_ids():
		rset_id(id, puppet_var, value)
	set(puppet_var, value)

func rset_ex_cond(puppet_var, value):
	if self[puppet_var] != value:
		self[puppet_var] = value
		rset_ex(puppet_var, value)
		
# Single-message moves:
remote func try_jump():
	print("Server ship.try_jump")
	if is_far_enough_to_jump():
		print("Far enough to jump: switching universe")
		# TODO: Jump Effects
		if selected_valid_system_to_jump_to():
			Server.switch_player_universe(self)
		else:
			print("Tried to jump to unconnected system. Current System %s has no hyperlane to selected (%s)" % [current_system(), get_input_state().puppet_selected_system])
			Client.rpc_id(int(name), "complain", "Cannot enter hyperspace - Current System %s has no hyperlane to selected (%s)" % [current_system(), get_input_state().puppet_selected_system])
	else:
		print("Too close to jump")
		Client.rpc_id(int(name), "complain", "Cannot enter hyperspace - too close to sytem center")

# Trade related functions:
	
func get_npc_carried_money() -> int:
	return RandomNumberGenerator.new().randi_range(int(price / 10), int(price / 5))

func bulk_cargo_amount(type) -> int:
	if type in bulk_cargo:
		return bulk_cargo[type]
	else:
		return 0

func add_bulk_cargo(type, quantity):
	if type in bulk_cargo:
		bulk_cargo[type] += quantity
	else:
		bulk_cargo[type] = quantity
	
func remove_bulk_cargo(type, quantity):
	if type in bulk_cargo:
		bulk_cargo[type] -= quantity
	if bulk_cargo[type] == 0:
		bulk_cargo.erase(type)

func free_cargo() -> int:
	return max_cargo - total_cargo()

func total_cargo() -> int:
	var total: int = 0
	for key in bulk_cargo:
		total += bulk_cargo[key]
	return total

func purchase_commodity(commodity_id, quantity, price):
	if money >= price and free_cargo() >= quantity:
		money -= price
		add_bulk_cargo(commodity_id, quantity)
		push_update_cargo_and_money()

func sell_commodity(commodity_id, quantity, price):
	if commodity_id in bulk_cargo and bulk_cargo[commodity_id] >= quantity:
		money += price
		remove_bulk_cargo(commodity_id, quantity)
		push_update_cargo_and_money()

# One-off push functions for setting remote stuff.
# We don't want to go through the puppet push/pull because
# they're unlikley to be called many times per frame.

func push_update_cargo_and_money():
	for id in get_level().get_node("world").get_player_ids():
		rpc_id(id, "client_set_cargo_and_money", bulk_cargo, money)

remote func client_set_cargo_and_money(new_bulk_cargo, new_money):
	bulk_cargo = new_bulk_cargo
	money = new_money
	emit_signal("cargo_updated")

func push_update_money():
	for id in get_level().get_node("world").get_player_ids():
		rpc_id(id, "client_set_money", money)
		
remote func client_set_money(new_money):
	new_money = new_money
