#Singleton for managing everything related to the game
extends Node

#Audio player gets automatically set as soon as the audioplayer enters the scene tree
var audio_player : AudioStreamPlayer

#Audio file properties
var song_name : String = ""
var artist_name : String = ""
var difficulty : int = 0
var map : int = 0
var custom_songs_folder : String = ""
var project_file : String = ""
var folder_name : String = ""
var bpm : float = 60.0
var preview_file : String = ""
var snapping_frequency : int = 4

var is_another_window_focused : bool = false #ui_controller.gd -> check_for_window_focused()

#If any change has been made to the project then give warnings if it hasn't been saved yet
var project_changed : bool

var current_hovered_note
var current_selected_note
var current_lane : int

var cursor_note : Sprite2D #<- cursor_note.gd _ready()
var note_sprite : Resource = load("res://Assets/Sprites/Notes.png")
var marker_sprite : Resource = load("res://Assets/Sprites/BPMMarker.png")

signal errors_found(errors : String)
signal note_selected(note : Note)
signal note_deselected(note : Note)

#region Getter/Setters
var seconds_per_measure : float :
	get:
		return 60 / (bpm / snapping_frequency)

var seconds_per_beat : float :
	get:
		return seconds_per_measure / snapping_frequency
		
var current_beat : int :
	get:
		return current_pos / seconds_per_beat

var current_measure : int :
	get:
		return current_beat / 4

var scroll_speed : int = 50 :
	set(value):
		scroll_speed = value
		redraw_scene()
		current_pos = current_pos
		
var song_file : String = "" :
	#Set up audiostreamplayer as soon as it's set
	set(value):
		if value != song_file:
			song_file = value
			setup_audio(value)

var audio_length : float = 60 :
	#Return length of audio, if audio empty return default value
	get:
		if(audio_player.stream != null):
			return audio_player.stream.get_length()
		else:
			return audio_length

var current_pos : float = 0 :
	#Automatically move the notes whenever we play the position
	set(value):
		current_pos = value
		for marker : Marker in NoteManager.marker_nodes:
			if(marker.time <= value):
				bpm = marker.bpm
				snapping_frequency = marker.snapping
			NoteManager.play_notes(marker, current_pos)
		for note : Note in NoteManager.note_nodes:
			NoteManager.play_notes(note, current_pos)
#endregion

func _ready() -> void:
	#Default custom song location
	if(OS.get_name() == "Windows"):
		custom_songs_folder = OS.get_data_dir().rstrip("Roaming") + "LocalLow/Garage 51/Drums Rock/CustomSongs"
	
#region Project setup
func setup_project(jsonString : Dictionary) -> void:
	#Setup metadata, audio and all the notes
	var metadata : Dictionary = jsonString["metaData"][0]
	song_name = metadata["songName"]
	artist_name = metadata["artistName"]
	difficulty = metadata["difficulty"]
	map = metadata["map"]
	song_file = metadata["songFile"]
	preview_file = metadata["previewFile"]
	folder_name = metadata["folderName"]
	
	NoteManager.clear_all_notes()
	
	NoteManager.initialise_marker(jsonString["marker"])
	NoteManager.initialise_notes(jsonString["notes"])
	current_pos = 0

func setup_audio(audio_file : String) -> void:
	#Remove the audio if the song file is blank
	if audio_file == "":
		audio_player.stream = null
	else:
		audio_player.stream = AudioStreamOggVorbis.load_from_file(song_file)
		current_pos = 0

func clean_project() -> void:
	setup_audio("")
	NoteManager.clear_all_notes()
	song_name = ""
	artist_name = ""
	difficulty = 0
	map = 0
	song_file = ""
	preview_file = ""
	bpm = 60.0

	current_pos = 0
	NoteManager.add_new_note(0,7)
	Global.notification_popup.play_notification("Project has been reset!", 0.5)
#endregion

func play_music() -> void:
	audio_player.play(current_pos)
	Global.notification_popup.play_notification("Music playing", 0.5)

