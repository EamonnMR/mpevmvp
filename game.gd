# This is chiefly concerned with handling the follwing details:

# How the various nodes interact
# How CSV files are turned into nodes

extends Node
var systems = null
var ships = null
var spob_types = null
var commodities = null
var factions = null
var spobs = {}
var ships_by_faction = {}
var weapons = {}
var upgrades = {}

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

func get_multiverse():
	return get_tree().get_root().get_node("Multiverse")

func _ready():
	call_deferred("load_multiple_csvs", {
		"spob_types": "res://data/spob_types.csv",
		"commodities": "res://data/trade.csv",
		"factions": "res://data/factions.csv",
		"ships": "res://data/ships.csv",
		"weapons": "res://data/weapons.csv",
		"upgrades": "res://data/upgrades.csv"
	}, "process_data")

func process_data():
	load_spob_types()
	load_commodities()
	load_factions()
	load_weapons()
	load_upgrades()
	load_galaxy()
	load_ships()
	print("Game Ready")

func load_multiple_csvs(csv_dict, callback):
	# Load CSV wants to be called in a deferred fashon.
	# This calls each in sequence deferred, then finally calls
	# the callback function.
	var keys = csv_dict.keys()
	if keys.size():
		var key = keys[0]
		set(key, load_csv(csv_dict[key]))
		csv_dict.erase(key)
		call_deferred("load_multiple_csvs", csv_dict, callback)
	else:
		call_deferred(callback)
	

func random_select(items: Array):
	# Don't use this for procgen, because it is unseeded
	randomize()
	return items[randi() % items.size()]

func load_spob_types():
	for spob_type_id in spob_types:
		var spob_type = spob_types[spob_type_id]
		spob_type["sprite"] = load(spob_type["sprite"]) if spob_type["sprite"] else null
		spob_type["landing"] = load(spob_type["landing"]) if spob_type["landing"] else null
	
	Procgen.index_spob_types()
			
func load_commodities():
	for commodity_id in commodities:
		var commodity = commodities[commodity_id]
		var price = int(commodity["price"])
		commodity["prices"] = {
			price_factors.LOW: int(PRICE_LOW * price),
			price_factors.MED: price,
			price_factors.HIGH: int(PRICE_HIGH * price)
		}
		
func load_factions():
	# TODO: Support this kind of parsing out of the box, in load_csv maybe
	# as a template somehow?
	var boolean_fields = [
		"is_default",
		"spawn_anywhere",
		"host_spawn_anywhere",
		"peninsula_bonus"
	]
	
	var int_array_fields = [
		"allies",
		"enemies"
	]
	
	var float_fields = [
		
	]
	
	for faction_id in factions:
		var faction = factions[faction_id]
		faction["color"] = parse_color(faction["color"])
		faction["initial_disposition"] = int(faction["initial_disposition"])
		
		for field in boolean_fields:
			faction[field] = parse_bool(faction[field])
			
		for field in int_array_fields:
			faction[field] = parse_int_array(faction[field])
		
func load_ships():
	for i in ships:
		var dict = ships[i]
		var ship = ShipDat.new(ships[i])
		
		if ship.faction in ships_by_faction:
			ships_by_faction[ship.faction].append(ship.id)
		else:
			ships_by_faction[ship.faction] = [ship.id]
		ships[i] = ship

func load_weapons():
	var int_fields = [
		"damage"
	]
	
	var float_fields = [
		"projectile_lifetime",
		"cooldown"
	]
	
	var scene_fields = [
		"projectile_scene"
	]
	
	var sound_fields = [
		"sound_effect"
	]
	for weapon_id in weapons:
		var weapon = weapons[weapon_id]
		for field in int_fields:
			weapon[field] = int(weapon[field])
		for field in float_fields:
			weapon[field] = float(weapon[field])
		for field in scene_fields:
			weapon[field] = load(weapon[field])
		for field in sound_fields:
			weapon[field] = GdScriptAudioImport.loadfile(weapon[field])
			weapon[field].loop = false
			
func load_upgrades():
	for i in upgrades:
		upgrades[i] = Upgrade.new(upgrades[i])

func get_ship(ship_type, player_id):
	var type = str(ship_type)
	print("Type: ", type)
	print("Scene: ", ships[type].scene)
	var ship = ships[type].scene.instance()
	ship.apply_stats(type)
	ship.set_name(str(player_id))
	return ship

# TODO: Refactor obv.
func get_npc_ship(ship_type, faction):
	var type = str(ship_type)
	var ship = ships[type]["scene"].instance()
	ship.apply_stats(type)
	ship.faction = faction
	return ship

func load_galaxy():
	print("Loading Galaxy")
	systems = load_csv("res://data/galaxy.csv")
	for system in systems:
		preprocess_system(systems[system])
	# ensure_link_reciprocity()  # Trust the spreadsheet
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

func parse_color(color_text) -> Color:
	var color_parsed = color_text.split(",")
	return Color(color_parsed[0], color_parsed[1], color_parsed[2])
	
func parse_int_array(text: String) -> Array:
	var int_array = []
	for i in text.split(" "):
		int_array.append(int(i))
	return int_array

func parse_bool(caps_true_or_false: String) -> bool:
	return caps_true_or_false == "TRUE"
	
func parse_x_dict(x_dict: String) -> Dictionary:
	""" Looks like: '1x4 0x3' and translates to:
		{
			"1": 4,
			"0": 3
		}
	"""
	var dict = {}
	for i in x_dict.split(" "):
		var key_count = i.split("x")
		dict[key_count[0]] = int(key_count[1])
	return dict

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
		return Procgen._level_from_data(level_name, systems[level_name])
