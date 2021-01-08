# Class with utility functions for procedurally generating a universe.

# Because this is run on both the client and server, ensure that any random
# functions used are seeded, and that the seed isn't just, say, the ID of the
# spob or system. The goal is to have a unique universe for each galaxy.csv
# that the spreadsheet generates.

extends Node

var spob_types_grouped = {}

# Left side: types as seen by the spreadsheet
# Right side: types as seen in spob_types.csv.
# (Except station, which is in there because
# we add stations directly)
const SPOB_TYPES_MAP = {
	"Gas Giant": "Gas_Giant",
	"Rocky Planet": "Planet",
	"Large Asteroid": "Moon",
	"Moon": "Moon",
	"Rock Ring": "Moon",
	"Ice Ring": "Moon",
	"Station": "Station"
}

func index_spob_types():
	# Maps spob types by 'kind' (planet, moon, station, etc)
	for spob_type_id in Game.spob_types:
		var spob_type = Game.spob_types[spob_type_id]
		if spob_type["kind"] in spob_types_grouped:
			spob_types_grouped[spob_type["kind"]].append(spob_type_id)
		else:
			spob_types_grouped[spob_type["kind"]] = [spob_type_id]

func random_comodities(id):
	var spob_commodities = {}
	var rng_seed = int(id)
	for comodity_id in Game.commodities:
		# This code deals with making sure it's random, but also
		# replicated exactly the same way on every start
		var comodity = Game.commodities[comodity_id]
		var result = rand_seed(rng_seed)
		var price_rng = result[0]
		rng_seed = result[1]
		result = rand_seed(rng_seed)
		var presence_rng = result[0]
		rng_seed = result[1]
		
		if abs(presence_rng % 2):
			spob_commodities[comodity_id] = {
				0: Game.price_factors.LOW,
				1: Game.price_factors.MED,
				2: Game.price_factors.HIGH,
			}[abs(price_rng % 3)]
	return spob_commodities

func select_spob_type(id, basic_type):
	var rng_value = rand_seed(int(id))[0]
	var mapped_type = SPOB_TYPES_MAP[basic_type]
	var spob_type_group = spob_types_grouped[mapped_type]
	return spob_type_group[abs(rng_value % spob_type_group.size())]

func populate_galaxy():
	print("Populating Galaxy")
	var _core_worlds = randomly_assign_faction_core_worlds()
	_core_worlds += assign_peninsula_bonus_worlds()
	grow_faction_influence_from_core_worlds()
	grow_npc_spawns()
	assign_names_to_systems()
	print("Galaxy populated")
	

func randomly_assign_faction_core_worlds() -> Array:
	print("Randomly Assigning core worlds ")
	calculate_system_distances()
	var sorted = systems_sorted_by_distance()
	var sorted_reverse = sorted.duplicate().invert()
	var rng = RandomNumberGenerator.new()
	rng.seed = sorted.hash()
	var already_selected = []
	for faction_id in Game.factions:
		var faction = Game.factions[faction_id]
		var i = 0
		while i < int(int(faction.core_systems_per_500) * (Game.systems.size() / 500)):
			var rnd_result = abs(rng.randfn(0.0))
			var scale = int(faction.favor_galactic_center)
			var scaled_rnd_result = 0
			if scale:
				scaled_rnd_result = int(rnd_result * (sorted.size() / scale))
			else:
				print(0, sorted.size())
				scaled_rnd_result = rng.randi_range(0, sorted.size())
			if scaled_rnd_result > sorted.size() or scaled_rnd_result < 0 - sorted.size():
				print("Long tail too long: ", rnd_result, " (", scaled_rnd_result, ")")
				continue
			var system_id = sorted[scaled_rnd_result]
			if system_id in already_selected:
				print("Collision: ", system_id)
				continue
			else:
				Game.systems[system_id]["faction"] = faction_id
				Game.systems[system_id]["core"] = true
				add_npc_spawn(Game.systems[system_id], faction_id, int(faction["npc_radius"]) + int(faction["systems_radius"]))
				already_selected.append(system_id)
				i += 1
	print("Core worlds assigned")
	return already_selected

func calculate_system_distances():
	var sum_position = Vector2(0,0)
	
	for system_id in Game.systems:
		var system = Game.systems[system_id]
		sum_position += system["position"]
		
	var mean_position = sum_position / Game.systems.size()

	var max_distance = 0
	for system_id in Game.systems:
		var system = Game.systems[system_id]
		system["distance"] = mean_position.distance_to(system["position"])
		if system["distance"] > max_distance:
			max_distance = system["distance"]
		
	for system_id in Game.systems:
		var system = Game.systems[system_id]
		system["distance_normalized"] = system["distance"] / max_distance


