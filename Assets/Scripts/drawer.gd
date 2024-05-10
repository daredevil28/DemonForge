extends Node2D

var lineColor : Color = Color.WHITE
@onready var manager : Node = %GameManager
@onready var note_manager : Node = %NoteManager
func _draw() -> void:
	#The judgement line
	draw_line(Vector2(%NoteManager.offset, 0), Vector2(%NoteManager.offset,DisplayServer.window_get_size().y), lineColor, 2)
	var bps = 60 / manager.bpm
	var new_time = bps
	for i in range(0,500):
		var marker_distance = (-manager.music_time_to_screen_time(manager.current_pos) + manager.music_time_to_screen_time(new_time)) * manager.scroll_speed + note_manager.offset
		draw_line(Vector2(marker_distance,DisplayServer.window_get_size().y / 1.4),Vector2(marker_distance,DisplayServer.window_get_size().y / 2.6),lineColor,1)
		new_time = new_time + bps
