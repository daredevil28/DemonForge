class_name FileManager
extends Node
## Manages anything related to files.
##
## Does actions like saving the project, exporting to the custom songs folder and saving the settings.

## Emits if we found any errors.
signal errors_found(errors : String)

@onready var autosave_timer : Timer = $AutosaveTimer

## The location of the custom songs folder.
var custom_songs_folder : String = ""

## The location of the project .json.
var project_file : String = ""

## The name of the exporting folder inside the custom songs folder.
var folder_name : String = ""

## The preview file.
var preview_file : String = ""

## The location of where the .exe is located.
var exe_dir : String = OS.get_executable_path().get_base_dir()

## The song file.
var song_file : String = "" :
	# Set up audiostreamplayer in GameManager as soon as it's set
	set(value):
		if value != song_file:
			song_file = value
			GameManager.setup_audio(value)


var current_autosave_time: float = 300 :
	set(value):
		current_autosave_time = value
		if(GameManager.project_changed):
			toggle_autosave_timer(true)


func _init() -> void:
	Global.file_manager = self


func _ready() -> void:
	GameManager.project_was_changed.connect(toggle_autosave_timer)
	current_autosave_time = autosave_timer.wait_time
	if(OS.get_name() == "Windows"):
		custom_songs_folder = OS.get_data_dir().rstrip("Roaming") + "LocalLow/Garage 51/Drums Rock/CustomSongs"
	load_settings()
	var custom_dir : String = exe_dir + "/custom"
	print(custom_dir)
	if(DirAccess.dir_exists_absolute(custom_dir)):
		
		# Loading note file
		var note_file : Image = Image.load_from_file(custom_dir + "/note.png")
		if(note_file != null):
			GameManager.note_sprite = ImageTexture.create_from_image(note_file)
			
		# Loading marker file
		var marker_file : Image = Image.load_from_file(custom_dir + "/marker.png")
		if(marker_file != null):
			GameManager.marker_sprite = ImageTexture.create_from_image(marker_file)
			
		var background_image : Image
		background_image = Image.load_from_file(custom_dir + "/background.jpg")
		if(background_image == null):
			background_image = Image.load_from_file(custom_dir + "/background.png")
			
		if(background_image != null):
			Global.background_image.texture = ImageTexture.create_from_image(background_image)
			
			
		# Loading custom audio for drumkit
		for player : AudioStreamPlayer in Global.instruments:
			var audio_loader : WavAudioLoader = WavAudioLoader.new()
			var audio_file : AudioStreamWAV = audio_loader.loadfile(custom_dir + "/" + player.name.to_lower() + ".wav")
			if(audio_file != null):
				player.set_stream(audio_file)


func toggle_autosave_timer(start_timer : bool) -> void:
	var timer : Timer = $AutosaveTimer
	if(start_timer):
		timer.start(current_autosave_time) # -> _on_autosave_timer_timeout
	else:
		timer.stop()


func _on_autosave_timer_timeout() -> void:
	var current_autosave : int = 0
	var config : ConfigFile = ConfigFile.new()
	
	# Check for errors
	var err : Error = config.load("user://settings.cfg")
	if err != OK:
		printerr(err)
		return
		
	if(config.has_section_key("autosave","currentAutosave")):
		current_autosave = int(config.get_value("autosave","currentAutosave"))
	else:
		config.set_value("autosave","currentAutosave",0)
	current_autosave += 1
	
	if(current_autosave >= 6):
		current_autosave = 0
		
	var autosave_path : String = "user://autosave" + str(current_autosave) + ".json"
	
	save_project(autosave_path,true)
	config.set_value("autosave","currentAutosave",current_autosave)
	config.save("user://settings.cfg")


