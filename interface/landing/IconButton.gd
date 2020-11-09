extends TextureButton

export var ship_data: Dictionary = {}
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("res://" + ship_data["icon"])
	texture_normal = load("res://" + ship_data["icon"])
	$Label.text = ship_data["name"]
