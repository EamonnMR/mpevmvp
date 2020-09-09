extends Node

var lobby
var players = {}
var client
var server
var client_id
var player_name

func _ready():
	var args = OS.get_cmdline_args()
	var kwargs = parse_args({
		"server-name": "Just Another EV MP",
		"max_players": "6"
	})
	if OS.has_feature("Server") or "--server" in args:
		Server.start(kwargs["server-name"], int(kwargs["max_players"]))
	else:
		# TODO: Show Menu
		pass

func parse_args(kwargs):
	# Takes a dict of default args and values,
	# mutates it according to what is passed with 
	# --command line arguments
	var args = Array(OS.get_cmdline_args())
	for arg in kwargs:
		var index = args.find("--" + arg)
		if index >= 0:
			kwargs[arg] = args[index + 1]
	return kwargs
