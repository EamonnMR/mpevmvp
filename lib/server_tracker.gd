extends Node
const TRACKER = "tracker.eamonnmr.com"
const GAMETYPE = "mp_ev_mvp"
const DEFAULT_PORT = 26000

signal post_completed()
signal get_completed(games)

var game_name = null

func register_game(gname):
	game_name = gname

	# TODO: Stick this right into world.tscn and show/hide it?
	var timer = Timer.new()
	timer.connect("timeout", self, "_post_to_tracker")
	add_child(timer)
	timer.set_wait_time(5)
	timer.start()
	
func _post_to_tracker():
	# Put a game up on the server tracker
	# See: https://github.com/eamonnmr/server-tracker
	var query = JSON.print({
		"port": DEFAULT_PORT,
		"name": game_name),
		"type": GAMETYPE
	})
	
	var headers = ["Content-Type: application/json"]
	var http_request = HTTPRequest.new()
	add_child(http_request)
	# TODO: Care that the game was registered
	http_request.connect("request_completed", self, "_post_completed")
	http_request.request("http://" + TRACKER + "/game", headers, false, HTTPClient.METHOD_PUT, query)

func _post_completed(result, response_code, headers, body):
	# If this never comes back, maybe throw up a "can't connect" message
	self.emit_signal("post_completed")

func get_game_list():
	# This merely kicks off a request; you need to connect to "get completed"
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_get_completed")
	http_request.request("http://" + TRACKER + "/games?type=" + GAMETYPE, [], false, HTTPClient.METHOD_GET, "")

func _get_completed(result, response_code, headers, body):
	# Connect to this signal to add a callback to populate a games list, etc
	var games = JSON.parse(body.get_string_from_utf8())
	self.emit_signal("get_completed", games.result)
