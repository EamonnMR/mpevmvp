extends Node2D

var cooldown = true

func _init():
	pass

func get_ship():
	return get_node("../../")

func try_shooting():
	if cooldown:
		print("Server: Firing: ", name)
		cooldown = false
		Server.fire_shot(get_ship(), name)
		$CooldownTimer.start()

func _on_CooldownTimer_timeout():
	cooldown = true

func shot_effects():
	$shot_sfx.play()

func get_shot():
	print("Get shot")
	var shot = preload("res://gameplay/bullet.tscn").instance()
	var ship = get_ship()
	shot.team_set = get_ship().team_set
	shot.init(ship.direction, ship.position, ship.get_linear_velocity())
	if not ship.is_network_master():
		shot_effects()
	return shot
