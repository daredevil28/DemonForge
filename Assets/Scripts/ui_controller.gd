extends Control

@onready var file_dialog : FileDialog = $FileDialog
@onready var save_dialog : FileDialog = $SaveDialog
@onready var song_properties_panel : Window = $SongProperties
@onready var manager : Node = %GameManager
@onready var property_nodes : Array = get_tree().get_nodes_in_group("SongProperties")

func _on_file_index_pressed(index : int) -> void:
	match index:
		0:
			print("New File")
			manager.clean_project()
		1:
			print("Load File")
			file_dialog.popup()# > _on_file_dialog_file_selected()
			
		2:
			print("Save File")
			save_dialog.popup()# > _on_save_dialog_file_selected()

func _on_properties_index_pressed(index : int) -> void:
	match index:
		0:
			print("Song Properties")
			if !song_properties_panel.visible:
				song_properties_panel.popup()
			else:
				song_properties_panel.visible = false
		1:
			print("Client Options")

func _on_file_dialog_file_selected(path : String) -> void:
	var regex : RegEx = RegEx.new()
	regex.compile("\\.(json|csv)")
	var result : RegExMatch = regex.search(path)
	match result.get_string():
		".json":
			print(".json")
			var json_file : Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			
			manager.setup_project(json_file)
		".csv":
			print(".csv")
			%NoteManager.initialise_notes(csv_to_json(path))

func _on_save_dialog_file_selected(path : String) -> void:
	manager.save_project(path)
	
func _on_song_properties_about_to_popup() -> void:
	#Song name property
	property_nodes[0].text = manager.song_name
	#Artist name property
	property_nodes[1].text = manager.artist_name
	#Difficulty of song
	property_nodes[2].selected = manager.difficulty
	#Which map it plays on
	property_nodes[3].selected = manager.map
	#Path for the song file
	property_nodes[4].text = manager.song_file
	property_nodes[5].text = str(manager.bpm)
	
func _on_song_properties_close_requested() -> void:
	song_properties_panel.visible = false
	for i in property_nodes:
		print(i.name + ": " + i.text)
	#Song name property
	manager.song_name = property_nodes[0].text
	#Artist name property
	manager.artist_name = property_nodes[1].text
	#Difficulty of song
	manager.difficulty = property_nodes[2].selected
	#Which map it plays on
	manager.map = property_nodes[3].selected
	#Path for the song file
	manager.song_file = property_nodes[4].text
	manager.bpm = float(property_nodes[5].text)

func csv_to_json(csv_file : String) -> Array:
	#Time,Enemy Type(1normal,2dual,3fat),Color1,Color2,1,Drumroll amount,Aux
	var file : FileAccess = FileAccess.open(csv_file, FileAccess.READ)
	print(file.get_line()) #Skip the first line
	
	var note_array : Array = []
	
	while file.get_position() < file.get_length():
		var csv_line : PackedStringArray = file.get_csv_line()
		var temp_array : Dictionary = {}
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
				var new_array : Dictionary = temp_array.duplicate()
				new_array["color"] = int(csv_line[3])
				note_array.append(new_array)
			3: #fat demon
				temp_array["time"] = float(csv_line[0])
				temp_array["color"] = int(csv_line[2])
				temp_array["interval"] = int(csv_line[5])
				note_array.append(temp_array)
	return note_array
