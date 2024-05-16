extends Node2D

func _ready() -> void:
	GameManager.game_scene_node = self
	
func _draw() -> void:
	#The judgement line
	var line_color : Color = Color.WHITE
	draw_line(Vector2(NoteManager.offset, 0), Vector2(NoteManager.offset,DisplayServer.window_get_size().y), line_color, 4)
	for i in range(1,7):
		draw_line(Vector2(0,NoteManager.get_note_lane_y(i)),Vector2(DisplayServer.window_get_size().x,NoteManager.get_note_lane_y(i)),line_color,1)
	var seconds_per_beat : float = 60 / GameManager.bpm / GameManager.snapping_frequency
	var new_time : float
	for i : int in range(0,snapped(GameManager.audio_length / seconds_per_beat, 0)):
		var marker_distance : float = (-GameManager.music_time_to_screen_time(GameManager.current_pos) + GameManager.music_time_to_screen_time(new_time)) + NoteManager.offset
		if (marker_distance > DisplayServer.window_get_size().x):
			break
		var line_thickness : int = 1
		var top_point : float = 0.25 * DisplayServer.window_get_size().y
		var bottom_point : float = 0.75 * DisplayServer.window_get_size().y
		if(i % GameManager.snapping_frequency):
			line_color = Color.GRAY
			top_point = 0.30 * DisplayServer.window_get_size().y
			bottom_point = 0.70 * DisplayServer.window_get_size().y
		else:
			line_color = Color.ANTIQUE_WHITE
			line_thickness = 2
		draw_line(Vector2(marker_distance,top_point),Vector2(marker_distance,bottom_point),line_color,line_thickness)
		new_time = new_time + seconds_per_beat
