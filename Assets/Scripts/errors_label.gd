extends Label


func _ready() -> void:
	GameManager.errors_found.connect(set_error_text)
	
func set_error_text(errors : String) -> void:
	text = errors
