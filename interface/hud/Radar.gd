extends NinePatchRect

func add_radar_pip(subject):
	print("Radar: Adding radar pip")
	var pip = preload("res://interface/hud/radar_pip.tscn").instance()
	pip.subject = subject
	$Panel.add_child(pip)
