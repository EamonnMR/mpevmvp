extends Node2D

export var start: String = ""
export var end: String = ""

func _draw():
	# TODO: Make it green if selected
	draw_line(
		Game.systems[start]["position"], Game.systems[end]["position"],
		Color(.7,.7,.7)
	)
