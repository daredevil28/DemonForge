extends Node2D

var lineColor : Color = Color.WHITE
@onready var manager : Node = %GameManager
@onready var note_manager : Node = %NoteManager
func _draw() -> void:
	#The judgement line
	draw_line(Vector2(note_manager.offset, 0), Vector2(note_manager.offset,DisplayServer.window_get_size().y), lineColor, 2)
	var seconds_per_beat : float = 60 / manager.bpm
	var new_time : float = seconds_per_beat
	for i : int in range(0,500):
		var marker_distance : float = (-manager.music_time_to_screen_time(manager.current_pos) + manager.music_time_to_screen_time(new_time)) * manager.scroll_speed + note_manager.offset
		draw_line(Vector2(marker_distance,DisplayServer.window_get_size().y / 1.4),Vector2(marker_distance,DisplayServer.window_get_size().y / 2.6),lineColor,1)
		new_time = new_time + seconds_per_beat