func assign_peninsula_bonus_worlds() -> Array:
	# The 'peninsula bonus' field lets you add core worlds to systems with only one link.
	# This adds a little flavor.
	var peninsula_factions = []
	var core_systems = []
	for faction_id in Game.factions:
		var faction = Game.factions[faction_id]
		if faction["peninsula_bonus"]:
			peninsula_factions.append(faction_id)
	var i = 0
	if peninsula_factions.size():
		print("Assigning factions to systems with only one connection")
		for system_id in Game.systems:
			var system = Game.systems[system_id]
			if system["links"].size() == 1 and not "faction" in system:
				# TODO: Randomize, don't just iterate through
				system["faction"] = peninsula_factions[i]
				add_npc_spawn(system, peninsula_factions[i], 10)
				core_systems.append(system_id)
				i += 1
				if i == peninsula_factions.size():
					i = 0
	return core_systems

func grow_faction_influence_from_core_worlds():
	# TODO: This is obviously not optimal
	print("Growing faction influence")
	for faction_id in Game.factions:
		var faction = Game.factions[faction_id]
		print(faction.systems_radius)
		for i in range(faction.systems_radius):
			print("Full iteration: ", faction["name"], ", iteration: ", i)
			var marked_systems = []
			for system_id in Game.systems:
				var system = Game.systems[system_id]
				for link_id in system["links"]:
					var link_system = Game.systems[link_id]
					if "faction" in link_system and link_system["faction"] == faction_id:
						marked_systems.append(system_id)
						break
			for system_id in marked_systems:
				var system = Game.systems[system_id]
				system["faction"] = faction_id
				add_npc_spawn(system, faction_id, int(faction["npc_radius"]) + int(faction["systems_radius"]) - i)
				
	print("Factions grown")

func add_npc_spawn(system, faction_id, count):
	if "npc_spawns" in system:
		if not (faction_id in system["npc_spawns"]):
			system["npc_spawns"].append(faction_id)
	else:
		system["npc_spawns"] = [faction_id]
	if "npc_count" in system:
		system["npc_count"] = max(system["npc_count"], count)
	else:
		system["npc_count"] = count

func grow_npc_spawns():
	# TODO: This is also obviously not optimal
	print("Growing faction spawns")
	for faction_id in Game.factions:
		var faction = Game.factions[faction_id]
		print(faction.npc_radius)
		for i in range(faction.npc_radius):
			var marked_systems = []
			for system_id in Game.systems:
				var system = Game.systems[system_id]
				for link_id in system["links"]:
					var link_system = Game.systems[link_id]
					if "npc_spawns" in link_system and faction_id in link_system["npc_spawns"]:
						marked_systems.append(system_id)
						break
			for system_id in marked_systems:
				add_npc_spawn(Game.systems[system_id], faction_id, int(faction["npc_radius"]) - i)
	
	print("Adding 'spawn anywhere' spawns")
	
	var spawn_anywhere_factions = []
	var spawn_anywhere_hosts = []
	for faction_id in Game.factions:
		var faction = Game.factions[faction_id]
		if faction.spawn_anywhere:
			spawn_anywhere_factions.append(faction_id)
		if faction["host_spawn_anywhere"]:
			spawn_anywhere_hosts.append(faction_id)
	
	for system_id in Game.systems:
		var system = Game.systems[system_id]
		if "npc_spawns" in system:
			for faction_id in spawn_anywhere_hosts:
				if faction_id in system["npc_spawns"]:
					system["npc_spawns"] += spawn_anywhere_factions
					break

func assign_names_to_systems():
	print("Assigning names to systems")
	for system_id in Game.systems:
		var system = Game.systems[system_id]
		if "npc_spawns" in system:
			system["System Name"] = Markov.get_random_name("", int(system_id))

func system_distance_comparitor(l_id, r_id) -> bool:
	var lval = Game.systems[l_id]["distance"]
	var rval = Game.systems[r_id]["distance"]
	return lval < rval

func systems_sorted_by_distance() -> Array:
	var system_ids = Game.systems.keys()
	system_ids.sort_custom(self, "system_distance_comparitor")
	return system_ids

func _is_moon(moon_type):
	# We can't use "Category" for reasons I don't understand; it fails to load from the csv
	# So we get this hack
	return ("Moon" in moon_type) or ("moon" in moon_type)

func _level_from_data(level_name, dat):
	var inhabited = "faction" in dat
	var near_inhabited = inhabited or "npc_spawns" in dat
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
			spob.name = Markov.get_random_name( "",
				Game.systems.size() + (planet_num + 100 * int(level_name))
			) if near_inhabited else dat[prfx + "Name"]
			if inhabited and not (Game.spob_types[spob.spob_type]["uninhabited"] == "TRUE"):
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
			spob.name = Markov.get_random_name( "",
				Game.systems.size() + 3 + (moon_num + 100 * int(level_name))
			) if near_inhabited else dat[prfx + "Name"]
			if inhabited and not (Game.spob_types[spob.spob_type]["uninhabited"] == "TRUE"):
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
