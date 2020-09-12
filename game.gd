extends Node

const SHIP_TYPES = {
	0: {"name": "Ringer", "scene": preload("res://gameplay/player.tscn")},
}

const INPUT = "input_nodes"

func get_ship(ship_type, player_id):
	var ship = SHIP_TYPES[ship_type]["scene"].instance()
	ship.set_name(str(player_id))
	return ship
