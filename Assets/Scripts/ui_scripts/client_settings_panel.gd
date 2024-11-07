extends Window


## When we are about to open the client settings, set the proper values.
func _on_client_settings_about_to_popup() -> void:
	# ClientSettings
	for setting : Node in get_tree().get_nodes_in_group("ClientSettings"):
		match setting.name:
			"ScrollSpeed":
				setting.value = GameManager.scroll_speed
			"Offset":
				setting.value = NoteManager.offset
			"MaxFPS":
				setting.value = Engine.max_fps
			"AudioOffset":
				setting.value = GameManager.audio_offset
			"AutoSaveInterval":
				setting.value = Global.file_manager.current_autosave_time


## Close the client settings.
func _on_client_settings_close_requested() -> void:
	visible = false


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


## Change the audio offset.
func _on_audio_offset_value_changed(value: float) -> void:
	GameManager.audio_offset = value

## Change the auto save interval
func _on_auto_save_interval_value_changed(value: float) -> void:
	Global.file_manager.current_autosave_time = value
