extends Node2D

var lineColor : Color = Color.WHITE

func _ready() -> void:
	GameManager.game_scene_node = self
	
func _draw() -> void:
	#The judgement line
	draw_line(Vector2(NoteManager.offset, 0), Vector2(NoteManager.offset,DisplayServer.window_get_size().y), lineColor, 2)
	var seconds_per_beat : float = 60 / GameManager.bpm
	var new_time : float = seconds_per_beat
	for i : int in range(0,snapped(GameManager.audio_length / seconds_per_beat, 0)):
		var marker_distance : float = (-GameManager.music_time_to_screen_time(GameManager.current_pos) + GameManager.music_time_to_screen_time(new_time)) + NoteManager.offset
		draw_line(Vector2(marker_distance,0.25 * DisplayServer.window_get_size().y),Vector2(marker_distance,0.75 * DisplayServer.window_get_size().y),lineColor,1)
		new_time = new_time + seconds_per_beat
