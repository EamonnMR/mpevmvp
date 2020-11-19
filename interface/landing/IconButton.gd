extends TextureButton

var data: Item
var id: String
var count: int

func _ready():
	texture_normal = load("res://" + data.icon)
	$Label.text = data.name
	update()

func update():
	$Count.text = str(count) if count else ""
