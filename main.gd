extends Node

const DEFAULT_SERVER_NAME = "Server Name"

var lobby
var players = {}
var client
var server
var client_id
var player_name

const MAX_PLAYERS = 6

func _ready():
	var args = OS.get_cmdline_args()
	if(OS.has_feature("Server") or "server" in args):
		Server.start(DEFAULT_SERVER_NAME, 1)
	else:
		# TODO: Show Menu
		pass
