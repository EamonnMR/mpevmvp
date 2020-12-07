extends Panel

class_name Store

var selected = null

func _ready():
	var button_class = preload("res://interface/landing/IconButton.tscn")
	
	for child in $Left/IconGrid.get_children():
		child.queue_free()
	for type in items():
		var button = button_class.instance()
		button.id = type
		button.data = items()[type]
		button.count = get_count(type)
		button.connect("pressed", self, "update_selection", [type])
		$Left/IconGrid.add_child( button )

func update():
	for button in $Left/IconGrid.get_children():
		# TODO: Why ain't this working?
		button.count = get_count(button.id)
		button.update()
	# TODO: Enable / Disable buy and sell buttons here

func items() -> Dictionary:
	return {}
	
func get_count(item_id) -> int:
	return 0

func update_selection(id):
	var data: Item = items()[id]
	selected = id
	$ItemName.text = data.name
	$desc.text = data.desc

func _on_leave_pressed():
	hide()

func _on_BuyButton_pressed():
	pass
