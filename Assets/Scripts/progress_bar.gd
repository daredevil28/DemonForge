extends ProgressBar

func _process(_delta : float) -> void:
	value = GameManager.current_pos / GameManager.audio_length * 100
