extends SpinBox

# A remake of the editing_toggled signal on the lineEdit because you can't access the signals of it
signal editing_toggled(toggled_on: bool)


func _ready() -> void:
	get_line_edit().editing_toggled.connect(editing_toggled_func)
	
func editing_toggled_func(toggled_on : bool) -> void:
	editing_toggled.emit(toggled_on)
