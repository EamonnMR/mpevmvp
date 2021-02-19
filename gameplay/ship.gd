extends RigidBody2D

class_name Ship

var max_speed: float
var turn: float
var accel: float
var max_cargo: int
var free_mass: int
var price: int
var standoff: bool
var joust: bool
var wimpy: bool
var has_turrets: bool
var subtitle: String
var armor: float
var upgrades: Dictionary

var direction: float = 0

var shooting = false
var shot_cooldown = false
var jumping_out = false
var jumping_in = false
var thrusting = false
var braking = false
var health = 20
var input_state: ShipController
var landing = false

export var bulk_cargo = {}
export var money = 0

export var type: String

export var team_set = []
export var faction = ""

signal destroyed
signal disappeared
signal cargo_updated
signal status_updated
signal upgrades_updated
signal took_damage_from(source)
signal money_updated

func _ready():
	if (name == str(Client.client_id)):
		$Camera2D.make_current()
		Client.set_player_ship(self)
	if(is_network_master()):
		input_state = get_input_state()
	else:
		Client.hud.add_radar_pip(self)
		# set_physics_process(false)
	$RotationSprite.set_direction(direction)
	
	# TODO: Handle ships with no engine glow
	if not $EngineGlowSprite.get_sprite_frames():
		var removed = $EngineGlowSprite
		remove_child(removed)
		removed.queue_free()
	# _show_debug_info()
	_apply_upgrades()
	# $ClickArea/CollisionShape2D.shape.radius = $RotationSprite.texture.get_size().length() / 2

func is_alive():
	return true

func apply_stats(new_type):
	type = new_type
	data().apply(self)
	
	health = armor

func _apply_upgrades():
	for upgrade in upgrades:
		var count = upgrades[upgrade]
		if not (upgrade in Game.upgrades):
			print("INVALID UPGRADE: ", upgrade, " on ship type ", type)
		else:
			Game.upgrades[upgrade].apply(self, count)

func add_weapon(type: String, count: int):
	if $weapons.has_node(type):
		var weapon = $weapons.get_node(type)
		weapon.count += count
		weapon.apply_stats()
	else:
		var weapon = preload("res://gameplay/Weapon.tscn").instance()
		weapon.name = type
		weapon.count = count
		weapon.apply_stats()
		$weapons.add_child(weapon)
	
func remove_weapon(type: String, count: int):
	var weapon: Weapon = $weapons.get_node(type)
	if not is_instance_valid(weapon):
		print("Cannot remove weapon: ", type)
		return
	weapon.count -= count
	if weapon.count <= 0:
		$weapons.remove_child(weapon)
	else:
		weapon.apply_stats()

func data() -> ShipDat:
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
		input_state = get_input_state()
		
		shooting = input_state.puppet_shooting
		thrusting = input_state.puppet_thrusting and not input_state.puppet_braking
		landing = input_state.puppet_landing
		braking = input_state.puppet_braking
		
		handle_rotation(delta)
		if shooting:
			for weapon in $weapons.get_children():
				weapon.try_shooting()
	else:
		var time = Client.time()
		var net_frame_latest = _get_net_frame(0)
		var net_frame_next = _get_net_frame(1)
		
		if not net_frame_next:
			pass
		elif net_frame_next.time > time and net_frame_latest: # Interpolate
			var time_range = net_frame_next.time - net_frame_latest.time
			var time_offset = time - net_frame_latest.time
			var lerp_factor = float(time_offset) / float(time_range)
			
			lerp_member("position", net_frame_latest, net_frame_next, lerp_factor)
			lerp_angle_member("direction", net_frame_latest, net_frame_next, lerp_factor)
			lerp_boolean_member("thrusting", net_frame_latest, net_frame_next, lerp_factor)
			lerp_member("health", net_frame_latest, net_frame_next, lerp_factor)
			
		elif net_frame_next.time < time and net_frame_latest: # Extrapolate
			# Extrapolate by dead reckoning
			var extrapolation_factor = float(time - net_frame_latest.time) / float(net_frame_next.time - net_frame_latest.time) - 1.00
			extrapolate_member("position", net_frame_latest, net_frame_next, extrapolation_factor)
			extrapolate_angle_member("direction", net_frame_latest, net_frame_next, extrapolation_factor)
			thrusting = net_frame_next.state.get("thrusting")
			# Don't update health
		else: # Cannot extrapolate - probably waiting on frames
			pass
			
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
	if has_node("JumpAutopilot"):
		return $JumpAutopilot
	if has_node("AI"):
		return $AI
	else:
		return get_tree().get_root().get_node(Game.INPUT).get_node(name)

