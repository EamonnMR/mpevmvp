extends Node2D

func get_color():
	# TODO: Show status
	return Color(0,0,1)

func _draw():
	draw_circle(Vector2(0,0), 20, get_color())
