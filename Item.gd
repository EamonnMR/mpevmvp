extends DataRow

class_name Item

# Superclass for items that can be displayed in a store view.

var id: int
var name: String
var icon: String
var desc: String
var price: int

func get_keys():
	var keys = []
	var props = get_property_list()
	for prop in props:
		if not (prop["name"] in ["name", "Script", "script", "Script Variables", "faction"]):
			keys.append(prop["name"])
	return keys
