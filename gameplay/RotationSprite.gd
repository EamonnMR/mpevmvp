extends AnimatedSprite

class_name RotationSprite

export var rotation_offset: int = 9
const ARC: float = 2 * PI



func set_direction(direction):
	var direction_fraction = direction / (PI * 2)
	var frame_count = get_sprite_frames().get_frame_count("default")
	frame = int(round((direction_fraction * frame_count) + rotation_offset)) % frame_count

func get_size() -> Vector2:
	return get_sprite_frames().get_frame("default", frame).get_size()
