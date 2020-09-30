extends Node
var systems = null
var ships = null
var spob_types = null

const INPUT = "input_nodes"
const PLAY_AREA_RADIUS = 800

const SPOB_TYPES_MAP = {
	"Gas Giant": "Gas_Giant",
	"Rocky Planet": "Planet",
	"Large Asteroid": "Moon",
	"Moon": "Moon",
	"Rock Ring": "Moon",
	"Ice Ring": "Moon"
}

var spob_types_grouped = {}

func _ready():
	
	# Call Deferred prevents a bug where loads get interrupted.
	load_spob_types()
	call_deferred("load_galaxy")
	call_deferred("load_ships")

func load_spob_types():
	spob_types = load_csv("res://data/spob_types.csv")
	for spob_type_id in spob_types:
		var spob_type = spob_types[spob_type_id]
		spob_type["sprite"] = load(spob_type["sprite"]) if spob_type["sprite"] else null
		spob_type["landing"] = load(spob_type["landing"]) if spob_type["landing"] else null
		if spob_type["kind"] in spob_types_grouped:
			spob_types_grouped[spob_type["kind"]].append(spob_type_id)
		else:
			spob_types_grouped[spob_type["kind"]] = [spob_type_id]
func load_ships():
	ships = load_csv("res://data/ships.csv")
	for i in ships:
		ships[i]["scene"] = load("res://gameplay/ships/" + ships[i]["scene"] + ".tscn")

func get_ship(ship_type, player_id):
	var type = str(ship_type)
	var ship = ships[type]["scene"].instance()
	ship.type = type
	ship.set_name(str(player_id))
	return ship

# TODO: Refactor obv.
func get_npc_ship(ship_type):
	var type = str(ship_type)
	var ship = ships[type]["scene"].instance()
	ship.type = type
	return ship

func load_galaxy():
	systems = load_csv("res://data/galaxy.csv")
	for system in systems:
		preprocess_system(systems[system])

func preprocess_system(system):
	system["links"] = []
	for possible_link in [
		"Link South (Down)",
		"Link East (Left)",
		"Link West (Right)",
		"Link North (Up)"
	]:
		if system[possible_link]:
			system["links"].append(system[possible_link])
	
	# TODO: Scale factor in the map
	system["position"] = Vector2(system["System X"], system["System Y"]) * 2

func load_csv(csv):
	var file = File.new()
	file.open(csv + ".txt", File.READ) # Simlink *csv.txt this to your *.csv to dodge export badness
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
	print("Parsed ", csv + ".txt ", "got ", parsed_file.size(), " rows")
	return parsed_file
	
func get_level(level_name):
	var directory = Directory.new();
	var file_path = "res://levels/" + level_name + ".tscn"
	if directory.file_exists(file_path):
		return load(file_path).instance()
	else:
		return _level_from_data(systems[level_name])


func _select_spob_type(id, basic_type):
	var rng_value = rand_seed(int(id))[0]
	var mapped_type = SPOB_TYPES_MAP[basic_type]
	var spob_type_group = spob_types_grouped[mapped_type]
	return spob_type_group[abs(rng_value % spob_type_group.size())]

func _level_from_data(dat):
	var SCALE = 1
	var level = preload("res://gameplay/level.tscn").instance()
	var planet_type = preload("res://environment/spob.tscn")
	for planet_num in [1,2,3]:
		var prfx = "Planet %s " % str(planet_num)
		if dat[prfx + "Exists?"] == "Exists":
			var spob = planet_type.instance()
			spob.spob_id = dat[prfx + "ID"]
			var basic_type = dat[prfx + "Basic Type"]
			spob.spob_type = _select_spob_type(spob.spob_id, basic_type)
			spob.position = SCALE * Vector2(
				dat[prfx + "X"],
				dat[prfx + "Y"]
			)
			spob.name = dat[prfx + "Name"]
			level.get_node("spobs").add_child(spob)
	for moon_num in [1,2]:
		var prfx = "Moon %d " % moon_num
		if dat[prfx + "Exists?"] == "Exists":
			var spob = planet_type.instance()
			spob.spob_id = dat[prfx + "ID"]
			spob.spob_type = _select_spob_type(spob.spob_id, "Moon")
			spob.position = SCALE * Vector2(
				dat[prfx + "X"],
				dat[prfx + "Y"]
			)
			spob.name = dat[prfx + "Name"]
			level.get_node("spobs").add_child(spob)
	
	return level
