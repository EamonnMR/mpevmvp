extends Node2D

# The 'get level' mechanism lets this load levels in the
# background

func _get_universe():
	return get_children()[0]

func get_level():
	if (_get_universe().has_node("world")):
		return _get_universe().get_node("world")
	else:
		return null

func switch_level(new_level_name, level_data):
	var old_level = get_level()
	if old_level:
		old_level.queue_free()
		_get_universe().remove_child(old_level)
	_get_universe().name = new_level_name
	var new_level = Game.get_level(new_level_name)
	new_level.deserialize(level_data)
	new_level.name = "world"
	_get_universe().add_child(new_level)
	assert(new_level == _get_universe().get_node("world"))
	$SystemChangeSound.play()
