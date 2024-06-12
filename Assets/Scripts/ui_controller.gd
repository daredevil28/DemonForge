extends Control
## Anything related to the UI goes in here

var _selected_note : InternalNote
var _opening_note_settings : bool
var _note_settings_focused : bool = false

@onready var _open_dialog : FileDialog = $OpenDialog
@onready var _save_dialog : FileDialog = $SaveDialog
@onready var _song_file_dialog : FileDialog = $SongFileDialog
@onready var _preview_file_dialog : FileDialog = $PreviewFileDialog
@onready var _folder_dialog : FileDialog = $FolderDialog
@onready var _song_properties_panel : Window = $SongProperties
@onready var _client_settings_panel : Window = $ClientSettings
@onready var _export_panel : Window = $ExportPanel
@onready var _song_properties : Array = get_tree().get_nodes_in_group("SongProperties")
@onready var _export_settings : Array = get_tree().get_nodes_in_group("ExportSettings")
@onready var _note_settings : Array = get_tree().get_nodes_in_group("NoteSettings")
@onready var _note_settings_panel : Control = $NoteSettings
@onready var _song_time_label : Label = $SongTimeLabel
@onready var _notification_popup : Control = $NotificationContainer


func _ready() -> void:
	GameManager.note_selected.connect(_on_note_selected)
	GameManager.note_deselected.connect(_on_note_deselected)


#region MenuBar
## When we press anything in the File menu bar.
func _on_file_index_pressed(index : int) -> void:
	# File menu bar
	match index:
		0:
			print("New File")
			if(GameManager.project_changed):
				Global.popup_dialog.play_dialog("Project not saved!","The current project has not been saved, are you sure you want to continue?", GameManager.clean_project)
			else:
				GameManager.clean_project()
		1:
			print("Load File")
			if(GameManager.project_changed):
				Global.popup_dialog.play_dialog("Project not saved!","The current project has not been saved, are you sure you want to continue?", _open_dialog.popup)
			else:
				_open_dialog.popup()# > _on_open_dialog_file_selected()
		2:
			print("Save File")
			if(Global.file_manager.project_file == ""):
				_save_dialog.popup()# > _on_save_dialog_file_selected()
			else:
				Global.file_manager.save_project(Global.file_manager.project_file)
		3:
			print("Export project")
			_export_panel.popup()# > _on_open_dialog_file_selected


## When we press anything in the Properties menu bar.
func _on_properties_index_pressed(index : int) -> void:
	# Properties menu bar
	match index:
		0:
			print("Song Properties")
			if !_song_properties_panel.visible:
				_song_properties_panel.popup()# > _on_song_properties_about_to_popup
			else:
				_song_properties_panel.visible = false
		1:
			print("Client Options")
			if !_client_settings_panel.visible:
				_client_settings_panel.popup()# > _on_client_settings_about_to_popup
			else:
				_client_settings_panel.visible = false


## When we press anything in the Tools menu bar.
func _on_tools_index_pressed(index: int) -> void:
	match index:
		0:
			Global.popup_dialog.play_dialog("Destructive action!","This will snap all the notes to the closest snap value. This can not be undone. Are you sure?",NoteManager.snap_all_notes_to_nearest)
#endregion


#region Everything related to files
## When we select a file in the open dialog.
func _on_open_dialog_file_selected(path : String) -> void:
	# File > Open File
	# Check if path contains either .json or .csv
	var regex : RegEx = RegEx.new()
	regex.compile("\\.(json|csv)")
	var result : RegExMatch = regex.search(path)
	
	Global.notification_popup.play_notification("Loading file: " + path, 2)
	match result.get_string():
		".json":
			Global.file_manager.project_file = path
			print(".json")
			var json_file : Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			GameManager.setup_project(json_file)
		".csv":
			print(".csv")
			NoteManager.clear_all_notes()
			NoteManager.initialise_notes(Global.file_manager.csv_to_json(path))


## When we select a file in the save dialog.
func _on_save_dialog_file_selected(path : String) -> void:
	# File > Save File
	Global.file_manager.save_project(path)
