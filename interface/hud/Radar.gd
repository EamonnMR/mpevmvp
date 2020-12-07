extends NinePatchRect

func add_radar_pip(subject):
	var pip = preload("res://interface/hud/radar_pip.tscn").instance()
	pip.subject = subject
	$Panel.add_child(pip)
