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
var scene_cache = {}

const INPUT = "input_nodes"
const PLAY_AREA_RADIUS = 2000
const JUMP_DISTANCE = 600

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
	_load_mods()
	
	call_deferred("load_multiple_csvs", {
		"spob_types": "res://data/spob_types.csv",
		"commodities": "res://data/trade.csv",
		"factions": "res://data/factions.csv",
		"ships": "res://data/ships.csv",
		"weapons": "res://data/weapons.csv",
		"upgrades": "res://data/upgrades.csv"
	}, "process_data")
	
func list_files_in_directory(path):
	# https://godotengine.org/qa/1349/find-files-in-directories
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()
	return files
	
func _load_mods():
	for mod in list_files_in_directory("plugins"):
		var success = ProjectSettings.load_resource_pack("plugins/" + mod)
		if success: 
			print("Plugin successfully: ", mod)
		else:
			print("Plugin failed to load: ", mod)

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
		set(key, DataRow.load_csv(csv_dict[key]))
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
	for faction_id in factions:
		factions[faction_id] = Faction.new(factions[faction_id])
		
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
	for i in weapons:
		var wep = weapons[i]
		weapons[i] = WeaponData.new(weapons[i])
	
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
func get_npc_ship(ship_type: int, faction: String):
	var type = str(ship_type)
	var ship = ships[type]["scene"].instance()
	ship.apply_stats(type)
	ship.faction = faction
	return ship

func load_galaxy():
	print("Loading Galaxy")
	systems = DataRow.load_csv("res://data/galaxy.csv")
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
	
func get_level(level_name):
	var directory = Directory.new();
	var file_path = "res://levels/" + level_name + ".tscn"
	if directory.file_exists(file_path):
		return load(file_path).instance()
	else:
		return Procgen._level_from_data(level_name, systems[level_name])

func random_ship_for_faction(faction_id: int):
	return random_select(ships_by_faction[faction_id])
