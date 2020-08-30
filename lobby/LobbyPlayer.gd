extends HBoxContainer

export var player = {}

func _ready():
	# player needs to be set externally or this class will break
	assert(len(player) > 0)
	$PlayerName.text = str(player["name"])
	$ShipSelection.text = str(player["ship"])
