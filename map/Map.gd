extends CanvasLayer

var dragging = false

func _ready():
	var system_scene = preload("res://map/system.tscn")
	for system_id in Game.systems:
		# TODO: Tons of stuff, including:
		# show hide systems based on discovery
		var sys = Game.systems[system_id]
		var system = system_scene.instance()
		system.system_name = sys["System Name"]
		system.position = Vector2(sys["System X"], sys["System Y"]) * 2  # TODO: Proper Scaling
		$Panel/systems.add_child(system)

func _input(event):
	if event is InputEventMouseButton:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		$Panel/systems.position += event.relative
