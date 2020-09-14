extends Node2D

func _ready():
	print("Load Galaxy: ")
	Game.load_galaxy()
	print("Galaxy Load Complete")
	

func get_level(level_name):
	return get_node(level_name).get_node("world")

func switch_player_level(player, new_level_name):
	var new_level = get_level(new_level_name)
	player.get_parent().remove_child(player)
	new_level.get_node("players").add_child(player)
