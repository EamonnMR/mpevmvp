extends Node
var systems = null
var ships = null

const INPUT = "input_nodes"

func _ready():
	call_deferred("load_galaxy")  # This prevents a bug where load_ships will break subsequent calls
	
	load_ships()
	
func load_ships():
	ships = {
		0: {"name": "Ringer", "scene": preload("res://gameplay/player.tscn")},
	}

func get_ship(ship_type, player_id):
	print("Get Ship")
	var ship = ships[ship_type]["scene"].instance()
	ship.set_name(str(player_id))
	return ship

func load_galaxy():
	systems = load_csv("res://data/galaxy.csv.txt")

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
	# TODO: Examine the data and spawn some stuff
	return preload("res://gameplay/level.tscn").instance()
