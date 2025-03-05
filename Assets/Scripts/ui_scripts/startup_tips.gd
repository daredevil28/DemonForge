extends Window

@onready var text_node : RichTextLabel = find_child("TipText")
@onready var current_tip_text : Label = find_child("CurrentTipText")
var text_array : PackedStringArray
var current_tip : int


func _ready() -> void:
	var text_file : FileAccess = FileAccess.open("res://Assets/tips.txt",FileAccess.READ)
	
	while text_file.get_position() < text_file.get_length():
		text_array.append(text_file.get_line())
	
	current_tip = randi_range(0,text_array.size() - 1)
	_set_text(current_tip)
	

func _set_text(text_id : int) -> void:
	text_node.text = ""
	text_node.text = "[font_size=22]"
	for new_text in text_array[text_id].split("\\n"):
		text_node.append_text(new_text + "\n")
	
	current_tip_text.text = str(text_id + 1) + "/" + str(text_array.size())
	# Fit the window to the text size
	size = Vector2i(text_node.get_content_width(),text_node.get_content_height() + 50)
	# Center the window in the middle of the screen
	position = Vector2i(get_tree().root.size.x / 2 - size.x / 2,get_tree().root.size.y / 2 - size.y / 2)


func _on_tip_text_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)


func _on_next_tip_pressed() -> void:
	if(current_tip == text_array.size() - 1):
		current_tip = 0
	else:
		current_tip += 1
	_set_text(current_tip)


func _on_prev_tip_pressed() -> void:
	if(current_tip == 0):
		current_tip = text_array.size() - 1
	else:
		current_tip -= 1
	_set_text(current_tip)


func _on_close_requested() -> void:
	visible = false
