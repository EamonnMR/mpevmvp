extends Node2D

export var system_name: String = "Name"

func _ready():
	$Label.text = system_name

func clicked():
	print("Clicked: ", system_name)
