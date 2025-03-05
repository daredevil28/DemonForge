extends Window

@onready var text_node : RichTextLabel = $ColorRect/TipText

func _ready() -> void:
	var text_file : FileAccess = FileAccess.open("res://Assets/tips.txt",FileAccess.READ)
	var text_array : PackedStringArray
	
	while text_file.get_position() < text_file.get_length():
		text_array.append(text_file.get_line())
	
	var text : String = text_array[randi_range(0,text_array.size() - 1)]
	print(text.split("\\n"))
	for new_text in text.split("\\n"):
		text_node.append_text(new_text + "\n")
	
	# Fit the window to the text size
	size = Vector2i(text_node.get_content_width(),text_node.get_content_height())
	# Center the window in the middle of the screen
	position = Vector2i(get_tree().root.size.x / 2 - size.x / 2,get_tree().root.size.y / 2 - size.y / 2)
	print(get_tree().root.size)


func _on_tip_text_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
