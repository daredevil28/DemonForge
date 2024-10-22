extends Window


@onready var _export_settings : Array[Node] = get_tree().get_nodes_in_group("ExportSettings")
@onready var _folder_dialog : FileDialog = $"../FolderDialog"


#region Export panel
## When the export panel is about to pop up, set the proper values.
func _on_export_panel_about_to_popup() -> void:
	# ExportPanel
	_export_settings[0].text = Global.file_manager.custom_songs_folder
	_export_settings[1].text = Global.file_manager.folder_name
	_export_settings[2].text = Global.file_manager.check_for_errors()


## Close the export panel
func _on_export_panel_close_requested() -> void:
	visible = false


## Pop up the folder dialog when we press the custom folder button.
func _on_custom_folder_button_up() -> void:
	_folder_dialog.popup()


## Export the project when we press the export button
func _on_export_project_button_up() -> void:
	Global.file_manager.export_project()


## Open the custom songs folder
func _on_open_customs_button_button_up() -> void:
	if(Global.file_manager.custom_songs_folder != ""):
		OS.shell_open(Global.file_manager.custom_songs_folder)


## If we edit the custom song folder location or press the custom song folder location button
func _on_folder_selected(dir : String) -> void:# Connects to both the texturebutton and the lineEdit button
	Global.file_manager.custom_songs_folder = dir
	_export_settings[0].text = dir


func _on_folder_name_text_changed(new_text : String) -> void:
	Global.file_manager.folder_name = 	"/"+new_text
#endregion
