extends Label

func _process(delta: float) -> void:
	text = str(round(GameManager.current_pos))
