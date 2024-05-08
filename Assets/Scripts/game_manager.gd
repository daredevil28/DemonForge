extends Node

@onready var audio_player : AudioStreamPlayer = $"../SongAudio"

var song_name : String = ""
var artist_name : String = ""
var difficulty : int = 0
var map : int = 0
var song_file : String = "" :
	get:
		return song_file
	set(value):
		song_file = value
		setup_audio(value)
var preview_file : String = ""
var custom_songs_folder : String = ""
var bpm : float = 60.0

var current_pos : float = 0
var previous_pos : float = 0

@onready var note_manager : Node = %NoteManager

var scroll_speed : int = 50

#_audio_player.has_stream_playback() doesn't return true if called on the same frame that the stream gets set so we have to track it myself
var audio_stream_set : bool = false

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
	preview_file = metadata["previewFile"]
	bpm = metadata["bpm"]

	note_manager.initialise_notes(jsonString["notes"])
	note_manager.play_notes(0.0)
	current_pos = 0
	
func play_music() -> void:
	audio_player.play(current_pos)

func stop_music() -> void:
	current_pos = audio_player.get_playback_position()
	audio_player.stop()
	
	#Get the location of the note based on how long the song is and the width of the window
func music_time_to_screen_time(time : float) -> float:
	var percentage_elapsed : float = 0.0
	var songLength : float
	
	#Check if the audio is set, and else use the last note in the array to determine song length
	if audio_stream_set:
		songLength = audio_player.stream.get_length()
	else:
		#Song length could be temporary "wrong", this should be fine even if the final note in the array is not the latest note
		songLength = note_manager.note_nodes.back().time
		
	if time > 0:
		percentage_elapsed = time / songLength
	else:
		percentage_elapsed = 0
	
	return percentage_elapsed * DisplayServer.window_get_size().x
	
func setup_audio(audio_file : String) -> void:
	if audio_file == "":
		audio_player.stream = null
		audio_stream_set = false
	else:
		audio_player.stream = AudioStreamOggVorbis.load_from_file(song_file)
		audio_stream_set = true
	
func clean_project() -> void:
	setup_audio("")
	note_manager.clear_all_notes()
	song_name = ""
	artist_name = ""
	difficulty = 0
	map = 0
	song_file = ""
	preview_file = ""
	custom_songs_folder = ""
	bpm = 60.0

	current_pos = 0
	
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
				"previewFile" : preview_file,
				"bpm" : bpm
			}
		],
		"notes" : 
		[
			
		]
	}
	var note_array : Array = []
	for i : Node2D in note_manager.note_nodes:
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

func _process(_delta : float) -> void:
	if(audio_player.playing):
		current_pos = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		if (current_pos > previous_pos):
			previous_pos = current_pos
		note_manager.play_notes(current_pos)
	
	if(Input.is_action_just_pressed("TogglePlay")):
		if(audio_player.playing):
			stop_music()
		else:
			play_music()
			
	if(Input.is_action_just_pressed("ScrollUp")):
		if current_pos < audio_player.stream.get_length():
			current_pos += 0.25
			note_manager.play_notes(current_pos)
	if(Input.is_action_just_pressed("ScrollDown")):
		if current_pos < 0:
			current_pos = 0
		else:
			current_pos -= 0.25
		note_manager.play_notes(current_pos)

