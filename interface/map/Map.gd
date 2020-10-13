extends CanvasLayer

var dragging = false

func _ready():
	for item in [
		"Disposition",
		"Distance from core",
		"Political"
	]:
		$Mode.add_item(item)
	
	var system_scene = preload("res://interface/map/system.tscn")
	var line_scene = preload("res://interface/map/line.tscn")
	for system_id in Game.systems:
		for destination in Game.systems[system_id]["links"]:
			print(Game.systems[system_id]["links"])
			var line = line_scene.instance()
			line.start = system_id
			line.end = destination
			$Panel/systems.add_child(line)
	for system_id in Game.systems:
		# TODO: Tons of stuff, including:
		# show hide systems based on discovery
		var sys = Game.systems[system_id]
		var system = system_scene.instance()
		system.system_name = sys["System Name"]
		system.system_id = system_id
		system.position = sys["position"]  # TODO: Proper Scaling
		$Panel/systems.add_child(system)

func _input(event):
	if event is InputEventMouseButton:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		$Panel/systems.position += event.relative

func update():
	for system in $Panel/systems.get_children():
		if system.get_node("circle"):
			system.get_node("circle").update()


func _on_Mode_item_selected(index):
	update()
