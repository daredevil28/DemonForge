class_name ui_controller
extends Control
## Anything related to the UI goes in here

var _note_settings_focused : bool = false
var _song_properties_focused : bool = false
var _client_settings_focused : bool = false
var _export_panel_focused : bool = false
var _speed_menu_focused : bool = false
var _about_focused : bool = false
var _credits_focused : bool = false
var _settings_spinbox_focused : bool = false


func _ready() -> void:
	Global.ui_controller = self


func _process(_delta : float) -> void:
	_check_for_window_focus()


## Check if any window is being focused
func _check_for_window_focus() -> void:
	# Check the focus of windows so that we don't show the cursor note when we are focusing on a window
	if _note_settings_focused || _client_settings_focused || _export_panel_focused || _note_settings_focused || _speed_menu_focused || _about_focused || _credits_focused || _settings_spinbox_focused:
		GameManager.is_another_window_focused = true
	else:
		GameManager.is_another_window_focused = false


func _on_song_properties_focused(focus : bool) -> void:
	_song_properties_focused = focus


func _on_speed_menu_focused(focus : bool) -> void:
	_speed_menu_focused = focus


func _on_client_settings_focused(focus : bool) -> void:
	_client_settings_focused = focus


func _on_export_panel_focused(focus: bool) -> void:
	_export_panel_focused = focus


func _on_about_focused(focus : bool) -> void:
	_about_focused = focus

func _on_credits_focused(focus : bool) -> void:
	_credits_focused = focus

func _on_settings_spinbox_focused(focus : bool) -> void:
	_settings_spinbox_focused = focus
