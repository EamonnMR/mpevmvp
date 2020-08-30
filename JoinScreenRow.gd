extends HBoxContainer

var game = null

signal join_game_pressed(game)

func apply_game(new_game):
	game = new_game
	$Label.text = game["name"]

func _on_Join_pressed():
	emit_signal("join_game_pressed", game)