func stop_music() -> void:
	current_pos = audio_player.get_playback_position()
	audio_player.stop()
	Global.notification_popup.play_notification("Music stopped", 0.5)

func redraw_scene() -> void:
	Global.game_scene_node.queue_redraw()
	
#region Music time related functions
func music_time_to_screen_time(time : float) -> float:
	#Get the location of the note based on how long the song is and the width of the window
	var percentage_elapsed : float = 0.0
	if time > 0:
		percentage_elapsed = time / audio_length

	return percentage_elapsed * DisplayServer.window_get_size().x * GameManager.scroll_speed

func screen_time_to_music_time(location : float) -> float:
	#Like previous function but in reverse
	return location / DisplayServer.window_get_size().x * audio_length / GameManager.scroll_speed

func get_closest_snap_value(music_pos : float) -> float:
	var start_time : float = 0
	if(NoteManager.marker_nodes.size() != 0):
		var bpm : int
		var snapping_frequency : int
		for marker : Marker in NoteManager.marker_nodes:
				if(marker.time <= music_pos):
					start_time = marker.time
					bpm = marker.bpm
					snapping_frequency = marker.snapping
	#Gets the closest bar by comparing the snap backwards with the snap forwards and see which is closer
	var beat_duration : float = 60 / bpm / snapping_frequency
	var relative_pos : float = music_pos - start_time
	var closest_beat : int = round(relative_pos / beat_duration)
	var before_snap : float = start_time + closest_beat * beat_duration
	var ahead_snap : float = before_snap + seconds_per_beat
	
	if(abs(music_pos - ahead_snap) < abs(music_pos - before_snap)):
		return ahead_snap
	else:
		return before_snap

func mouse_snapped_screen_pos(pos : Vector2) -> Dictionary:
	#Get the right music time and position based on screen position
	var offset_pos : float = pos.x - NoteManager.offset
	var music_time : float = get_closest_snap_value(screen_time_to_music_time(offset_pos) + current_pos)
	var snapped_pos : float = GameManager.music_time_to_screen_time(music_time - current_pos) + NoteManager.offset
	return {"screen_pos": snapped_pos,"time_pos":music_time}
#endregion

#region Files and saving related
func save_project(path : String) -> void:
	#Save project into a .json file
	#Set up general json file as a dictionary
	var json_data : Dictionary = {
		"metaData":
		[
			{
				"songName" : song_name,
				"artistName" : artist_name,
				"difficulty" : difficulty,
				"map" : map,
				"songFile" : song_file,
				"previewFile" : preview_file,
				"folderName" : folder_name
			}
		],
		"marker" : [
			
		],
		"notes" : 
		[
			
		]
	}
	#Make a new array with the notes
	var note_array : Array = []
	for i : Note in NoteManager.note_nodes:
		var individual_note : Dictionary = {
		"time" : i.time,
		"color" : i.color,
		"interval" : i.interval
		}
		note_array.append(individual_note)
	#Make a new array with the markers
	var marker_array : Array = []
	for i : Marker in NoteManager.marker_nodes:
		var individual_marker : Dictionary = {
			"time" : i.time,
			"bpm" : i.bpm,
			"snapping" : i.snapping
		}
		marker_array.append(individual_marker)
	#Add both to the dictionary
	json_data["notes"] = note_array
	json_data["marker"] = marker_array
	
	var json_string : String = JSON.stringify(json_data, "\t",false)
	#Check if path has .json at the end, else add it
	var regex : RegEx = RegEx.new()
	regex.compile("\\.(json)")
	var result : RegExMatch = regex.search(path)
	
	var file : FileAccess
	if(result.get_string() == ".json"):
		file = FileAccess.open(path, FileAccess.WRITE)
	else:
		file = FileAccess.open(path + ".json", FileAccess.WRITE)
	
	file.store_string(json_string)
	file.close()
	project_changed = false
	Global.notification_popup.play_notification("Project has been saved to: " + path, 2)

