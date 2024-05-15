extends Node

var audio_player : AudioStreamPlayer

var game_scene_node : Node2D

var song_name : String = ""
var artist_name : String = ""
var difficulty : int = 0
var map : int = 0
var custom_songs_folder : String = ""
var bpm : float = 60.0
var snapping_frequency : int = 4
var is_another_window_focused : bool = false #ui_controller.gd -> check_for_window_focused()

var current_hovered_note : Note
var current_selected_note : Note

var cursor_note : Node2D #cursor_note.gd -> _ready()
var current_lane : int

#region Getter/Setters
var scroll_speed : int = 50 :
	set(value):
		scroll_speed = value
		redraw_scene()
		current_pos = current_pos
		
#Set up audiostreamplayer as soon as it's set
var song_file : String = "" :
	set(value):
		if value != song_file:
			song_file = value
			setup_audio(value)

#Return length of audio, if audio empty return default value
var audio_length : float = 60 :
	get:
		if(audio_player.stream != null):
			return audio_player.stream.get_length()
		else:
			return audio_length
	set(value):
		if(audio_player.stream == null):
			audio_length = value

#Automatically move the notes whenever we play the position
var current_pos : float = 0 :
	set(value):
		current_pos = value
		NoteManager.play_notes(current_pos)
#endregion

func _ready() -> void:
	#Default custom song location
	if(OS.get_name() == "Windows"):
		custom_songs_folder = OS.get_data_dir().rstrip("Roaming") + "LocalLow/Garage 51/Drums Rock/CustomSongs"
	
#region Project setup
#Setup metadata, audio and all the notes
func setup_project(jsonString : Dictionary) -> void:
	var metadata : Dictionary = jsonString["metaData"][0]
	song_name = metadata["songName"]
	artist_name = metadata["artistName"]
	difficulty = metadata["difficulty"]
	map = metadata["map"]
	song_file = metadata["songFile"]
	bpm = metadata["bpm"]

	NoteManager.initialise_notes(jsonString["notes"])
	current_pos = 0

func setup_audio(audio_file : String) -> void:
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
	custom_songs_folder = ""
	bpm = 60.0

	current_pos = 0
#endregion

func play_music() -> void:
	audio_player.play(current_pos)

func stop_music() -> void:
	current_pos = audio_player.get_playback_position()
	audio_player.stop()

func redraw_scene() -> void:
	game_scene_node.queue_redraw()
	
#region Music time related functions
#Get the location of the note based on how long the song is and the width of the window
func music_time_to_screen_time(time : float) -> float:
	var percentage_elapsed : float = 0.0
	if time > 0:
		percentage_elapsed = time / audio_length

	return percentage_elapsed * DisplayServer.window_get_size().x * GameManager.scroll_speed

#Like previous function but in reverse
func screen_time_to_music_time(location : float) -> float:
	return location / DisplayServer.window_get_size().x * audio_length / GameManager.scroll_speed

func get_closest_snap_value(original_pos : float) -> float:
	var seconds_per_beat : float = 60 / bpm / snapping_frequency
	var before_snap : float = floorf((original_pos-seconds_per_beat / snapping_frequency) / seconds_per_beat) * seconds_per_beat
	var ahead_snap : float = before_snap + seconds_per_beat
	
	if(abs(original_pos - ahead_snap) < abs(original_pos - before_snap)):
		return ahead_snap
	else:
		return before_snap

#Get the right music time and position
func mouse_snapped_screen_pos(pos : Vector2) -> Dictionary:
	var offset_pos : float = pos.x - NoteManager.offset
	var music_time : float = get_closest_snap_value(screen_time_to_music_time(offset_pos) + current_pos)
	var snapped_pos : float = GameManager.music_time_to_screen_time(music_time - current_pos) + NoteManager.offset
	return {"screen_pos": snapped_pos,"time_pos":music_time}
#endregion

func save_project(path : String) -> void:
	var json_data : Dictionary = {
		"metaData":
		[
			{
				"songName" : song_name,
				"artistName" : artist_name,
				"difficulty" : difficulty,
				"map" : map,
				"songFile" : song_file,
				"bpm" : bpm
			}
		],
		"notes" : 
		[
			
		]
	}
	var note_array : Array = []
	for i : Note in NoteManager.note_nodes:
		var individual_note : Dictionary = {
		"time" : i.time,	
		"color" : i.color,
		"interval" : i.interval
		}
		note_array.append(individual_note)
	json_data["notes"] = note_array
	var json_string : String = JSON.stringify(json_data, "\t")
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

func export_project(path : String) -> void:
	pass

func _process(_delta : float) -> void:
	if(audio_player.playing):
		current_pos = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		
	if current_lane == 0:
		cursor_note.visible = false
	else:
		cursor_note.visible = true
		cursor_note.position.y = NoteManager.reset_note_y(cursor_note, current_lane)
		var note_pos : Dictionary = mouse_snapped_screen_pos(get_viewport().get_mouse_position())
		cursor_note.position.x = note_pos["screen_pos"]
			
func _input(event : InputEvent) -> void:
	if(event is InputEventMouseButton):
		var seconds_per_beat : float = 60 / bpm
		if(current_lane != 0):
			var new_pos : Dictionary = mouse_snapped_screen_pos(get_viewport().get_mouse_position())
			var note_exists: bool = NoteManager.check_if_note_exists_at_mouse_location(new_pos["time_pos"], current_lane)
			if(event.is_action_pressed("LeftClick")):
				if(!note_exists):
					NoteManager.add_new_note(new_pos["time_pos"], current_lane)
			if(event.is_action_pressed("RightClick")):
				if(current_hovered_note != null):
					NoteManager.remove_note_at_time(current_hovered_note.time, current_hovered_note.color)
					current_hovered_note = null

		if(event.is_action_pressed("ScrollUp") && !audio_player.playing && !is_another_window_focused):
			current_pos += seconds_per_beat / snapping_frequency
			current_pos = get_closest_snap_value(current_pos)
			if current_pos > audio_length:
				current_pos = audio_length

		if(event.is_action_pressed("ScrollDown") && !audio_player.playing && !is_another_window_focused):
			current_pos -= seconds_per_beat / snapping_frequency
			current_pos = get_closest_snap_value(current_pos)
			if current_pos < 0:
				current_pos = 0

	if(event.is_action_pressed("TogglePlay") && is_another_window_focused == false):
		if(audio_player.playing):
			stop_music()
			current_pos = get_closest_snap_value(current_pos)
		else:
			if(audio_player.stream != null):
				for i : Note in NoteManager.note_nodes:
					if(i.time < current_pos):
						i.disable_collision()
						i.visible = false
					else:
						continue
				play_music()
