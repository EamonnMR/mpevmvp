extends Node2D

func get_color():
	# TODO: Show status
	return Color(0,0,1)

func _draw():
	draw_circle(Vector2(0,0), 7, get_color())
	draw_circle(Vector2(0,0), 5, Color(0,0,0))
