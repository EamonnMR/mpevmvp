extends Node2D

func _ready():
	if get_node("../").texture:
		$NinePatchRect.rect_size = get_node("../").texture.get_size()
		$NinePatchRect.rect_position = $NinePatchRect.rect_size / -2
