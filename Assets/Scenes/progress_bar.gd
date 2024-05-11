extends ProgressBar

func _process(delta):
	value = GameManager.current_pos / GameManager.audio_length * 100
