extends Node2D

var subject: Node2D
var radar_scale = 1.0 / 20.0
var size: int

# Note that these disposition colors are slightly different from the map ones.
var DISPOSITION_COLORS = {
	"hostile": Color(1,0,0),
	"neutral": Color(1,1,0),
	"abandoned": Color(0.5, 0.5, 0.5),
	"player": Color(1,1,1)
}

func _radar_offset():
	return get_node("../").rect_size / 2
	
func _relative_position():
	return subject.position - Client.player_ship.position

func _process(delta):
	# TODO: This is kind of hacky
	if subject == null:
		queue_free()
	else:
		if is_instance_valid(Client.player_ship) and Client.player_ship:
			show()
			if is_instance_valid(subject):
				position = (_relative_position() * radar_scale) + _radar_offset()
			else:
				queue_free()
		else:
			hide()

func get_color() -> Color:
	if subject == Client.player_ship:
		return DISPOSITION_COLORS["player"]
	# return DISPOSITION_COLORS["neutral"]
	if subject == null:
		return DISPOSITION_COLORS["abandoned"]
	if "faction" in subject:
		if not(subject.faction in Game.factions):
			return DISPOSITION_COLORS["abandoned"]
		var faction = Game.factions[subject.faction]
		var disposition = faction["initial_disposition"]
		if disposition < 0:
			return DISPOSITION_COLORS["hostile"]
		else:
			return DISPOSITION_COLORS["neutral"]
	else:
		return DISPOSITION_COLORS["abandoned"]

func get_size():
	if subject is Spob:
		return {
			"Planet": 5,
			"Moon": 3,
			"Planetary System": 6,
			"Station": 2,
			"Gas_Giant": 8
		}[subject.kind]
	elif subject is Ship:
		# TODO: Check ship mass
		return 2

func _draw():
	draw_circle(Vector2(0,0), size, get_color())
	if size > 3:
		draw_circle(Vector2(0,0), size - 2, Color(0,0,0))

func _ready():
	size = get_size()
