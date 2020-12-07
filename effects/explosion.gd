extends AnimatedSprite

var sfx_finished = false
var gfx_finished = false

func _on_animation_finished():
	hide()
	gfx_finished = true
	cleanup_if_done()

func cleanup_if_done():
	if sfx_finished and gfx_finished:
		queue_free()
	
func _on_sfx_finished():
	sfx_finished = true
	$sfx.queue_free()
	cleanup_if_done()
