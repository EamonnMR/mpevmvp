extends Node2D

func get_color():
	# TODO: Show status
	return Color(0,0,1)

func _draw():
	print("Selected: ", get_node("../").get_input().selected_system, " but I am ", get_node("../").system_id)
	if get_node("../").get_input().selected_system == get_node("../").system_id:
		draw_circle(Vector2(0,0), 9, Color(0,1,0))
	
	draw_circle(Vector2(0,0), 7, get_color())
	draw_circle(Vector2(0,0), 5, Color(0,0,0))
	
	if Client.get_level().name == get_node("../").system_id:
		draw_circle(Vector2(0,0), 2, Color(0,1,0))
