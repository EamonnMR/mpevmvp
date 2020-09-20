extends AnimatedSprite

export var rotation_offset: int = 9
const ARC: float = 2 * PI

var _frames

func set_direction(direction):
	var direction_fraction = direction / (PI * 2)
	var frame_count = get_sprite_frames().get_frame_count("default")
	frame = int(round((direction_fraction * frame_count) + rotation_offset)) % frame_count
