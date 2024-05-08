extends Node2D

var lineColor : Color = Color.WHITE

func _draw() -> void:
	#The judgement line
	draw_line(Vector2(%NoteManager.offset, 0), Vector2(%NoteManager.offset,DisplayServer.window_get_size().y), lineColor, 2)