#endregion


#region Song properties panel
## Set up the properties panel if it's about to pop up.
func _on_song_properties_about_to_popup() -> void:
	# Song name property
	_song_properties[0].text = GameManager.song_name
	# Artist name property
	_song_properties[1].text = GameManager.artist_name
	# Difficulty of song
	_song_properties[2].selected = GameManager.difficulty
	# Which map it plays on
	_song_properties[3].selected = GameManager.map
	# Path for the song file
	_song_properties[4].text = Global.file_manager.song_file
	# Path to the preview file
	_song_properties[5].text = Global.file_manager.preview_file



## Save all the values if the properties panel is closed.
func _on_song_properties_close_requested() -> void:
	_song_properties_panel.visible = false
	for i : Node in _song_properties:
		print(i.name + ": " + i.text)
	# Song name property
	GameManager.song_name = _song_properties[0].text
	# Artist name property
	GameManager.artist_name = _song_properties[1].text
	# Difficulty of song
	GameManager.difficulty = _song_properties[2].selected
	# Which map it plays on
	GameManager.map = _song_properties[3].selected
	# Path for the song file
	Global.file_manager.song_file = _song_properties[4].text
	# Path to the preview file
	Global.file_manager.preview_file = _song_properties[5].text


## When we press the song select button in properties.
func _on_song_select_file_button_up() -> void:
	# Properties > Song Properties > song file select
	_song_file_dialog.popup()# > _on_song_file_dialog_file_selected


## When we select a file with the song select dialog.
func _on_song_file_dialog_file_selected(path : String) -> void:
	# SongFileDialog
	Global.file_manager.song_file = path
	# Song file
	_song_properties[4].text = path


## When we press the preview select button in properties.
func _on_preview_select_file_button_up() -> void:
	# Properties > Song Properties > Preview file select
	_preview_file_dialog.popup() # _on_preview_file_dialog_file_selected

## When we select a file with the preview select dialog.
func _on_preview_file_dialog_file_selected(path: String) -> void:
	# PreviewFileDialog
	Global.file_manager.preview_file = path
	_song_properties[5].text = path
#endregion


#region Client settings panel
## When we are about to open the client settings, set the proper values.
func _on_client_settings_about_to_popup() -> void:
	# ClientSettings
	Global.client_settings[0].value = GameManager.scroll_speed
	Global.client_settings[1].value = NoteManager.offset
	Global.client_settings[2].value = Engine.max_fps
	Global.client_settings[3].value = OS.low_processor_usage_mode_sleep_usec
	Global.client_settings[4].value = GameManager.audio_offset


## Close the client settings.
func _on_client_settings_close_requested() -> void:
	_client_settings_panel.visible = false


## If we move any volume slider then adjust the proper volume mixer.
func _on_slider_changed(value : float, slider : int) -> void:
	# When any volume slider has been changed
	# Go down a max of -24dB
	var new_db_value : float = value / 100 * 24
	# If it's 0 then mute the audio bus
	if new_db_value == 0:
		AudioServer.set_bus_mute(slider, true)
	else:
		AudioServer.set_bus_mute(slider, false)
		AudioServer.set_bus_volume_db(slider,new_db_value-24)


## Change the scroll speed.
func _on_scroll_speed_value_changed(value : float) -> void:
	GameManager.scroll_speed = roundi(value)


## Change the FPS max.
func _on_max_fps_value_changed(value: float) -> void:
	Engine.max_fps = roundi(value)


## Change the judgement line offset.
func _on_offset_value_changed(value : float) -> void:
	NoteManager.offset = roundi(value)


## Change the time between frames.
func _on_time_between_frames_value_changed(value: float) -> void:
	OS.low_processor_usage_mode_sleep_usec = roundi(value)


## Change the audio offset.
func _on_audio_offset_value_changed(value: float) -> void:
	GameManager.audio_offset = value
#endregion


#region Export panel
## When the export panel is about to pop up, set the proper values.
func _on_export_panel_about_to_popup() -> void:
	# ExportPanel
	_export_settings[0].text = Global.file_manager.custom_songs_folder
	_export_settings[1].text = Global.file_manager.folder_name
	_export_settings[2].text = Global.file_manager.check_for_errors()


