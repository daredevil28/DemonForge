extends Window


@onready var _song_properties : Array[Node] = get_tree().get_nodes_in_group("SongProperties")
@onready var _song_file_dialog : FileDialog = $"../SongFileDialog"
@onready var _preview_file_dialog : FileDialog = $"../PreviewFileDialog"


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
	visible = false
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
