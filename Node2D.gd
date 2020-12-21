extends Area2D

var source
var damage
var team_set

func _ready():
	get_node("../").remove_child(self)
	source.add_child(self)

func _physics_process(delta):
	self.rotation = get_node("../").direction
	
func init(speed, new_damage, lifetime, start_angle, new_position, new_velocity, source):
	damage = new_damage
	$Timer.wait_time = lifetime
	self.source = source
	#_show_debug_info()

func _draw():
	draw_line(
		Vector2(0,0), Vector2($Ray.shape.length, 0),
		Color(.5,1,.5),
		3
	)

func _on_Timer_timeout():
	queue_free()

func _on_beam_body_entered(body):
	for team_flag in team_set:
		if body.team_set.has(team_flag):
			#print("Ignoring friendly fire")
			#print("Shot Flags: ", team_set, " Target Flags: ", body.team_set)
			return
	#print("Shot Hit")
	#print("Shot Flags: ", team_set, " Target Flags: ", body.team_set)
	if( body.has_method("take_damage") ):
		body.take_damage(damage, source)

