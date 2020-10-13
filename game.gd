extends Node
var systems = null
var ships = null
var spob_types = null
var commodities = null
var factions = null

const INPUT = "input_nodes"
const PLAY_AREA_RADIUS = 2000

# Commodity price factors
# Maybe pull this out into its own spreadsheet
const PRICE_HIGH = 1.25
const PRICE_LOW = 0.75

enum price_factors {
	LOW
	MED
	HIGH
}

var comodity_price_factor_names = {
	price_factors.LOW: "low",
	price_factors.MED: "med",
	price_factors.HIGH: "high"
}

const SPOB_TYPES_MAP = {
	"Gas Giant": "Gas_Giant",
	"Rocky Planet": "Planet",
	"Large Asteroid": "Moon",
	"Moon": "Moon",
	"Rock Ring": "Moon",
	"Ice Ring": "Moon"
}

var spob_types_grouped = {}

func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")

func _ready():
	# Call Deferred prevents a bug where loads get interrupted.
	load_spob_types()
	load_commodities()
	load_factions()
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
			
func load_commodities():
	commodities = load_csv("res://data/trade.csv")
	for commodity_id in commodities:
		var commodity = commodities[commodity_id]
		var price = int(commodity["price"])
		commodity["prices"] = {
			price_factors.LOW: int(PRICE_LOW * price),
			price_factors.MED: price,
			price_factors.HIGH: int(PRICE_HIGH * price)
		}
		
func load_factions():
	factions = load_csv("res://data/factions.csv")
	for faction_id in factions:
		var faction = factions[faction_id]
		faction["color"] = parse_color(faction["color"])
		
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
	print("Loading Galaxy")
	systems = load_csv("res://data/galaxy.csv")
	for system in systems:
		preprocess_system(systems[system])
	print("Galaxy Loaded")
	calculate_system_distances()
	print("Galaxy Analyzed")

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
	
	system["position"] = Vector2(system["System X"], system["System Y"])

func parse_color(color_text):
	var color_parsed = color_text.split(",")
	return Color(color_parsed[0], color_parsed[1], color_parsed[2])

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
		return _level_from_data(level_name, systems[level_name])

func _is_moon(moon_type):
	# We can't use "Category" for reasons I don't understand; it fails to load from the csv
	# So we get this hack
	return ("Moon" in moon_type) or ("moon" in moon_type)

func _select_spob_type(id, basic_type):
	var rng_value = rand_seed(int(id))[0]
	var mapped_type = SPOB_TYPES_MAP[basic_type]
	var spob_type_group = spob_types_grouped[mapped_type]
	return spob_type_group[abs(rng_value % spob_type_group.size())]
	
func random_comodities(id):
	var spob_commodities = {}
	var rng_seed = int(id)
	for comodity_id in commodities:
		# This code deals with making sure it's random, but also
		# replicated exactly the same way on every start
		var comodity = commodities[comodity_id]
		var result = rand_seed(rng_seed)
		var price_rng = result[0]
		rng_seed = result[1]
		result = rand_seed(rng_seed)
		var presence_rng = result[0]
		rng_seed = result[1]
		
		if abs(presence_rng % 2):
			spob_commodities[comodity_id] = {
				0: price_factors.LOW,
				1: price_factors.MED,
				2: price_factors.HIGH,
			}[abs(price_rng % 3)]
	return spob_commodities

func _level_from_data(level_name, dat):
	var level_id = int(level_name)
	var SCALE = 1
	var level = preload("res://gameplay/level.tscn").instance()
	var planet_type = preload("res://environment/spob.tscn")
	# Hack to deal with a bug in the galaxy generator script
	# (see the conditional on bad IDs below)
	var spob_counter = 10 * level_id
	for planet_num in [1,2,3]:
		var prfx = "Planet %s " % str(planet_num)
		if dat[prfx + "Exists?"] == "Exists":
			var spob = planet_type.instance()
			spob.spob_id = dat[prfx + "ID"]
			# Working around a bug in the spreadsheet
			if spob.spob_id == "#NUM!":
				spob_counter += 1
				spob.spob_id = str(spob_counter)
			var basic_type = dat[prfx + "Basic Type"]
			spob.spob_type = _select_spob_type(spob.spob_id, basic_type)
			spob.position = SCALE * Vector2(
				dat[prfx + "X"],
				dat[prfx + "Y"]
			)
			spob.name = dat[prfx + "Name"]
			spob.commodities = random_comodities(int(spob.spob_id))
			level.get_node("spobs").add_child(spob)
	for moon_num in [1,2]:
		var prfx = "Moon %d " % moon_num
		if dat[prfx + "Exists?"] == "Exists" and _is_moon(dat[prfx + "Type"]):
			var spob = planet_type.instance()
			spob.spob_id = dat[prfx + "ID"]
			# Working around a bug in the spreadsheet
			if spob.spob_id == "#NUM!":
				spob_counter += 1
				spob.spob_id = str(spob_counter)
			spob.spob_type = _select_spob_type(spob.spob_id, "Moon")
			spob.position = SCALE * Vector2(
				dat[prfx + "X"],
				dat[prfx + "Y"]
			)
			spob.name = dat[prfx + "Name"]
			spob.commodities = random_comodities(int(spob.spob_id))
			level.get_node("spobs").add_child(spob)
	return level

func calculate_system_distances():
	var sum_position = Vector2(0,0)
	var max_position = Vector2(0,0)
	
	for system_id in systems:
		var system = systems[system_id]
		sum_position += system["position"]
		
	var mean_position = sum_position / systems.size()

	var max_distance = 0
	for system_id in systems:
		var system = systems[system_id]
		system["distance"] = mean_position.distance_to(system["position"])
		if system["distance"] > max_distance:
			max_distance = system["distance"]
		
	for system_id in systems:
		var system = systems[system_id]
		system["distance_normalized"] = system["distance"] / max_distance
