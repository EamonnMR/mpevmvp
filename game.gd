extends Node
var systems = null
var ships = null
var spob_types = null
var commodities = null
var factions = null
var spobs = {}
var ships_by_faction = {}

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
	"Ice Ring": "Moon",
	"Station": "Station"
}

func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")

func _ready():
	# Call Deferred prevents a bug where loads get interrupted.
	load_spob_types()
	load_commodities()
	load_factions()
	call_deferred("load_galaxy")
	call_deferred("load_ships")

func random_select(items: Array):
	# Don't use this for procgen, because it is unseeded
	randomize()
	return items[randi() % items.size()]

func load_spob_types():
	spob_types = load_csv("res://data/spob_types.csv")
	for spob_type_id in spob_types:
		var spob_type = spob_types[spob_type_id]
		spob_type["sprite"] = load(spob_type["sprite"]) if spob_type["sprite"] else null
		spob_type["landing"] = load(spob_type["landing"]) if spob_type["landing"] else null
	
	Procgen.index_spob_types()
			
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
	var boolean_fields = [
		"is_default",
		"spawn_anywhere",
		"host_spawn_anywhere",
		"peninsula_bonus"
	]
	
	factions = load_csv("res://data/factions.csv")
	
	for faction_id in factions:
		var faction = factions[faction_id]
		faction["color"] = parse_color(faction["color"])
		
		for field in boolean_fields:
			faction[field] = parse_bool(faction[field])
		
func load_ships():
	ships = load_csv("res://data/ships.csv")
	for i in ships:
		ships[i]["scene"] = load("res://gameplay/ships/" + ships[i]["scene"] + ".tscn")
		var faction = ships[i]["faction"]
		if faction in ships_by_faction:
			ships_by_faction[faction].append(ships[i]["id"])
		else:
			ships_by_faction[faction] = [ships[i]["id"]]
	print(ships_by_faction)

func get_ship(ship_type, player_id):
	var type = str(ship_type)
	var ship = ships[type]["scene"].instance()
	ship.type = type
	ship.set_name(str(player_id))
	return ship

# TODO: Refactor obv.
func get_npc_ship(ship_type, faction):
	var type = str(ship_type)
	var ship = ships[type]["scene"].instance()
	ship.type = type
	return ship

func load_galaxy():
	print("Loading Galaxy")
	systems = load_csv("res://data/galaxy.csv")
	for system in systems:
		preprocess_system(systems[system])
	ensure_link_reciprocity()
	print("Galaxy Loaded")
	Procgen.populate_galaxy()

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

func ensure_link_reciprocity():
	for system_id in systems:
		var system = systems[system_id]
		for link in system["links"]:
			var link_sys = systems[link]
			if not(system_id in link_sys["links"]):
				link_sys["links"].append(system_id)

func parse_color(color_text):
	var color_parsed = color_text.split(",")
	return Color(color_parsed[0], color_parsed[1], color_parsed[2])

func parse_bool(caps_true_or_false):
	return caps_true_or_false == "TRUE"

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

func _level_from_data(level_name, dat):
	var inhabited = "faction" in dat
	var inhabited_spob_found = false
	var level_id = int(level_name)
	var SCALE = 1
	var level = preload("res://gameplay/level.tscn").instance()
	level.dat = dat
	level.level_id = level_id
	var planet_type = preload("res://environment/spob.tscn")
	# Hack to deal with a bug in the galaxy generator script
	# (see the conditional on bad IDs below)
	var spob_counter = 10 * level_id
	
	# TODO: Stars
	
	# Planets from spreadsheet
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
			spob.spob_type = Procgen.select_spob_type(spob.spob_id, basic_type)
			spob.position = SCALE * Vector2(
				dat[prfx + "X"],
				dat[prfx + "Y"]
			)
			spob.name = dat[prfx + "Name"]
			if inhabited and not (spob_types[spob.spob_type]["uninhabited"] == "TRUE"):
				spob.commodities = Procgen.random_comodities(int(spob.spob_id))
				spob.faction = dat["faction"]
				inhabited_spob_found = true
			level.get_node("spobs").add_child(spob)
			
	# Moons from spreadsheet
	for moon_num in [1,2]:
		var prfx = "Moon %d " % moon_num
		if dat[prfx + "Exists?"] == "Exists" and _is_moon(dat[prfx + "Type"]):
			var spob = planet_type.instance()
			spob.spob_id = dat[prfx + "ID"]
			# Working around a bug in the spreadsheet
			if spob.spob_id == "#NUM!":
				spob_counter += 1
				spob.spob_id = str(spob_counter)
			spob.spob_type = Procgen.select_spob_type(spob.spob_id, "Moon")
			spob.position = SCALE * Vector2(
				dat[prfx + "X"],
				dat[prfx + "Y"]
			)
			spob.name = dat[prfx + "Name"]
			if inhabited and not (spob_types[spob.spob_type]["uninhabited"] == "TRUE"):
				spob.commodities = Procgen.random_comodities(level_id)
				spob.faction = dat["faction"]
				inhabited_spob_found = true
			level.get_node("spobs").add_child(spob)
	
	# Stations for systems with no useful spobs
	if inhabited and not inhabited_spob_found:
		var spob = planet_type.instance()
		spob.spob_type = Procgen.select_spob_type(level_id, "Station")
		spob.position = Vector2(0,0)
		spob.name = dat["System Name"] + " Station"
		spob.commodities = Procgen.random_comodities(level_id)
		spob.faction = dat["faction"]
		level.get_node("spobs").add_child(spob)
		# print("Added station: ", spob.name, " for faction: ", factions[spob.faction]["name"])
	return level
