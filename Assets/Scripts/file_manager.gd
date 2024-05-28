class_name FileManager extends Node

var custom_songs_folder : String = ""
var project_file : String = ""
var folder_name : String = ""
var preview_file : String = ""

var song_file : String = "" :
	#Set up audiostreamplayer in GameManager as soon as it's set
	set(value):
		if value != song_file:
			song_file = value
			GameManager.setup_audio(value)

func _init() -> void:
	Global.file_manager = self
	
	
func _ready() -> void:
	if(OS.get_name() == "Windows"):
		custom_songs_folder = OS.get_data_dir().rstrip("Roaming") + "LocalLow/Garage 51/Drums Rock/CustomSongs"
	load_settings()

func save_project(path : String) -> void:
	#Save project into a .json file
	#Set up general json file as a dictionary
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
	GameManager.project_changed = false
	Global.notification_popup.play_notification("Project has been saved to: " + path, 2)

func csv_to_json(csv_file : String) -> Array:
	#Convert an existing .csv file to json. Generally not recommended for actually editing the chart (because of floating point inaccuracies) but still a possiblity
	#Time,Enemy Type(1normal,2dual,3fat),Color1,Color2,1,Drumroll amount,Aux
	var file : FileAccess = FileAccess.open(csv_file, FileAccess.READ)
	
	print(file.get_line()) #Skip the first line
	
	var note_array : Array = []
	
	#While we haven't reached end of file yet
	while file.get_position() < file.get_length():
		
		#Read the csv line and advanced the line
		var csv_line : PackedStringArray = file.get_csv_line()
		var temp_array : Dictionary = {}
		
		#Read the second item which is the enemy type
		match int(csv_line[1]):
			1: #normal demon
				temp_array["time"] = float(csv_line[0])
				temp_array["color"] = int(csv_line[2])
				temp_array["interval"] = int(0)
				note_array.append(temp_array)
			2: #dual demon
				temp_array["time"] = float(csv_line[0])
				temp_array["color"] = int(csv_line[2])
				temp_array["interval"] = int(0)
				note_array.append(temp_array)
				#Since it's a double note duplicate the array and just change the color
				var new_array : Dictionary = temp_array.duplicate()
				new_array["color"] = int(csv_line[3])
				note_array.append(new_array)
			3: #fat demon
				temp_array["time"] = float(csv_line[0])
				temp_array["color"] = int(csv_line[2])
				temp_array["interval"] = int(csv_line[5])
				note_array.append(temp_array)
	return note_array

func export_project() -> void:
	#Export the project to the custom songs folder
	print("Exporting project")
	#Check for errors and don't continue if any is found
	var errors : String = GameManager.check_for_errors()
	if(errors != ""):
		GameManager.errors_found.emit(errors)
	else:
		GameManager.errors_found.emit(errors)
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
		info.store_csv_line(PackedStringArray([GameManager.song_name,GameManager.artist_name,str(GameManager.difficulty),roundi(GameManager.audio_length),str(GameManager.map)]))
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

func save_settings() -> void:
	var settings_json : Dictionary = {
		"volume": [
			{
				"master": Global.volume_sliders[0].value,
				"music": Global.volume_sliders[1].value,
				"instruments": Global.volume_sliders[2].value,
				"sfx": Global.volume_sliders[3].value
			}
		],
		"settings": [
			{
				"scrollSpeed": GameManager.scroll_speed,
				"lineOffset": NoteManager.offset,
				"fps": Engine.max_fps,
				"sleep": OS.low_processor_usage_mode_sleep_usec,
				"audioOffset": GameManager.audio_offset
			}
		]
	}
	var settings_file : FileAccess = FileAccess.open("settings.cfg",FileAccess.WRITE)
	var json_string : String = JSON.stringify(settings_json, "\t",false)
	settings_file.store_string(json_string)
	settings_file.close()

func load_settings() -> void:
	var settings_file : FileAccess = FileAccess.open("settings.cfg",FileAccess.READ)
	
	if(settings_file == null):
		return
	else:
		var json_file = JSON.parse_string(settings_file.get_as_text())
		var volume_settings : Dictionary = json_file["volume"][0]
		Global.volume_sliders[0].value = volume_settings["master"]
		Global.volume_sliders[1].value = volume_settings["music"]
		Global.volume_sliders[2].value = volume_settings["instruments"]
		Global.volume_sliders[3].value = volume_settings["sfx"]
		
		var settings : Dictionary = json_file["settings"][0]
		
		GameManager.scroll_speed = settings["scrollSpeed"]
		NoteManager.offset = settings["lineOffset"]
		Engine.max_fps = settings["fps"]
		OS.low_processor_usage_mode_sleep_usec = settings["sleep"]
		GameManager.audio_offset = settings["audioOffset"]
