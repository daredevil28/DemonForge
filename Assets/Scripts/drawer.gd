extends Node2D
## Draws the judgement line and the individual beats


var default_font : Font = ThemeDB.fallback_font
var default_font_size : int = ThemeDB.fallback_font_size

var previous_line_count : int

func _init() -> void:
	Global.game_scene_node = self


func _draw() -> void:
	var current_line : int = 0
	var line_color : Color = Color.WHITE

	# Beat markers
	# Loop for each marker
	for x : int in range(0,NoteManager.marker_nodes.size()):
		var length : float
		
		# Draw the markers up until the next marker or until song end
		if(x+1 < NoteManager.marker_nodes.size()):
			length = NoteManager.marker_nodes[x+1].time - NoteManager.marker_nodes[x].time
		else:
			length = GameManager.audio_length - NoteManager.marker_nodes[x].time
		
		var seconds_per_beat : float = 60 / NoteManager.marker_nodes[x].bpm / NoteManager.marker_nodes[x].snapping
		
		# Use the position of the marker as the first line
		var new_time : float = NoteManager.marker_nodes[x].time
		
		# Draw the beat lines
		for i : int in range(0,snapped(length / seconds_per_beat, 0)):
			var marker_distance : float = (-GameManager.music_time_to_screen_time(GameManager.current_pos) + GameManager.music_time_to_screen_time(new_time)) + NoteManager.offset
			
			# If the beat line would go outside of the screen on the right then stop the loop
			if(marker_distance > DisplayServer.window_get_size().x):
				break
				
			# If the beat line would go outside of the screen on the left then skip this iteration
			if(marker_distance < 0):
				if(i % (NoteManager.marker_nodes[x].snapping * NoteManager.marker_nodes[x].snapping) == 0):
					current_line += 1
				new_time = new_time + seconds_per_beat
				continue
				
			var line_thickness : int = 2
			# Top and bottom position of the line
			var top_point : float = 0.30 * DisplayServer.window_get_size().y
			var bottom_point : float = 0.70 * DisplayServer.window_get_size().y
			
			# Any time the metronome reaches a new measure then make the line thick
			if(i % (NoteManager.marker_nodes[x].snapping * NoteManager.marker_nodes[x].snapping) == 0):
				line_color = Color.WHITE
				top_point = 0.25 * DisplayServer.window_get_size().y
				bottom_point = 0.75 * DisplayServer.window_get_size().y
				draw_string(default_font,Vector2(marker_distance + -5,top_point + -20),str(current_line),HORIZONTAL_ALIGNMENT_CENTER,-1,default_font_size + 8)
				current_line += 1
				
			elif(i % NoteManager.marker_nodes[x].snapping == 0):
				line_color = Color.ANTIQUE_WHITE
				top_point = 0.275 * DisplayServer.window_get_size().y
				bottom_point = 0.725 * DisplayServer.window_get_size().y
				
			else:
				line_color = Color.GRAY
				line_thickness = 1
				
			# Draw the line itself
			draw_line(Vector2(marker_distance,top_point),Vector2(marker_distance,bottom_point),line_color,line_thickness)
			
			new_time = new_time + seconds_per_beat
