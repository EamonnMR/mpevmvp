extends Node2D

func _ready():
	if (name == str(Client.client_id)):
		$Camera2D.make_current()