func check_for_errors() -> String:
	#Check for errors before exporting the project
	var errors : String = ""
	if(song_name == ""):
		errors += "No song name set\n"
	if(artist_name == ""):
		errors += "Artist name not set\n"
	if(song_file == ""):
		errors += "No song file specified\n"
	if(preview_file == ""):
		errors += "No preview file specified\n"
	if(folder_name == ""):
		errors += "Folder name not specified\n"
	if(custom_songs_folder == ""):
		errors += "Custom songs folder not set\n"
	return errors

func export_project() -> void:
	#Export the project to the custom songs folder
	print("Exporting project")
	#Check for errors and don't continue if any is found
	var errors : String = check_for_errors()
	if(errors != ""):
		errors_found.emit(errors)
	else:
		errors_found.emit(errors)
		#Set the path to the custom songs folder + the exported folder name
		var path : String = custom_songs_folder + folder_name
		print(path)
		if(DirAccess.dir_exists_absolute(path)):
			print("Path exists")
		else:
			print("Path don't exist")
			DirAccess.make_dir_absolute(path)
		var dir : DirAccess = DirAccess.open(path)
		#Copy audio files to the folder
		print(dir.copy(song_file,path + "/song.ogg"))
		print(dir.copy(preview_file, path + "./preview.ogg"))
		
		#Making info.csv file
		var info : FileAccess = FileAccess.open(path + "/info.csv",FileAccess.WRITE)
		info.store_csv_line(PackedStringArray(["Song Name","Author Name","Difficulty","Song Duration in seconds","Song Map"]))
		info.store_csv_line(PackedStringArray([song_name,artist_name,str(difficulty),roundi(audio_length),str(map)]))
		info.close()
		
		NoteManager.sort_all_notes()
		
		#Write the first line
		var notes : FileAccess = FileAccess.open(path + "/notes.csv",FileAccess.WRITE)
		notes.store_line("Time [s],Enemy Type,Aux Color 1,Aux Color 2,Nº Enemies,interval,Aux")
		var double_note : bool
		#Everything below here is adapted from https://github.com/daredevil28/drumsrockmidiparser/blob/main/drumsrockparser.py#L76
		for i : int in NoteManager.note_nodes.size():
			var note : Note = NoteManager.note_nodes[i]
			#If the previous was a double note then skip this iteration
			if(double_note):
				double_note = false
				continue
			
			var note_time : String
			var enemy_type : String = "1"
			var color_1 : String
			var color_2 : String
			var interval : String = ""
			var aux : String
			
			#if interval is not 0 then it's a drumroll
			if(note.interval != 0):
				enemy_type = "3"
				interval = str(note.interval)
			
			#If this note and the next one have the exact same time then it's a double note
			if(i+1 < NoteManager.note_nodes.size()):
				if(note.time == NoteManager.note_nodes[i+1].time):
					double_note = true
					enemy_type = "2"
					color_2 = str(NoteManager.note_nodes[i+1].color)
			
			note_time = str(note.time)
			color_1 = str(note.color)
			
			if(!double_note):
				color_2 = color_1
			
			if(int(color_2) < int(color_1)):
				var temp : String = color_1
				color_1 = color_2
				color_2 = temp

			match color_1:
				"2":
					aux = "7"
				"1":
					aux = "6"
				"5":
					aux = "5"
				"3":
					aux = "5"
				"6":
					aux = "8"
				"4":
					aux = "8"

			notes.store_csv_line(PackedStringArray([note_time,enemy_type,color_1,color_2,"1",interval,aux]))
		notes.close()
		Global.notification_popup.play_notification("Project succesfully exported to: " + path, 1)
#endregion

