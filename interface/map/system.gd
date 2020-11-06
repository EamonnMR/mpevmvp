extends Node2D

export var system_name: String = "Name"
export var system_id: String

var data: Dictionary = {}

func _ready():
	$Label.text = system_name
	data = Game.systems[system_id]

func clicked():
	print("Clicked: ", system_name)
	Client.player_input.map_select_system(system_id)
	$circle.update()

