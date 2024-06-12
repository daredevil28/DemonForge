extends Label
## Sets the text [Label] in the export panel


func _ready() -> void:
	Global.file_manager.errors_found.connect(set_error_text)


## Sets the [Label] text
func set_error_text(errors : String) -> void:
	text = errors
