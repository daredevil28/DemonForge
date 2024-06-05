#Mostly anything related to the UI goes here
extends Control

@onready var open_dialog : FileDialog = $OpenDialog
@onready var save_dialog : FileDialog = $SaveDialog
@onready var song_file_dialog : FileDialog = $SongFileDialog
@onready var preview_file_dialog : FileDialog = $PreviewFileDialog
@onready var folder_dialog : FileDialog = $FolderDialog
@onready var song_properties_panel : Window = $SongProperties
@onready var client_settings_panel : Window = $ClientSettings
@onready var export_panel : Window = $ExportPanel
@onready var song_properties : Array = get_tree().get_nodes_in_group("SongProperties")
@onready var export_settings : Array = get_tree().get_nodes_in_group("ExportSettings")
@onready var note_settings : Array = get_tree().get_nodes_in_group("NoteSettings")
@onready var note_settings_panel : Control = $NoteSettings
@onready var song_time_label : Label = $SongTimeLabel
@onready var notification_popup : Control = $NotificationContainer

var selected_note : InternalNote
var opening_note_settings : bool

func _ready() -> void:
	GameManager.note_selected.connect(_on_note_selected)
	GameManager.note_deselected.connect(_on_note_deselected)

#region MenuBar
func _on_file_index_pressed(index : int) -> void:
	#File menu bar
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
				Global.popup_dialog.play_dialog("Project not saved!","The current project has not been saved, are you sure you want to continue?", open_dialog.popup)
			else:
				open_dialog.popup()# > _on_open_dialog_file_selected()
		2:
			print("Save File")
			if(Global.file_manager.project_file == ""):
				save_dialog.popup()# > _on_save_dialog_file_selected()
			else:
				Global.file_manager.save_project(Global.file_manager.project_file)
		3:
			print("Export project")
			export_panel.popup()# > _on_open_dialog_file_selected

func _on_properties_index_pressed(index : int) -> void:
	#Properties menu bar
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
				
func _on_tools_index_pressed(index: int) -> void:
	match index:
		0:
			Global.popup_dialog.play_dialog("Destructive action!","This will snap all the notes to the closest snap value. This can not be undone. Are you sure?",NoteManager.snap_all_notes_to_nearest)
#endregion

#region Everything related to files
func _on_open_dialog_file_selected(path : String) -> void:
	#File > Open File
	#Check if path contains either .json or .csv
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
			NoteManager.initialise_notes(Global.file_manager.csv_to_json(path))

func _on_save_dialog_file_selected(path : String) -> void:
	#File > Save File
	Global.file_manager.save_project(path)
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
	song_properties[4].text = Global.file_manager.song_file
	#Path to the preview file
	song_properties[5].text = Global.file_manager.preview_file
	
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
	Global.file_manager.song_file = song_properties[4].text
	#Path to the preview file
	Global.file_manager.preview_file = song_properties[5].text

func _on_song_select_file_button_up() -> void:
	#Properties > Song Properties > song file select
	song_file_dialog.popup()# > _on_song_file_dialog_file_selected

func _on_song_file_dialog_file_selected(path : String) -> void:
	#SongFileDialog
	Global.file_manager.song_file = path
	#Song file
	song_properties[4].text = path
	
func _on_preview_select_file_button_up() -> void:
	#Properties > Song Properties > Preview file select
	preview_file_dialog.popup() # _on_preview_file_dialog_file_selected
	
func _on_preview_file_dialog_file_selected(path: String) -> void:
	#PreviewFileDialog
	Global.file_manager.preview_file = path
	song_properties[5].text = path
#endregion
	
#region Client settings panel
func _on_client_settings_about_to_popup() -> void:
	#ClientSettings
	Global.client_settings[0].value = GameManager.scroll_speed
	Global.client_settings[1].value = NoteManager.offset
	Global.client_settings[2].value = Engine.max_fps
	Global.client_settings[3].value = OS.low_processor_usage_mode_sleep_usec
	Global.client_settings[4].value = GameManager.audio_offset
	
func _on_client_settings_close_requested() -> void:
	client_settings_panel.visible = false

func _on_slider_changed(value : float, slider : int) -> void:
	#When any volume slider has been changed
	#Go down a max of -24dB
	var new_db_value : float = value / 100 * 24
	#If it's 0 then mute the audio bus
	if new_db_value == 0:
		AudioServer.set_bus_mute(slider, true)
	else:
		AudioServer.set_bus_mute(slider, false)
		AudioServer.set_bus_volume_db(slider,new_db_value-24)

