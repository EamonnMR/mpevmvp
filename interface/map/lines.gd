extends Node2D

export var start: String = ""
export var end: String = ""

func _draw():
	if start == Client.current_system_id() and end == Client.player_input.selected_system:
		draw_line(
			Game.systems[start]["position"], Game.systems[end]["position"],
			Color(.5,1,.5),
			3
		)
	else:
		draw_line(
			Game.systems[start]["position"], Game.systems[end]["position"],
			Color(.7,.7,.7)
		)
