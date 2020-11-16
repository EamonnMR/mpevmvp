extends Panel

class_name Store

var selected = null

func _ready():
	var button_class = preload("res://interface/landing/IconButton.tscn")
	
	for child in $Left/IconGrid.get_children():
		child.queue_free()
	for type in items():
		var button = button_class.instance()
		button.data = items()[type]
		button.connect("pressed", self, "on_grid_button_pressed", [type])
		$Left/IconGrid.add_child( button )

func items() -> Dictionary:
	return {}

func on_grid_button_pressed(id):
	update_selection(id)
	
func update_selection(id):
	var data: Item = items()[id]
	selected = id
	$ItemName.text = data.name
	$desc.text = data.desc

func _on_leave_pressed():
	hide()

func _on_BuyButton_pressed():
	pass