## Save the project into a .json file
func save_project(path : String, autosave : bool = false) -> void:
	# Set up general json file as a dictionary
	
	var json_data : Dictionary = {
		"metaData":
		[
			{
				"songName" : GameManager.song_name,
				"artistName" : GameManager.artist_name,
				"difficulty" : GameManager.difficulty,
				"map" : GameManager.map,
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
	
	# Make a new array with the notes
	var note_array : Array = []
	for i : Note in NoteManager.note_nodes:
		var individual_note : Dictionary = {
		"time" : i.time,
		"color" : i.color,
		"interval" : i.interval,
		"double_time" : i.double_time
		}
		note_array.append(individual_note)
		
	# Make a new array with the markers
	var marker_array : Array = []
	for i : Marker in NoteManager.marker_nodes:
		var individual_marker : Dictionary = {
			"time" : i.time,
			"bpm" : i.bpm,
			"snapping" : i.snapping
		}
		marker_array.append(individual_marker)
		
	# Add both to the dictionary
	json_data["notes"] = note_array
	json_data["marker"] = marker_array
	
	var json_string : String = JSON.stringify(json_data, "\t",false)
	# Check if path has .json at the end, else add it
	var regex : RegEx = RegEx.new()
	regex.compile("\\.(json)")
	var result : RegExMatch = regex.search(path)
	
	var file : FileAccess
	
	if(result == null || result.get_string() != ".json"):
		file = FileAccess.open(path + ".json", FileAccess.WRITE)
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
	
	var config : ConfigFile = ConfigFile.new()
	
	# Check for errors
	var err : Error = config.load("user://settings.cfg")
	if err != OK:
		printerr(err)
	else:
		config.set_value("autosave","currentAutosave",7)
		config.set_value("autosave","lastSave",file.get_path())
		config.save("user://settings.cfg")
		
	file.store_string(json_string)
	file.close()
	
	if(autosave):
		Global.notification_popup.play_notification(tr("NOTIFICATION_PROJECT_AUTOSAVED").format({FILE = str(file.get_path())}), 2)
	else:
		
		Global.notification_popup.play_notification(tr("NOTIFICATION_PROJECT_SAVED_{FILE}", "File is the .json file").format({FILE = str(file.get_path())}), 2)
		GameManager.project_changed = false


func open_project(path : String) -> void:
	# Check if path contains either .json or .csv
	var regex : RegEx = RegEx.new()
	regex.compile("\\.(json|csv)")
	var result : RegExMatch = regex.search(path)
	print("Opening file: " + path)
	Global.notification_popup.play_notification(tr("POPUP_LOADING_{FILE}","{FILE} is the file that is being opend") + path, 2)
	match result.get_string():
		".json":
			Global.file_manager.project_file = path
			print(".json")
			var json_file : Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			GameManager.setup_project(json_file)
		".csv":
			print(".csv")
			GameManager.clean_project()
			NoteManager.initialise_notes(Global.file_manager.csv_to_json(path))


## Convert an existing .csv file to json.
## Generally not recommended for actually editing the chart (because of floating point inaccuracies) but still a possiblity
func csv_to_json(csv_file : String) -> Array:
	
	# Time,Enemy Type(1normal,2dual,3fat),Color1,Color2,1,Drumroll amount,Aux
	var file : FileAccess = FileAccess.open(csv_file, FileAccess.READ)
	
	print(file.get_line()) # Skip the first line
	
	var note_array : Array = []
	
	# While we haven't reached end of file yet
	while file.get_position() < file.get_length():
		
		# Read the csv line and advanced the line
		var csv_line : PackedStringArray = file.get_csv_line()
		var temp_array : Dictionary = {}
		
		# Read the second item which is the enemy type
		match int(csv_line[1]):
			1: # Normal demon
				temp_array["time"] = float(csv_line[0])
				temp_array["color"] = int(csv_line[2])
				temp_array["interval"] = int(0)
				note_array.append(temp_array)
			2: # Dual demon
				temp_array["time"] = float(csv_line[0])
				temp_array["color"] = int(csv_line[2])
				temp_array["interval"] = int(0)
				note_array.append(temp_array)
				# Since it's a double note duplicate the array and just change the color
				var new_array : Dictionary = temp_array.duplicate()
				new_array["color"] = int(csv_line[3])
				note_array.append(new_array)
			3: # Fat demon
				temp_array["time"] = float(csv_line[0])
				temp_array["color"] = int(csv_line[2])
				temp_array["interval"] = int(csv_line[5])
				note_array.append(temp_array)
	return note_array

## Exports the project to the custom songs folder
func export_project() -> void:
	print("Exporting project")
	
	# Check for errors and don't continue if any is found
	var errors : String = check_for_errors()
	if(errors != ""):
		errors_found.emit(errors)
	else:
		errors_found.emit(errors)
		
		# Set the path to the custom songs folder + the exported folder name
		var path : String = custom_songs_folder + folder_name
		print(path)
		if(DirAccess.dir_exists_absolute(path)):
			print("Path exists")
		else:
			print("Path don't exist")
			DirAccess.make_dir_absolute(path)
		var dir : DirAccess = DirAccess.open(path)
		
		# Copy audio files to the folder
		print(dir.copy(song_file,path + "/song.ogg"))
		print(dir.copy(preview_file, path + "/preview.ogg"))
		
		# Making info.csv file
		var info : FileAccess = FileAccess.open(path + "/info.csv",FileAccess.WRITE)
		info.store_csv_line(PackedStringArray(["Song Name","Author Name","Difficulty","Song Duration in seconds","Song Map"]))
		info.store_csv_line(PackedStringArray([GameManager.song_name,GameManager.artist_name,str(GameManager.difficulty),roundi(GameManager.audio_length),str(GameManager.map)]))
		info.close()
		
		NoteManager.sort_all_notes()
		
		# Write the first line
		var notes : FileAccess = FileAccess.open(path + "/notes.csv",FileAccess.WRITE)
		notes.store_line("Time [s],Enemy Type,Aux Color 1,Aux Color 2,Nº Enemies,interval,Aux")
		var double_note : bool
		
		# Everything below here is adapted from https://github.com/daredevil28/drumsrockmidiparser/blob/main/drumsrockparser.py#L76
		for i : int in NoteManager.note_nodes.size():
			var note : Note = NoteManager.note_nodes[i]
			
			# If the previous was a double note then skip this iteration
			if(double_note):
				double_note = false
				continue
			
			var note_time : String
			var enemy_type : String = "1"
			var color_1 : String
			var color_2 : String
			var interval : String = ""
			var aux : String
			
			# if interval is not 0 then it's a drumroll
			if(note.interval != 0):
				enemy_type = "3"
				interval = str(note.interval)
			
			# If this note and the next one have the exact same time then it's a double note
			if(i+1 < NoteManager.note_nodes.size()):
				if(is_equal_approx(note.time,NoteManager.note_nodes[i+1].time)):
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
		
		Global.notification_popup.play_notification(tr("NOTIFICATION_PROJECT_EXPORTED_{PATH}", "{PATH} is the folder name inside the custom songs folder").format({PATH = path}), 1)

## Saves the client settings to [code]user://settings.cfg[/code]
func save_settings() -> void:
	# Initialise config file
	var config : ConfigFile = ConfigFile.new()
	
	# Check for errors
	var err : Error = config.load("user://settings.cfg")
	if err != OK:
		printerr(err)
	
	# Set all the variables into the config file
	config.set_value("volume","master",Global.volume_sliders[0].value)
	config.set_value("volume","music",Global.volume_sliders[1].value)
	config.set_value("volume","instruments",Global.volume_sliders[2].value)
	config.set_value("volume","sfx",Global.volume_sliders[3].value)
	
	config.set_value("settings","scrollSpeed",GameManager.scroll_speed)
	config.set_value("settings","lineOffset",NoteManager.offset)
	config.set_value("settings","fps",Engine.max_fps)
	config.set_value("settings","audioOffset",GameManager.audio_offset)
	config.set_value("settings","autoSaveInterval",current_autosave_time)
	config.set_value("settings", "metronomeEnabled",Global.metronome.metronome_enabled)
	config.set_value("settings", "language",TranslationServer.get_locale())
	
	# Save the config file
	config.save("user://settings.cfg")

## Loads the client settings from [code]user://settings.cfg[/code]
func load_settings() -> void:
	# Initialise config file
	var config : ConfigFile = ConfigFile.new()
	
	# Check for errors
	var err : Error = config.load("user://settings.cfg")
	if err != OK:
		printerr(err)
		save_settings()
		return
	
	# Set each volume setting
	var current_it : int = 0
	for volume : String in config.get_section_keys("volume"):
		Global.volume_sliders[current_it].value = config.get_value("volume", volume)
		current_it += 1
	
	# Set section key pair
	var settings : String = "settings"
	
	# Scrolling speed of notes
	if(config.has_section_key(settings,"scrollSpeed")):
		GameManager.scroll_speed = int(config.get_value(settings, "scrollSpeed"))
	
	# Line offset
	if(config.has_section_key(settings,"lineOffset")):
		NoteManager.offset = int(config.get_value(settings, "lineOffset"))
	
	# FPS
	if(config.has_section_key(settings,"fps")):
		Engine.max_fps = int(config.get_value(settings, "fps"))

	# Audio offset
	if(config.has_section_key(settings,"audioOffset")):
		GameManager.audio_offset = float(config.get_value(settings, "audioOffset"))

	# Auto save interval
	if(config.has_section_key(settings,"autoSaveInterval")):
		Global.file_manager.current_autosave_time = float(config.get_value(settings,"autoSaveInterval"))
	
	# If the metronome is enabled or disabled
	if(config.has_section_key(settings,"metronomeEnabled")):
		Global.metronome.metronome_enabled = bool(config.get_value(settings, "metronomeEnabled"))
	
	# Locale of the program
	if(config.has_section_key(settings,"language")):
		TranslationServer.set_locale(config.get_value(settings, "language"))

## Checks for errors in the current project
func check_for_errors() -> String:
	# Check for errors before exporting the project
	var errors : String = ""
	if(GameManager.song_name == ""):
		errors += tr("WINDOW_EXPORT_PANEL_ISSUES_NO_SONG_NAME")
	if(GameManager.artist_name == ""):
		errors += tr("WINDOW_EXPORT_PANEL_ISSUES_NO_ARTIST_NAME")
	if(Global.file_manager.song_file == ""):
		errors += tr("WINDOW_EXPORT_PANEL_ISSUES_NO_SONG_FILE")
	if(Global.file_manager.preview_file == ""):
		errors += tr("WINDOW_EXPORT_PANEL_ISSUES_NO_PREVIEW_FILE")
	if(Global.file_manager.folder_name == ""):
		errors += tr("WINDOW_EXPORT_PANEL_ISSUES_NO_FOLDER_NAME")
	if(Global.file_manager.custom_songs_folder == ""):
		errors += tr("WINDOW_EXPORT_PANEL_ISSUES_NO_CUSTOM_SONGS_FOLDER")
	return errors