func _on_scroll_speed_value_changed(value : float) -> void:
	GameManager.scroll_speed = roundi(value)
	
func _on_max_fps_value_changed(value: float) -> void:
	Engine.max_fps = roundi(value)

func _on_offset_value_changed(value : float) -> void:
	NoteManager.offset = roundi(value)
	
func _on_time_between_frames_value_changed(value: float) -> void:
	OS.low_processor_usage_mode_sleep_usec = roundi(value)

func _on_audio_offset_value_changed(value: float) -> void:
	GameManager.audio_offset = value
#endregion

#region Export panel
func _on_export_panel_about_to_popup() -> void:
	#ExportPanel
	export_settings[0].text = Global.file_manager.custom_songs_folder
	export_settings[1].text = Global.file_manager.folder_name
	export_settings[2].text = GameManager.check_for_errors()
	
func _on_export_panel_close_requested() -> void:
	export_panel.visible = false

func _on_custom_folder_button_up() -> void:
	folder_dialog.popup()
	
func _on_export_project_button_up() -> void:
	Global.file_manager.export_project()

func _on_folder_selected(dir : String) -> void:# Connects to both the texturebutton and the lineEdit button
	Global.file_manager.custom_songs_folder = dir
	export_settings[0].text = dir
	
func _on_folder_name_text_changed(new_text : String) -> void:
	Global.file_manager.folder_name = 	"/"+new_text
#endregion

#region Note settings panel
var note_settings_focused : bool = false
	
#Check if mouse is inside the note settings box
func _on_note_settings_mouse_entered() -> void:
	note_settings_focused = true
	
func _on_note_settings_mouse_exited() -> void:
	note_settings_focused = false
	
func _on_spin_box_value_changed(value: float, box : String) -> void:
	#Change the specific box
	GameManager.project_changed = true
	
	if(selected_note != null):
		if(opening_note_settings == false):
			var new_action : ValueAction = ValueAction.new(Action.ActionName.VALUECHANGED)
			new_action.time = selected_note.time
			new_action.color = selected_note.color
			
			match box:
				
				"interval":
					new_action.value_type = ValueAction.ValueType.INTERVAL
					new_action.old_value = selected_note.interval
					selected_note.interval = value
					
				"bpm":
					new_action.value_type = ValueAction.ValueType.BPM
					new_action.old_value = selected_note.bpm
					selected_note.bpm = value
					GameManager.redraw_scene()
					
				"snapping":
					new_action.value_type = ValueAction.ValueType.SNAPPING
					new_action.old_value = selected_note.snapping
					selected_note.snapping = value
					GameManager.redraw_scene()
					
			GameManager.add_undo_action(new_action)

func _on_note_selected(note : InternalNote) -> void:# < GameManager.note_selected
	# Called when GameManager sends note_selected
	# Makes the note settings panel visible
	selected_note = note
	opening_note_settings = true
	# If note is a marker then show the marker panel, else show the note panel
	if(note is Marker):
		note_settings[1].value = selected_note.bpm
		note_settings[2].value = selected_note.snapping
		note_settings_panel.get_child(0).visible = false
		note_settings_panel.get_child(1).visible = true
	if(note is Note):
		note_settings[0].value = selected_note.interval
		note_settings_panel.get_child(0).visible = true
		note_settings_panel.get_child(1).visible = false
	note_settings_panel.visible = true
	opening_note_settings = false

func _on_note_deselected(_note : InternalNote) -> void:
	note_settings_panel.visible = false
	selected_note = null
#endregion

func check_for_window_focus() -> void:
	#Check the focus of windows so that we don't show the cursor note when we are focusing on a window
	if song_properties_panel.has_focus() || client_settings_panel.has_focus() || export_panel.has_focus() || note_settings_focused:
		GameManager.is_another_window_focused = true
	else:
		GameManager.is_another_window_focused = false

func _process(_delta : float) -> void:
	check_for_window_focus()
	#Time passed in song
	song_time_label.text = str(round(GameManager.current_pos))

func _shortcut_input(event: InputEvent) -> void:
	#Ctrl + N
	if(event.is_action_pressed("NewProject")):
		_on_file_index_pressed(0)
	#Ctrl + L
	if(event.is_action_pressed("LoadFile")):
		_on_file_index_pressed(1)
	#Ctrl + S
	if(event.is_action_pressed("SaveProject")):
		_on_file_index_pressed(2)	
