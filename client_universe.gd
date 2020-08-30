extends Node2D

var current_level = null

# The 'get level' mechanism lets this load levels in the
# background

func _ready():
	current_level = get_children()[0].name

func _get_universe():
	return get_children()[0]

func get_level():
	return _get_universe().get_node("world")

func switch_level(new_level_name, level_data):
	var old_level = get_level()
	old_level.queue_free()
	_get_universe().remove_child(old_level)
	_get_universe().name = new_level_name
	current_level = new_level_name
	var new_level = load("res://levels/" + new_level_name + ".tscn").instance()
	new_level.deserialize(level_data)
	new_level.name = "world"
	_get_universe().add_child(new_level)
	_get_universe().print_tree_pretty()
	assert(new_level == _get_universe().get_node("world"))
