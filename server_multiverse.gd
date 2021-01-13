extends Node2D

func _ready():
	call_deferred("_create_systems")

func _create_systems():
	# Call deferred to avoid a race where we haven't loaded the data yet.
	print("Creating systems")
	for system_id in Game.systems:
		create_level(str(system_id))

func create_level(level_name):
	var level = Viewport.new()
	level.world_2d = World2D.new()
	level.own_world = true
	level.name = level_name
	var world = Game.get_level(level_name)
	world.name = "world"
	level.add_child(world)
	add_child(level)

func get_level(level_name):
	return get_node(level_name).get_node("world")

func switch_ship_level(ship, new_level_name):
	var new_level = get_level(new_level_name)
	var parent = ship.get_parent()
	parent.remove_child(ship)
	new_level.get_node(parent.name).add_child(ship)
