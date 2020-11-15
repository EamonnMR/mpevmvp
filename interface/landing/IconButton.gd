extends TextureButton

var data: Item

func _ready():
	print("res://" + data.icon)
	texture_normal = load("res://" + data.icon)
	$Label.text = data.name