func get_limited_velocity_with_thrust():
	var vel = get_linear_velocity()
	if thrusting:
		vel += Vector2(accel, 0).rotated(direction)
	if braking or landing:
		vel -= (Vector2(min(accel, vel.length()), 0).rotated(vel.angle()))
	var tmp_max_speed = max_speed
	if jumping_out:
		tmp_max_speed = max_speed * 10
	if vel.length() > tmp_max_speed:
		return Vector2(tmp_max_speed, 0).rotated(vel.angle())
	else:
		return vel

func wrap_position_with_transform(state):
	var transform = state.get_transform()
	if transform.origin.length() > Game.PLAY_AREA_RADIUS and not (jumping_in or jumping_out):
		transform.origin = Vector2(Game.PLAY_AREA_RADIUS / 2, 0).rotated(anglemod(transform.origin.angle() + PI))
		state.set_transform(transform)
	else:
		if jumping_in:
			jumping_in = false

func _integrate_forces(state):
	set_applied_torque(0)  # No rotation component
	rotation = 0.0
	if (is_network_master()):
		wrap_position_with_transform(state)
		set_linear_velocity(get_limited_velocity_with_thrust())
	else:
		set_linear_velocity(Vector2(0,0))
	
func is_far_enough_to_jump():
	return Game.JUMP_DISTANCE < position.length()

func selected_valid_system_to_jump_to():
	return get_input_state().puppet_selected_system in Game.systems[current_system()].links
	
func current_system():
	return get_system().name
	
func _on_ShotTimer_timeout():
	shot_cooldown = true

func get_shot(weapon_id, angle=null):
	return $weapons.get_node(weapon_id).get_shot(angle)

func take_damage(damage, source):
	health -= damage
	print(self.name, " Took damage from", source)
	emit_signal("took_damage_from", source)
	if health < 0 and is_network_master():
		server_destroyed(source)

func server_destroyed(by):
	if is_player():
		Server.set_respawn_timer(int(name))
		Server.players[int(self.name)]
	else:
		if faction and by.is_player():
			Game.factions[str(faction)].player_destroyed_mine(int(by.name))
	for id in get_level().get_player_ids():
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

func get_system():
	# What system are we in?
	#      players ->   level      -> system 
	return get_parent().get_parent().get_parent()

func get_level():
	# What universe are we in?
	#      players ->   level 
	return get_parent().get_parent()


func anglemod(angle):
	"""I wish this was a builtin"""
	var ARC = 2 * PI
	# TODO: Recursive might be too slow
	return fmod(angle + ARC, ARC)

func explosion_effect():
	var explosion = data().explosion.instance()
	explosion.position = position
	get_level().add_effect(explosion)

# General purpose networking functions.
func serialize():
	return {
		"position": position,
		"direction": direction,
		"team_set": team_set,
		"money": money,
		"bulk_cargo": bulk_cargo,
		"upgrades": upgrades,
		"ai": has_node("AI"),  # We just want to know if it's a player
		"faction": faction
	}

func deserialize(data):
	# Maybe use 'set' and some reflection to simplify this?
	position = data["position"]
	direction = data["direction"]
	team_set = data["team_set"]
	money = data["money"]
	bulk_cargo = data["bulk_cargo"]
	upgrades = data["upgrades"]
	faction = data["faction"]
	
	if data["ai"]:
		var ai = Node.new()
		ai.name = "AI"
		add_child(ai)
		
# Single-message moves:
remote func try_jump():
	if is_far_enough_to_jump():
		if selected_valid_system_to_jump_to():
			start_jump()
		else:
			Client.rpc_id(int(name), "complain", Server.time(), "Cannot enter hyperspace - Current System %s has no hyperlane to selected (%s)" % [current_system(), get_input_state().puppet_selected_system])
	else:
		Client.rpc_id(int(name), "complain", Server.time(), "Cannot enter hyperspace - too close to sytem center")

