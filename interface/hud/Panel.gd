extends Panel

var style = StyleBoxFlat.new()

var pips = Dictionary()

func _ready():
	# The Panel doc tells you which style names there are
	style.set_bg_color(Color(0,0,0))
	add_stylebox_override("panel", style)
