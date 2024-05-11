extends Node

var audio_player : AudioStreamPlayer

var game_scene_node : Node2D

var song_name : String = ""
var artist_name : String = ""
var difficulty : int = 0
var map : int = 0
var custom_songs_folder : String = ""
var bpm : float = 60.0

var is_another_window_focused : bool = false #ui_controller.gd -> check_for_window_focused()

var scroll_speed : int = 50 :
	set(value):
		scroll_speed = value
		redraw_scene()
		current_pos = current_pos
		
#Set up audiostreamplayer as soon as it's set
var song_file : String = "" :
	get:
		return song_file
	set(value):
		if value != song_file:
			song_file = value
			setup_audio(value)

#Return length of audio, if audio empty return default value
var audio_length : float :
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
	get:
		return current_pos
	set(value):
		current_pos = value
		NoteManager.play_notes(current_pos)

func _ready() -> void:
	#Default custom song location
	if(OS.get_name() == "Windows"):
		custom_songs_folder = OS.get_data_dir().rstrip("Roaming") + "LocalLow/Garage 51/Drums Rock/CustomSongs"

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
	
func play_music() -> void:
	audio_player.play(current_pos)

func stop_music() -> void:
	current_pos = audio_player.get_playback_position()
	audio_player.stop()
	
	for i : Node2D in NoteManager.note_nodes:
		i.visible = true
	
#Get the location of the note based on how long the song is and the width of the window
func music_time_to_screen_time(time : float) -> float:
	var percentage_elapsed : float = 0.0
		
	if time > 0:
		percentage_elapsed = time / audio_length
	else:
		percentage_elapsed = 0
	
	return percentage_elapsed * DisplayServer.window_get_size().x
	
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

func redraw_scene() -> void:
	game_scene_node.queue_redraw()

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
	for i : Node2D in NoteManager.note_nodes:
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

func get_closest_snap_value(original_pos : float) -> float:
	var seconds_per_beat : float = 60 / bpm
	var before_snap : float = floorf((original_pos-seconds_per_beat / 4) / seconds_per_beat) * seconds_per_beat
	var ahead_snap : float = before_snap + seconds_per_beat
	
	if(abs(original_pos - ahead_snap) < abs(original_pos - before_snap)):
		return ahead_snap
	else:
		return before_snap
	
func _process(_delta : float) -> void:
	if(audio_player.playing):
		current_pos = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	var seconds_per_beat : float = 60 / bpm
	if(Input.is_action_just_pressed("TogglePlay") && is_another_window_focused == false):
		if(audio_player.playing):
			stop_music()
			current_pos = get_closest_snap_value(current_pos)
		else:
			play_music()
	if(Input.is_action_just_pressed("ScrollUp") && !audio_player.playing && !is_another_window_focused):
		current_pos += seconds_per_beat
		current_pos = get_closest_snap_value(current_pos)
		if current_pos > audio_length:
			current_pos = audio_length
	if(Input.is_action_just_pressed("ScrollDown") && !audio_player.playing && !is_another_window_focused):
		current_pos -= seconds_per_beat
		current_pos = get_closest_snap_value(current_pos)
		if current_pos < 0:
			current_pos = 0
