extends Node2D

export var spob_name: String
export var landing: String
export var spob_type: String
export var kind: String
export var biome: String
export var desc: String

var SPOB_STATS = [
	"kind",
	"biome",
	"desc"
]

func _ready():
	_apply_stats()
	
func _data():
	return Game.spob_types[spob_type]

func _apply_stats():
	for stat in SPOB_STATS:
		if _data()[stat] and not get(stat):
			set(stat, _data()[stat])
	if not $sprite.texture:
		$sprite.texture = _data()["sprite"]
