extends Node2D

func _ready() -> void:
	Global.game_scene_node = self
	
func _draw() -> void:
	#The judgement line
	var line_color : Color = Color.WHITE
	draw_line(Vector2(NoteManager.offset, 0), Vector2(NoteManager.offset,DisplayServer.window_get_size().y), line_color, 4)
	#The note lines
	for i in range(1,7):
		draw_line(Vector2(0,NoteManager.get_note_lane_y(i)),Vector2(DisplayServer.window_get_size().x,NoteManager.get_note_lane_y(i)),line_color,1)
	#Beat markers
	#Loop for each marker
	for x in range(0,NoteManager.marker_nodes.size()):
		var length : float
		#Draw the markers up until the next marker or until song end
		if(x+1 < NoteManager.marker_nodes.size()):
			length = NoteManager.marker_nodes[x+1].time
		else:
			length = GameManager.audio_length
		var seconds_per_beat : float = 60 / NoteManager.marker_nodes[x].bpm / NoteManager.marker_nodes[x].snapping
		#Use the position of the marker as the first line
		var new_time : float = NoteManager.marker_nodes[x].time
		#Draw the beat lines
		for i : int in range(0,snapped(length / seconds_per_beat, 0)):
			var marker_distance : float = (-GameManager.music_time_to_screen_time(GameManager.current_pos) + GameManager.music_time_to_screen_time(new_time)) + NoteManager.offset
			#If the beat line would go outside of the screen on the right then stop the loop
			if (marker_distance > DisplayServer.window_get_size().x):
				break
			#If the beat line would go outside of the screen on the left then skip this iteration
			if(marker_distance < 0):
				new_time = new_time + seconds_per_beat
				continue
				
			var line_thickness : int = 1
			#Top and bottom position of the line
			var top_point : float = 0.25 * DisplayServer.window_get_size().y
			var bottom_point : float = 0.75 * DisplayServer.window_get_size().y
			#Any time the metronome reaches a new measure then make the line thick
			#TODO make it work better with other time signatures
			if(i % (GameManager.snapping_frequency * 2)):
				line_color = Color.GRAY
				top_point = 0.30 * DisplayServer.window_get_size().y
				bottom_point = 0.70 * DisplayServer.window_get_size().y
			else:
				line_color = Color.ANTIQUE_WHITE
				line_thickness = 2
			#Draw the line itself
			draw_line(Vector2(marker_distance,top_point),Vector2(marker_distance,bottom_point),line_color,line_thickness)
			new_time = new_time + seconds_per_beat
