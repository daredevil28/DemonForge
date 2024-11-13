extends Node2D

func _ready() -> void:
	queue_redraw()
	get_tree().get_root().size_changed.connect(queue_redraw)
	NoteManager.offset_changed.connect(queue_redraw)
	
func _draw() -> void:
	# The judgement line
	var line_color : Color = Color.WHITE
	draw_line(Vector2(NoteManager.offset, 0), Vector2(NoteManager.offset,DisplayServer.window_get_size().y), line_color, 4)
	
	# The note lines
	for i : int in range(1,7):
		draw_line(Vector2(0,NoteManager.get_note_lane_y(i)),Vector2(DisplayServer.window_get_size().x,NoteManager.get_note_lane_y(i)),line_color,1)