## Close the export panel
func _on_export_panel_close_requested() -> void:
	_export_panel.visible = false


## Pop up the folder dialog when we press the custom folder button.
func _on_custom_folder_button_up() -> void:
	_folder_dialog.popup()


## Export the project when we press the export button
func _on_export_project_button_up() -> void:
	Global.file_manager.export_project()


## If we edit the custom song folder location or press the custom song folder location button
func _on_folder_selected(dir : String) -> void:# Connects to both the texturebutton and the lineEdit button
	Global.file_manager.custom_songs_folder = dir
	_export_settings[0].text = dir


func _on_folder_name_text_changed(new_text : String) -> void:
	Global.file_manager.folder_name = 	"/"+new_text
#endregion

#region Note settings panel
## If mouse has entered the note settings box.
func _on_note_settings_mouse_entered() -> void:
	_note_settings_focused = true


## If mouse has left the note settings box
func _on_note_settings_mouse_exited() -> void:
	_note_settings_focused = false


## Called whenever a spin box value changed in the client settings
func _on_spin_box_value_changed(value: float, box : String) -> void:
	# Change the specific box
	GameManager.project_changed = true
	
	if(_selected_note != null):
		if(_opening_note_settings == false):
			var new_action : ValueAction = ValueAction.new(Action.ActionName.VALUECHANGED)
			new_action.time = _selected_note.time
			new_action.color = _selected_note.color
			
			match box:
				
				"interval":
					new_action.value_type = ValueAction.ValueType.INTERVAL
					new_action.old_value = _selected_note.interval
					_selected_note.interval = value
					
				"bpm":
					new_action.value_type = ValueAction.ValueType.BPM
					new_action.old_value = _selected_note.bpm
					_selected_note.bpm = value
					Global.game_scene_node.queue_redraw()
					
				"snapping":
					new_action.value_type = ValueAction.ValueType.SNAPPING
					new_action.old_value = _selected_note.snapping
					_selected_note.snapping = value
					Global.game_scene_node.queue_redraw()
					
			GameManager.add_undo_action(new_action)



## Called on GameManager.note_selected
func _on_note_selected(note : InternalNote) -> void:# < GameManager.note_selected
	
	# Makes the note settings panel visible
	_selected_note = note
	_opening_note_settings = true
	# If note is a marker then show the marker panel, else show the note panel
	if(note is Marker):
		_note_settings[1].value = _selected_note.bpm
		_note_settings[2].value = _selected_note.snapping
		_note_settings_panel.get_child(0).visible = false
		_note_settings_panel.get_child(1).visible = true
	if(note is Note):
		_note_settings[0].value = _selected_note.interval
		_note_settings_panel.get_child(0).visible = true
		_note_settings_panel.get_child(1).visible = false
	_note_settings_panel.visible = true
	_opening_note_settings = false


## Called on GameManager.note_deselected
func _on_note_deselected(_note : InternalNote) -> void:
	_note_settings_panel.visible = false
	_selected_note = null
#endregion


## Check if any window is being focused
func _check_for_window_focus() -> void:
	# Check the focus of windows so that we don't show the cursor note when we are focusing on a window
	if _song_properties_panel.has_focus() || _client_settings_panel.has_focus() || _export_panel.has_focus() || _note_settings_focused:
		GameManager.is_another_window_focused = true
	else:
		GameManager.is_another_window_focused = false


func _process(_delta : float) -> void:
	_check_for_window_focus()
	# Time passed in song
	_song_time_label.text = str(round(GameManager.current_pos))


func _shortcut_input(event: InputEvent) -> void:
	# Ctrl + N
	if(event.is_action_pressed("NewProject")):
		_on_file_index_pressed(0)
	# Ctrl + L
	if(event.is_action_pressed("LoadFile")):
		_on_file_index_pressed(1)
	# Ctrl + S
	if(event.is_action_pressed("SaveProject")):
		_on_file_index_pressed(2)	
