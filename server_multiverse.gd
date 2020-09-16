extends Node2D

func _ready():
	for system_id in Game.systems:
		create_level(str(system_id))

func create_level(level_name):
	var level = Viewport.new()
	level.name = level_name
	var world = Game.get_level("level_name")
	world.name = "world"
	level.add_child(world)
	add_child(level)

func get_level(level_name):
	return get_node(level_name).get_node("world")

func switch_player_level(player, new_level_name):
	var new_level = get_level(new_level_name)
	player.get_parent().remove_child(player)
	new_level.get_node("players").add_child(player)
