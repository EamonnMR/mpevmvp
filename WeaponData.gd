class_name WeaponData

var id: int
var damage: int
var projectile_velocity: int
var projectile_lifetime: float
var cooldown: float
var arc: int
var projectile_scene: PackedScene
var sound_effect: AudioStream

func _init(data: Dictionary):
	var props = get_property_list()
	for prop in props:
		var prop_name = prop["name"]
		if prop_name in data:
			var val
			var type: int = prop["type"]
			var string_val = data[prop_name]

			if type == TYPE_INT:
				val = int(string_val)
			elif type == TYPE_REAL:
				val = float(string_val)
			elif type == TYPE_OBJECT:
				var type_class: String = prop["class_name"]
				if type_class in ["PackedScene", "Texture"]:
					val = load(string_val)
				elif type_class == "AudioStream":
					val = GdScriptAudioImport.loadfile(string_val)
				else:
					print("Unknown class: ", type_class)
			else:
				print("Unusable type: ", type, " for column ", prop_name)
			set(prop_name, val)
