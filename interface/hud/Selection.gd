extends Node2D

const MIN_SIZE = 40

func _ready():
	var parent = get_node("../")
	# TODO: Correctly assess parent's class
	# Sprite
	var rect_size: Vector2 = Vector2(0,0)
	if parent is Sprite:
		rect_size = parent.texture.get_size()
	# RotationSprite
	elif parent is RotationSprite:
		rect_size = parent.get_size()
	rect_size = Vector2(max(MIN_SIZE, rect_size[0]), max(MIN_SIZE, rect_size[1]))
	var rect_position = rect_size / -2
	for child in get_children():
		child.rect_size = rect_size
		child.rect_position = rect_position
	set_disposition("Friendly")

func set_disposition(disposition):
	for child in get_children():
		child.show() if child.name == disposition else child.hide()
