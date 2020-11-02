extends Node2D

export var start: String = ""
export var end: String = ""

func _draw():
	# print("if start: %s == Client.current_system_id(): %s and end: %s == Client.player_input.selected_system: %s: %s" % [start, Client.current_system_id(), end, Client.player_input.selected_system, start == Client.current_system_id() and end == Client.player_input.selected_system])
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
