extends Node2D

func _ready():
	if get_node("../").texture:
		var rect_size = get_node("../").texture.get_size()
		var rect_position = rect_size / -2
		for child in get_children():
			child.rect_size = rect_size
			child.rect_position = rect_position
	set_disposition("Friendly")

func set_disposition(disposition):
	for child in get_children():
		child.show() if child.name == disposition else child.hide()
