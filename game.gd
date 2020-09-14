extends Node

const SHIP_TYPES = {
	0: {"name": "Ringer", "scene": preload("res://gameplay/player.tscn")},
}

const INPUT = "input_nodes"

func get_ship(ship_type, player_id):
	var ship = SHIP_TYPES[ship_type]["scene"].instance()
	ship.set_name(str(player_id))
	return ship

func load_galaxy():
	var galaxy = load_csv("res://data/tc_galaxy_generator_output.csv")
	print(galaxy)
	return galaxy

func load_csv(csv):
	print("Loading Galaxy")
	var file = File.new()
	file.open(csv, File.READ)
	var headers = file.get_csv_line()
	var parsed_file = {}
	while true:
		var parsed_line = {}
		var line = file.get_csv_line()
		if line.size() == 1:
			break
		for column in range(line.size()):
			parsed_line[headers[column]] = line[column]
		parsed_file[line[0]] = parsed_line
	return parsed_file
