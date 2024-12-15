extends MenuBar


@onready var _open_dialog : FileDialog = $"../OpenDialog"
@onready var _save_dialog : FileDialog = $"../SaveDialog"
@onready var _export_panel : Window = $"../ExportPanel"
@onready var _speed_menu_panel : Window = $"../SpeedMenu"
@onready var _song_properties_panel : Window = $"../SongProperties"
@onready var _client_settings_panel : Window = $"../ClientSettings"
@onready var _about_panel : Window = $"../About"
@onready var _credits : Window = $"../Credits"


## When we press anything in the File menu bar.
func _on_file_index_pressed(index : int) -> void:
	# File menu bar
	match index:
		0:
			print("New File")
			if(GameManager.project_changed):
				Global.popup_dialog.play_dialog(tr("WINDOW_DIALOG_NOTSAVED_TITLE"),tr("WINDOW_DIALOG_NOTSAVED_EXIT"), GameManager.clean_project)
			else:
				GameManager.clean_project()
		1:
			print("Load File")
			if(GameManager.project_changed):
				Global.popup_dialog.play_dialog(tr("WINDOW_DIALOG_NOTSAVED_TITLE"),tr("WINDOW_DIALOG_NOTSAVED_CONTINUE"), _open_dialog.popup)
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
			Global.popup_dialog.play_dialog(tr("WINDOW_DIALOG_DESTRUCTIVE_TITLE"),tr("WINDOW_DIALOG_WARNING_SNAP_NOTES"),NoteManager.snap_all_notes_to_nearest)
		1:
			print("Speed Menu")
			if(!_speed_menu_panel.visible):
				_speed_menu_panel.popup()
			else:
				_speed_menu_panel.visible = false


func _on_about_index_pressed(index: int) -> void:
	match index:
		0:
			OS.shell_open("https://github.com/daredevil28/DemonForge")
		1:
			_about_panel.popup()
		2:
			_credits.popup()


## When we select a file in the open dialog.
func _on_open_dialog_file_selected(path : String) -> void:
	# File > Open File
	Global.file_manager.open_project(path)


## When we select a file in the save dialog.
func _on_save_dialog_file_selected(path : String) -> void:
	# File > Save File
	Global.file_manager.project_file = path
	Global.file_manager.save_project(path)


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
