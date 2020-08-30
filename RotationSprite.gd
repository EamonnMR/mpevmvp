extends AnimatedSprite

var diection
export var rotation_offset: int = 9
const ARC: float = 2 * PI

func _ready():
	set_direction(0)

func set_direction(direction):
	var direction_fraction = direction / (PI * 2)
	var direction_degrees = direction_fraction * 360
	var frame_count = get_sprite_frames().get_frame_count("default")
	frame = int(round((direction_fraction * frame_count) + rotation_offset)) % frame_count
