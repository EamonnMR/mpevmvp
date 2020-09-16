extends Node
var systems = null

const SHIP_TYPES = {
	0: {"name": "Ringer", "scene": preload("res://gameplay/player.tscn")},
}

const INPUT = "input_nodes"

func _ready():
	load_galaxy()

func get_ship(ship_type, player_id):
	var ship = SHIP_TYPES[ship_type]["scene"].instance()
	ship.set_name(str(player_id))
	return ship

func load_galaxy():
	systems = load_csv("res://data/galaxy.csv")

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
	
func get_level(level_name):
	var directory = Directory.new();
	var file_path = "res://levels/" + level_name + ".tscn"
	if directory.file_exists(file_path):
		return load(file_path).instance()
	else:
		return _level_from_data(systems[level_name])

func _level_from_data(level_data_dict):
	return preload("res://gameplay/level.tscn").instance()