func start_jump():
	var autopilot: Node = preload("res://gameplay/JumpAutopilot.tscn").instance()
	autopilot.puppet_selected_system = get_input_state().puppet_selected_system
	add_child(autopilot)

func complete_jump(arrival_position):
	position = arrival_position
	jumping_out = false
	jumping_in = true
	Server.switch_system(self)
		
	remove_child($JumpAutopilot)
	
# Trade related functions:
	
func get_npc_carried_money() -> int:
	print(int(price / 10), int(price / 5))
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

func purchase_upgrade(upgrade, quantity: int):
	price = upgrade.price * quantity
	if money >= price and free_mass >= quantity:
		money -= price
		push_add_upgrade(upgrade.id, quantity)
	else:
		print("Can't buy upgrade")

func sell_upgrade(upgrade, quantity: int):
	if str(upgrade.id) in upgrades and quantity <= upgrades[str(upgrade.id)]:
		money += upgrade.price * quantity
		push_remove_upgrade(upgrade.id, quantity)
	else:
		Client.rpc_id(int(name), "complain", Server.time(), "Can't sell an upgrade you don't have")

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

func push_add_upgrade(type, quantity):
	add_upgrade(type, quantity)
	for id in get_level().get_player_ids():
		rpc_id(id, "add_upgrade", type, quantity)
		
sync func add_upgrade(type, quantity):
	type = str(type)
	var upgrade = Game.upgrades[str(type)]
	if type in upgrades:
		upgrades[type] += quantity
	else:
		upgrades[type] = quantity
	upgrade.apply(self, quantity)
	emit_signal("upgrades_updated")

func push_remove_upgrade(type, quantity):
	remove_upgrade(type, quantity)
	for id in get_level().get_player_ids():
		rpc_id(id, "remove_upgrade", type, quantity)

sync func remove_upgrade(type_int: int, quantity: int):
	var type = str(type_int)
	var upgrade = Game.upgrades[type]
	upgrades[type] -= quantity
	if upgrades[type] == 0:
		upgrades.erase(type)
	var weapon_remove = upgrade.apply(self, -1 * quantity)
	emit_signal("upgrades_updated")
	print("Upgrades updated emitted")

func push_update_cargo_and_money():
	for id in get_level().get_player_ids():
		rpc_id(id, "client_set_cargo_and_money", bulk_cargo, money)

remote func client_set_cargo_and_money(new_bulk_cargo, new_money):
	bulk_cargo = new_bulk_cargo
	money = new_money
	emit_signal("money_updated")
	emit_signal("cargo_updated")

func push_update_money():
	for id in get_level().get_player_ids():
		rpc_id(id, "client_set_money", money)
		
remote func client_set_money(new_money):
	new_money = new_money
	emit_signal("money_updated")
# Selection box stuff

func add_selection():
	$RotationSprite.add_child(preload("res://interface/hud/Selection.tscn").instance())

func remove_selection():
	if $RotationSprite/Selection:
		$RotationSprite.remove_child($RotationSprite/Selection)

func _on_ClickArea_input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton && event.pressed):
		Client.player_input.select_ship(self)

func get_value():
	# TODO: Total up price of ship + price of upgrades
	return 0
	
func _exit_tree():
	emit_signal("disappeared")

func get_target():
	var input = get_input_state()
	if input:
		return input.target
	return null

func _get_net_frame(offset):
	return get_level().get_net_frame(get_node("../").name, name, offset)

func build_net_frame():
	return {
		"position": position,
		"direction": direction,
		"thrusting": thrusting,
		"health": health
	}

func lerp_member(member, past, future, factor):
	set(member,
		lerp(
			past.state[member], future.state[member], factor
		)
	)
	
func lerp_angle_member(member, past, future, factor):
	set(member,
		lerp_angle(
			past.state[member], future.state[member], factor
		)
	)

func lerp_boolean_member(member, past, future, factor):
	set(member, past.state[member] if factor < 0.5 else future.state[member])

func extrapolate_member(member, latest, next, factor):
	var known_delta = next.state[member] - next.state[member]
	set(member,
		next.state[member] + (known_delta * factor)
	)

func extrapolate_angle_member(member, latest, next, factor):
	var known_delta = next.state[member] - next.state[member]
	set(member,
		anglemod(next.state[member] + (known_delta * factor))
	)
