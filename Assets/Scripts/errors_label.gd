extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.errors_found.connect(set_error_text)
	
func set_error_text(errors : String) -> void:
	text = errors
