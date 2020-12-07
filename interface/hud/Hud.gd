extends CanvasLayer

class_name Hud
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)
	# Connect to a bunch of events
	
func add_radar_pip(subject):
	$Radar.add_radar_pip(subject)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