func _process(_delta : float) -> void:
	if(audio_player.playing):
		current_pos = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	
	if current_lane == 0 || is_another_window_focused || current_hovered_note != null:
		cursor_note.visible = false
	else:
		cursor_note.position.y = NoteManager.reset_note_y(cursor_note, current_lane)
		
		if(current_lane == 7):
			cursor_note.texture = marker_sprite
		else:
			cursor_note.texture = note_sprite
			
		#Get the proper position of the cursor note
		var note_pos : Dictionary = mouse_snapped_screen_pos(get_viewport().get_mouse_position())
		#If a double note does not exist at position or we are on the marker lane
		if(current_lane == 7 || !NoteManager.check_if_double_note_exists_at_time(note_pos["time_pos"])):
			cursor_note.visible = true
			cursor_note.position.x = note_pos["screen_pos"]

func _input(event : InputEvent) -> void:
	if(event is InputEventMouseButton):
		#TODO replace with the proper seconds_per_beat
		var seconds_per_beat : float = 60 / bpm
		
		#If we are in any of the note lanes
		if(current_lane != 0):
			
			#Get snapped pos and time
			var new_pos : Dictionary = mouse_snapped_screen_pos(get_viewport().get_mouse_position())
			
			#Check if note or marker already exists
			var note_exists: bool = NoteManager.check_if_note_exists_at_mouse_location(new_pos["time_pos"], current_lane)
			if(!is_another_window_focused):
				if(event.is_action_pressed("LeftClick")):
					
					#Check if note exists
					if(!note_exists):
						
						#Check if double note exists
						if(current_lane != 7):
							if(!NoteManager.check_if_double_note_exists_at_time(new_pos["time_pos"])):
								NoteManager.add_new_note(new_pos["time_pos"], current_lane)
						else:
							NoteManager.add_new_note(new_pos["time_pos"], current_lane)
								
					#If we are hovering over a note then set the note as the selected note
					if(current_hovered_note != null):
						current_selected_note = current_hovered_note
						note_selected.emit(current_selected_note)
						
				if(event.is_action_pressed("RightClick")):
					
					#Unselect the selected note
					if(current_selected_note != null):
						note_deselected.emit(current_selected_note)
						current_selected_note = null
						
					#Remove the note if we are hovering over a note
					if(current_hovered_note != null):
						NoteManager.remove_note_at_time(current_hovered_note.time, current_hovered_note.color)
						current_hovered_note = null
					
		#Scroll up 1 tick
		if(event.is_action_pressed("ScrollUp") && !audio_player.playing && !is_another_window_focused):
			current_pos += seconds_per_beat / snapping_frequency
			current_pos = get_closest_snap_value(current_pos)
			if current_pos > audio_length:
				current_pos = audio_length
				
		#Scroll down 1 tick
		if(event.is_action_pressed("ScrollDown") && !audio_player.playing && !is_another_window_focused):
			
			#Check if we are on a marker, use the previous marker for the seconds_per_beat if we are
			for i : int in range(0,NoteManager.marker_nodes.size()):
				if(NoteManager.marker_nodes[i].time == current_pos):
					seconds_per_beat = 60 / NoteManager.marker_nodes[i-1].bpm
					break
			
			current_pos -= seconds_per_beat / snapping_frequency
			current_pos = get_closest_snap_value(current_pos)
			if current_pos < 0:
				current_pos = 0

	if(event.is_action_pressed("TogglePlay") && is_another_window_focused == false):
		
		#If we are playing, then stop the music and snap to the nearest beat
		if(audio_player.playing):
			stop_music()
			current_pos = get_closest_snap_value(current_pos)
		else:
			#Hide all the notes that are behind the judgement line if we are going to play
			if(audio_player.stream != null):
				
				for i : Note in NoteManager.note_nodes:
					if(i.time < current_pos):
						i.disable_collision()
						i.visible = false
					else:
						continue
				play_music()

func _notification(what: int) -> void:
	#Warn before exiting the program if we have not saved
	if(what == NOTIFICATION_WM_CLOSE_REQUEST):
		if(project_changed):
			Global.popup_dialog.play_dialog("Project not saved!","The current project has not been saved, are you sure you want to exit?",get_tree().quit)
		else:
			get_tree().quit()
