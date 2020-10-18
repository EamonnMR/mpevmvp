extends Node
var systems = null
var ships = null
var spob_types = null
var commodities = null
var factions = null
var spobs = {}

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
	var boolean_fields = [
		"is_default",
		"spawn_anywhere",
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
	ensure_link_reciprocity()
	print("Galaxy Loaded")
	populate_galaxy()

func system_distance_comparitor(l_id, r_id) -> bool:
	var lval = systems[l_id]["distance"]
	var rval = systems[r_id]["distance"]
	return lval < rval

func systems_sorted_by_distance() -> Array:
	var system_ids = systems.keys()
	system_ids.sort_custom(self, "system_distance_comparitor")
	return system_ids

func populate_galaxy():
	print("Populating Galaxy")
	var core_worlds = randomly_assign_faction_core_worlds()
	core_worlds += assign_peninsula_bonus_worlds()
	grow_faction_influence_from_core_worlds()
	print("Galaxy populated")
	
func randomly_assign_faction_core_worlds() -> Array:
	print("Randomly Assigning core worlds ")
	calculate_system_distances()
	var sorted = systems_sorted_by_distance()
	var sorted_reverse = sorted.duplicate().invert()
	var rng = RandomNumberGenerator.new()
	rng.seed = sorted.hash()
	var already_selected = []
	for faction_id in factions:
		var faction = factions[faction_id]
		var i = 0
		while i < int(int(faction["core_systems_per_500"]) * (systems.size() / 500)):
			var rnd_result = abs(rng.randfn(0.0))
			var scale = int(faction["favor_galactic_center"])
			var scaled_rnd_result = 0
			if scale:
				scaled_rnd_result = int(rnd_result * (sorted.size() / scale))
			else:
				scaled_rnd_result = rng.randi_range(0, sorted.size())
			if scaled_rnd_result > sorted.size():
				print("Long tail too long: ", rnd_result, " (", scaled_rnd_result, ")")
				continue
			var system_id = sorted[scaled_rnd_result]
			if system_id in already_selected:
				print("Collision: ", system_id)
				continue
			else:
				systems[system_id]["faction"] = faction_id
				systems[system_id]["core"] = true
				already_selected.append(system_id)
				i += 1
	print("Core worlds assigned")
	return already_selected

func assign_peninsula_bonus_worlds() -> Array:
	# The 'peninsula bonus' field lets you add core worlds to systems with only one link.
	# This adds a little flavor.
	var peninsula_factions = []
	var core_systems = []
	for faction_id in factions:
		var faction = factions[faction_id]
		if faction["peninsula_bonus"]:
			peninsula_factions.append(faction_id)
	var i = 0
	if peninsula_factions.size():
		print("Assigning factions to systems with only one connection")
		for system_id in systems:
			var system = systems[system_id]
			if system["links"].size() == 1 and not "faction" in system:
				# TODO: Randomize, don't just iterate through
				system["faction"] = peninsula_factions[i]
				core_systems.append(system_id)
				i += 1
				if i == peninsula_factions.size():
					i = 0
	return core_systems

func grow_faction_influence_from_core_worlds():
	# TODO: This is obviously not optimal
	print("Growing faction influence")
	for faction_id in factions:
		var faction = factions[faction_id]
		for i in range(faction["systems_radius"]):
			print("Full iteration: ", faction["name"], ", iteration: ", i)
			var marked_systems = []
			for system_id in systems:
				var system = systems[system_id]
				for link_id in system["links"]:
					var link_system = systems[link_id]
					if "faction" in link_system and link_system["faction"] == faction_id:
						marked_systems.append(system_id)
						break
			for system_id in marked_systems:
				var system = systems[system_id]
				system["faction"] = faction_id
				
	print("Factions grown")

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
	var inhabited = "faction" in dat
	var inhabited_spob_found = false
	var level_id = int(level_name)
	var SCALE = 1
	var level = preload("res://gameplay/level.tscn").instance()
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
			spob.spob_type = _select_spob_type(spob.spob_id, basic_type)
			spob.position = SCALE * Vector2(
				dat[prfx + "X"],
				dat[prfx + "Y"]
			)
			spob.name = dat[prfx + "Name"]
			if inhabited and not (spob_types[spob.spob_type]["uninhabited"] == "TRUE"):
				spob.commodities = random_comodities(int(spob.spob_id))
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
			spob.spob_type = _select_spob_type(spob.spob_id, "Moon")
			spob.position = SCALE * Vector2(
				dat[prfx + "X"],
				dat[prfx + "Y"]
			)
			spob.name = dat[prfx + "Name"]
			if inhabited and not (spob_types[spob.spob_type]["uninhabited"] == "TRUE"):
				spob.commodities = random_comodities(level_id)
				spob.faction = dat["faction"]
				inhabited_spob_found = true
			level.get_node("spobs").add_child(spob)
	
	# Stations for systems with no useful spobs
	if inhabited and not inhabited_spob_found:
		var spob = planet_type.instance()
		spob.spob_type = _select_spob_type(level_id, "Station")
		spob.position = Vector2(0,0)
		spob.name = dat["System Name"] + " Station"
		spob.commodities = random_comodities(level_id)
		spob.faction = dat["faction"]
		level.get_node("spobs").add_child(spob)
		print("Added station: ", spob.name, " for faction: ", factions[spob.faction]["name"])
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
