extends Control

@onready var open_dialog : FileDialog = $OpenDialog
@onready var save_dialog : FileDialog = $SaveDialog
@onready var song_file_dialog : FileDialog = $SongFileDialog
@onready var folder_dialog : FileDialog = $FolderDialog
@onready var song_properties_panel : Window = $SongProperties
@onready var client_settings_panel : Window = $ClientSettings
@onready var export_panel : Window = $ExportPanel
@onready var song_properties : Array = get_tree().get_nodes_in_group("SongProperties")
@onready var volume_sliders : Array = get_tree().get_nodes_in_group("VolumeSliders")
@onready var client_settings : Array = get_tree().get_nodes_in_group("ClientSettings")
@onready var export_settings : Array = get_tree().get_nodes_in_group("ExportSettings")

#region MenuBar
func _on_file_index_pressed(index : int) -> void:
	match index:
		0:
			print("New File")
			GameManager.clean_project()
		1:
			print("Load File")
			open_dialog.popup()# > _on_open_dialog_file_selected()
		2:
			print("Save File")
			save_dialog.popup()# > _on_save_dialog_file_selected()
		3:
			print("Export project")
			export_panel.popup()# > _on_open_dialog_file_selected

func _on_properties_index_pressed(index : int) -> void:
	match index:
		0:
			print("Song Properties")
			if !song_properties_panel.visible:
				song_properties_panel.popup()# > _on_song_properties_about_to_popup
			else:
				song_properties_panel.visible = false
		1:
			print("Client Options")
			if !client_settings_panel.visible:
				client_settings_panel.popup()# > _on_client_settings_about_to_popup
			else:
				client_settings_panel.visible = false
#endregion

#region Everything related to files
func _on_open_dialog_file_selected(path : String) -> void:
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
#endregion
	
#region Song properties panel
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
	for i : Node in song_properties:
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

func _on_song_file_dialog_file_selected(path : String) -> void:
	GameManager.song_file = path
	#Song file
	song_properties[4].text = path
	
func _on_song_select_file_button_up() -> void:
	song_file_dialog.popup()# > _on_song_file_dialog_file_selected
#endregion
	
#region Client settings panel
func _on_client_settings_about_to_popup() -> void:
	client_settings[0].value = GameManager.scroll_speed
	client_settings[1].value = NoteManager.offset
	client_settings[2].value = Engine.max_fps
	client_settings[3].value = OS.low_processor_usage_mode_sleep_usec
	
func _on_client_settings_close_requested() -> void:
	client_settings_panel.visible = false
	Engine.max_fps = client_settings[2].value
	OS.low_processor_usage_mode_sleep_usec = client_settings[3].value

func _on_slider_changed(value : float, slider : int) -> void:
	var new_db_value : float = value / 100 * 24
	if new_db_value == 0:
		AudioServer.set_bus_mute(slider, true)
	else:
		AudioServer.set_bus_mute(slider, false)
		AudioServer.set_bus_volume_db(slider,new_db_value-24)

func _on_scroll_speed_value_changed(value : float) -> void:
	GameManager.scroll_speed = roundi(value)

func _on_offset_value_changed(value : float) -> void:
	NoteManager.offset = roundi(value)
#endregion

#region Export panel
func _on_export_panel_about_to_popup() -> void:
	export_settings[0].text = GameManager.custom_songs_folder
	export_settings[1].text = GameManager.folder_name
	export_settings[2].text = GameManager.check_for_errors()
	
func _on_export_panel_close_requested() -> void:
	export_panel.visible = false

func _on_custom_folder_button_up() -> void:
	folder_dialog.popup()
	
func _on_export_project_button_up() -> void:
	GameManager.export_project()

func _on_folder_dialog_dir_selected(dir : String) -> void:
	GameManager.custom_songs_folder = dir
	export_settings[0].text = dir
#endregion

func check_for_window_focus() -> void:
	if song_properties_panel.has_focus() || client_settings_panel.has_focus() || export_panel.has_focus():
		GameManager.is_another_window_focused = true
	else:
		GameManager.is_another_window_focused = false
		
func _process(_delta : float) -> void:
	check_for_window_focus()
