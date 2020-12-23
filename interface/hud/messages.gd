extends Label

func display(text):
	self.text = text
	$NotificationSound.play()
	$Timer.start()

func _on_Timer_timeout():
	text = ""
