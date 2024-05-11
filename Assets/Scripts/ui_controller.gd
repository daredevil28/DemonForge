extends Control

@onready var file_dialog : FileDialog = $FileDialog
@onready var save_dialog : FileDialog = $SaveDialog
@onready var song_file_dialog : FileDialog = $SongFileDialog
@onready var song_properties_panel : Window = $SongProperties
@onready var client_settings_panel : Window = $ClientSettings
@onready var song_properties : Array = get_tree().get_nodes_in_group("SongProperties")
@onready var volume_sliders : Array = get_tree().get_nodes_in_group("VolumeSliders")
@onready var client_settings : Array = get_tree().get_nodes_in_group("ClientSettings")

func _on_file_index_pressed(index : int) -> void:
	match index:
		0:
			print("New File")
			GameManager.clean_project()
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
			if !client_settings_panel.visible:
				client_settings_panel.popup()
			else:
				client_settings_panel.visible = false

func _on_song_select_file_button_up() -> void:
	song_file_dialog.popup()
	
func _on_file_dialog_file_selected(path : String) -> void:
	var regex : RegEx = RegEx.new()
	regex.compile("\\.(json|csv)")
	var result : RegExMatch = regex.search(path)
	match result.get_string():
		".json":
			print(".json")
			var json_file : Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			
			GameManager.setup_project(json_file)
		".csv":
			print(".csv")
			NoteManager.initialise_notes(csv_to_json(path))

func _on_save_dialog_file_selected(path : String) -> void:
	GameManager.save_project(path)

func _on_song_file_dialog_file_selected(path : String) -> void:
	GameManager.song_file = path
	get_node("SongProperties/ColorRect/SongPropertiesValues/HBoxContainer/SongLocation").text = path
	
func _on_song_properties_about_to_popup() -> void:
	#Song name property
	song_properties[0].text = GameManager.song_name
	#Artist name property
	song_properties[1].text = GameManager.artist_name
	#Difficulty of song
	song_properties[2].selected = GameManager.difficulty
	#Which map it plays on
	song_properties[3].selected = GameManager.map
	#Path for the song file
	song_properties[4].text = GameManager.song_file
	song_properties[5].text = str(GameManager.bpm)
	
func _on_song_properties_close_requested() -> void:
	song_properties_panel.visible = false
	for i in song_properties:
		print(i.name + ": " + i.text)
	#Song name property
	GameManager.song_name = song_properties[0].text
	#Artist name property
	GameManager.artist_name = song_properties[1].text
	#Difficulty of song
	GameManager.difficulty = song_properties[2].selected
	#Which map it plays on
	GameManager.map = song_properties[3].selected
	#Path for the song file
	GameManager.song_file = song_properties[4].text
	GameManager.bpm = float(song_properties[5].text)
	GameManager.redraw_scene()
	
func _on_client_settings_about_to_popup():
	client_settings[0].value = GameManager.scroll_speed
	client_settings[1].value = NoteManager.offset
	
func _on_client_settings_close_requested() -> void:
	client_settings_panel.visible = false
	GameManager.scroll_speed = client_settings[0].value
	NoteManager.offset = client_settings[1].value

func _on_slider_changed(value, slider):
	var new_db_value = value / 100 * 24
	print(new_db_value)
	if new_db_value == 0:
		AudioServer.set_bus_mute(slider, true)
	else:
		AudioServer.set_bus_mute(slider, false)
		AudioServer.set_bus_volume_db(slider,new_db_value-24)

func _on_scroll_speed_value_changed(value):
	GameManager.scroll_speed = value

func _on_offset_value_changed(value):
	NoteManager.offset = value

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

func check_for_window_focus():
	if song_properties_panel.has_focus() || client_settings_panel.has_focus():
		GameManager.is_another_window_focused = true
	else:
		GameManager.is_another_window_focused = false
		
func _process(delta):
	check_for_window_focus()
