extends Node2D

export var system_name: String = "Name"
export var system_id: String

var data: Dictionary = {}

func _ready():
	$Label.text = system_name
	data = Game.systems[system_id]

func clicked():
	print("Clicked: ", system_name)
	get_input().map_select_system(system_id)
	$circle.update()
func get_input():
	return get_tree().get_root().get_node(Game.INPUT).get_children()[0]
