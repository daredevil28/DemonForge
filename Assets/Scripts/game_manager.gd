extends Node
## Singleton for managing everything related to the program.
##
## Manages everything related to audio, undo/redo, actions and more.

signal note_selected(note : Array[InternalNote])
signal note_deselected()
signal project_was_changed(value : bool)

## Audio player gets automatically set as soon as the audioplayer enters the scene tree.
var audio_player : AudioStreamPlayer
## Name of the song.
var song_name : String = "New Song"
## Name of the artist.
var artist_name : String = ""
## Difficulty of the song (0 for [code]easy[/code], 3 for [code]extreme[/code]).
var difficulty : int = 0
## The map that the song plays on (0 = volcano, 1 = desert, 2 = storm).
var map : int = 0
## The Beats Per Minute of the song.
var bpm : float = 60.0
## How many beats are in each bar.
var snapping_frequency : int = 4
## Offset for the audio.
var audio_offset : float = 0
## Checks if another window is focused, this gets set from [code]ui_controller.gd[/code].
var is_another_window_focused : bool = false #ui_controller.gd -> check_for_window_focused()
## The current hovered note.
var current_hovered_note : InternalNote
## The current selected notes.
var current_selected_notes : Array[InternalNote]
## The current copied notes.
var current_copied_notes : Array[Dictionary]
## The lane that the mouse is currently in.
var current_lane : int
## Gets automatically set in [code]cursor_note.gd[/code].
var cursor_note : Sprite2D #<- cursor_note.gd _ready()
## The sprite of the note.
var note_sprite : Resource = preload("res://Assets/Sprites/Notes.png")
## The sprite of the marker.
var marker_sprite : Resource = preload("res://Assets/Sprites/BPMMarker.png")
## The undo actions Array.
var undo_actions : Array[Action] = []
## The redo actions Array.
var redo_actions : Array[Action] = []
## The current bpm marker that we have passed.
var _current_bpm_marker : Marker

#region Getter/Setters
var seconds_per_measure : float :
	get:
		return 60 / (bpm / snapping_frequency)
	set(value):
		print("seconds_per_measure is being set, this is not intended.")

var seconds_per_beat : float :
	get:
		return seconds_per_measure / snapping_frequency
	set(value):
		print("seconds_per_beat is being set, this is not intended.")

var seconds_per_tick : float :
	get:
		return seconds_per_beat / snapping_frequency
	set(value):
		print("seconds_per_tick is being set, this is not intended.")

var current_beat : float :
	get:
		return (current_pos - _current_bpm_marker.time) / seconds_per_beat
	set(value):
		print("current_beat is being set, this is not intended.")

var current_measure : float :
	get:
		return current_beat / snapping_frequency
	set(value):
		print("current_measure is being set, this is not intended.")

## The speed of the notes.
var scroll_speed : int = 50 :
	set(value):
		scroll_speed = value
		Global.game_scene_node.queue_redraw()
		current_pos = current_pos

## The length of the song in seconds.
## By default the length is 60 seconds.
var audio_length : float = 60 :
	# Return length of audio, if audio empty return default value
	get:
		if(audio_player.stream != null):
			return audio_player.stream.get_length()
		else:
			return audio_length
 
## The current position in the song.
## Any time this gets set it'll move any note with it too.[br]
## [param _current_bpm_marker] also gets set depending on which [Marker] it has passed.
var current_pos : float = 0 :
	# Automatically move the notes whenever we play the position
	set(value):
		current_pos = value
		for marker : Marker in NoteManager.marker_nodes:
			if(marker.time <= value):
				_current_bpm_marker = marker
				bpm = marker.bpm
				snapping_frequency = marker.snapping
			NoteManager.play_notes(marker, current_pos)
			marker.queue_redraw()
		for note : Note in NoteManager.note_nodes:
			NoteManager.play_notes(note, current_pos)
			note.queue_redraw()
		Global.game_scene_node.queue_redraw()

## If any change has been made to the project then give warnings if it hasn't been saved yet.
var project_changed : bool :
	get:
		return project_changed
	set(value):
		if(value != project_changed):
			var file : FileAccess = FileAccess.open("user://closedproperly",FileAccess.WRITE)
			file.close()
			project_changed = value
			project_was_changed.emit(value)
#endregion


func _ready() -> void:
	# Setting up translation strings for auto generation
	tr("UNDO")
	tr("REDO")
	get_tree().current_scene.ready.connect(_on_scenetree_ready)


func _on_scenetree_ready() -> void:
	if FileAccess.file_exists("user://closedproperly"):
		var current_autosave : int = 0
		var config : ConfigFile = ConfigFile.new()
		
		# Check for errors
		var err : Error = config.load("user://settings.cfg")
		if err != OK:
			printerr(err)
			return
			
		if(config.has_section_key("autosave","currentAutosave")):
			current_autosave = int(config.get_value("autosave","currentAutosave"))
			
			# The last save was not an auto save so ask to load a normal save
			if current_autosave == 7:
				if(config.has_section_key("autosave","lastSave")):
					var last_save : String = str(config.get_value("autosave","lastSave"))
					Global.popup_dialog.play_dialog(tr("WINDOW_DIALOG_BADLYCLOSED_TITLE"),tr("WINDOW_DIALOG_BADLYCLOSED_TEXT") + " " + last_save,Global.file_manager.open_project.bind(last_save))
			else:
				var autosave_path : String = "user://autosave" + str(current_autosave) + ".json"
				
				Global.popup_dialog.play_dialog(tr("WINDOW_DIALOG_BADLYCLOSED_TITLE"),tr("WINDOW_DIALOG_BADLYCLOSED_TEXT") + " " + autosave_path,Global.file_manager.open_project.bind(autosave_path))


func _process(_delta : float) -> void:
	if(audio_player.playing):
		current_pos = (audio_player.get_playback_position()) + audio_offset / 100
	
	if(current_lane == 0 || is_another_window_focused || current_hovered_note != null || Global.multi_select.currently_dragging):
		cursor_note.visible = false
	else:
		cursor_note.position.y = NoteManager.reset_note_y(cursor_note, current_lane)
		
		if(current_lane == 7):
			cursor_note.texture = marker_sprite
		else:
			cursor_note.texture = note_sprite
			
		# Get the proper position of the cursor note
		var note_pos : Dictionary = _get_snapped_screen_and_time_pos(get_viewport().get_mouse_position())
		# If a double note does not exist at position or we are on the marker lane
		if(current_lane == 7 || !NoteManager.check_if_double_note_exists_at_time(note_pos["time_pos"])):
			cursor_note.visible = true
			cursor_note.position.x = note_pos["screen_pos"]


func _input(event : InputEvent) -> void:
	if(event is InputEventMouseButton):
		
		# If we are in any of the note lanes
		if(current_lane != 0):
			
			# Get snapped pos and time
			var new_pos : Dictionary = _get_snapped_screen_and_time_pos(get_viewport().get_mouse_position())
			
			# Check if note or marker already exists
			var note_exists: bool = NoteManager.check_if_note_exists(new_pos["time_pos"], current_lane)
			
			if(!is_another_window_focused):
				if(event.is_action_released("LeftClick") && !Global.multi_select.currently_dragging):
					
					# Check if note exists
					if(!note_exists && current_hovered_note == null):
						
						# Check if double note exists
						if(!NoteManager.check_if_double_note_exists_at_time(new_pos["time_pos"]) || current_lane == 7):
							var note : InternalNote = NoteManager.add_new_note(new_pos["time_pos"], current_lane)
							
							var new_action : NoteAction = make_note_actions(NoteAction.ActionName.NOTEADD,note)
							
							# Add action to the undo array
							add_undo_action(new_action)
								
					# If we are hovering over a note then set the note as the selected note
					if(current_hovered_note != null):
						if(!Input.is_key_pressed(KEY_SHIFT)):
							deselect_all_notes()
							select_note(current_hovered_note)
						else:
							if(current_hovered_note.selected):
								deselect_note(current_hovered_note)
							else:
								select_note(current_hovered_note)
						
				if(event.is_action_released("RightClick") && !Global.multi_select.currently_dragging):
					
					# Unselect the selected note if we right click anywhere else in the scene
					if(!current_selected_notes.is_empty()):
						deselect_all_notes()
						
					# Remove the note if we are hovering over a note
					if(current_hovered_note != null):
						
						#Add action to the undo array
						var new_action : NoteAction = make_note_actions(NoteAction.ActionName.NOTEREMOVE,current_hovered_note)
						
						add_undo_action(new_action)
						
						NoteManager.remove_note_at_time(current_hovered_note)
						current_hovered_note = null
		
		if(!is_another_window_focused):
			if(event.is_action_pressed("ZoomIn")):
				scroll_speed += 1
				
			# Scroll up 1 tick
			elif(event.is_action_pressed("ScrollUp") && !audio_player.playing):
				current_pos += seconds_per_beat / snapping_frequency
				current_pos = get_closest_snap_value(current_pos)
				# Make sure we don't scroll past the end of the song
				if(current_pos > audio_length):
					current_pos = audio_length
			
				
			if(event.is_action_pressed("ZoomOut")):
				if(scroll_speed > 1):
					scroll_speed -= 1
					
			# Scroll down 1 tick
			elif(event.is_action_pressed("ScrollDown") && !audio_player.playing):
				
				# Check if we are on a marker, use the previous marker for the seconds_per_beat if we are
				var scroll_seconds_per_beat : float = seconds_per_beat
				for i : int in range(0,NoteManager.marker_nodes.size()):
					if(NoteManager.marker_nodes[i].time == current_pos):
						scroll_seconds_per_beat = 60 / NoteManager.marker_nodes[i-1].bpm
						break
				
				current_pos -= scroll_seconds_per_beat / snapping_frequency
				current_pos = get_closest_snap_value(current_pos)
				if(current_pos < 0):
					current_pos = 0


	if(!is_another_window_focused):
		if(event.is_action_pressed("Delete")):
			if(!current_selected_notes.is_empty()):
				var new_multi_action : MultiAction = MultiAction.new(Action.ActionName.MULTIACTION)
				
				var currently_selected_notes_size : int = current_selected_notes.size()
				
				for i : int in currently_selected_notes_size:
					var new_action : NoteAction = make_note_actions(NoteAction.ActionName.NOTEREMOVE,current_selected_notes[0])
						
					# If the array is bigger than 1 then add it to new_multi_action	
					if(currently_selected_notes_size > 1):
						new_multi_action.actions.append(new_action)
					else:
						add_undo_action(new_action)
						
					NoteManager.remove_note_at_time(current_selected_notes[0])
					
				if(currently_selected_notes_size > 1):
					add_undo_action(new_multi_action)
					
				current_selected_notes.clear()
				Global.notification_popup.play_notification(tr("NOTIFICATION_DELETE_MULTIPLE_NOTES"),0.5)
				
		if(event.is_action_pressed("TogglePlay")):
			# Reset note selected when playing the song
			if(!current_selected_notes.is_empty()):
				deselect_all_notes()
				
			# If we are playing, then stop the music and snap to the nearest beat
			if(audio_player.playing):
				_stop_music()
				current_pos = get_closest_snap_value(current_pos)
			else:
				# Hide all the notes that are behind the judgement line if we are going to play
				if(audio_player.stream != null):
					for i : Note in NoteManager.note_nodes:
						if(i.time < current_pos):
							i.disable_collision()
							i.visible = false
						else:
							continue
					_play_music()
					

func _shortcut_input(event: InputEvent) -> void:
	# Ctrl + C
	if(event.is_action_pressed("Copy")):
		current_copied_notes.clear()
		for note : InternalNote in current_selected_notes:
			var copy_note : Dictionary
			copy_note.time = note.time
			copy_note.color = note.color
			if(note.color == 7):
				# Default values for markers
				copy_note.bpm = note.bpm
				copy_note.snapping = note.snapping
				current_copied_notes.append(copy_note)
			else:
				copy_note.interval = note.interval
				copy_note.double_time = note.double_time
				current_copied_notes.append(copy_note)
		
		current_copied_notes.sort_custom(NoteManager.sort_ascending_time)
		Global.notification_popup.play_notification(tr("NOTIFICATION_COPIED_NOTES"),0.5)
	# Ctrl + V
	if(event.is_action_pressed("Paste")):
		if(current_copied_notes.size() > 0):
			# Make a new multi action.
			var new_multi_action : MultiAction = MultiAction.new(Action.ActionName.MULTIACTION)
			deselect_all_notes()
			
			# Get the time positiion at the mouse. This is where it pastes the new notes.
			var mouse_pos : Dictionary = _get_snapped_screen_and_time_pos(get_viewport().get_mouse_position())
			var lowest_note : Dictionary = NoteManager.get_lowest_note_time_in_array(current_copied_notes)
			var highest_note : Dictionary = NoteManager.get_highest_note_time_in_array(current_copied_notes)
			
			# The delta of the lowest note. This gets added to the new notes.
			var lowest_note_delta : float = mouse_pos["time_pos"] - lowest_note.time
			
			var existing_notes_array : Array[InternalNote] = NoteManager.get_notes_in_range(lowest_note.time + lowest_note_delta, highest_note.time + lowest_note_delta)
			
			for note : Dictionary in current_copied_notes:
				
				var new_note : InternalNote = NoteManager.add_new_note(note.time, note.color)
				
				new_note.time += lowest_note_delta
				
				if(new_note is Marker):
					new_note.bpm = note.bpm
					new_note.snapping = note.snapping
				if(new_note is Note):
					new_note.interval = note.interval
					new_note.double_time = note.double_time
				
				var new_action : NoteAction = make_note_actions(Action.ActionName.NOTEADD,new_note)
				
				# If the array is bigger than 1 then add it to new_multi_action.
				if(current_copied_notes.size() > 1 || existing_notes_array.size() > 0):
					new_multi_action.actions.append(new_action)
				else:
					add_undo_action(new_action)
				
				# Select the new note
				select_note(new_note)
				
			if(existing_notes_array.size() > 0):
				for note : InternalNote in existing_notes_array:
					
					var new_delete_action : NoteAction = make_note_actions(Action.ActionName.NOTEREMOVE,note)
					new_multi_action.actions.append(new_delete_action)
					
					NoteManager.remove_note_at_time(note)
				
			if(current_copied_notes.size() > 1):
				add_undo_action(new_multi_action)
				
			GameManager.current_pos = GameManager.current_pos
			Global.notification_popup.play_notification(tr("NOTIFICATION_PASTED_NOTES"),0.5)
		
	# Ctrl + Y
	if(event.is_action_pressed("Redo")):
		if(redo_actions.size() != 0):
			run_action(redo_actions.pop_back())
		return
	# Ctrl + Z
	if(event.is_action_pressed("Undo")):
		if(undo_actions.size() != 0):
			run_action(undo_actions.pop_back())
		return


func _notification(what : int) -> void:
	# Warn before exiting the program if we have not saved
	if(what == NOTIFICATION_WM_CLOSE_REQUEST):
		Global.file_manager.save_settings()
		if(project_changed):
			Global.popup_dialog.play_dialog(tr("WINDOW_DIALOG_NOTSAVED_TITLE"),tr("WINDOW_DIALOG_NOTSAVED_EXIT"),_quit_game)
		else:
			_quit_game()

func _quit_game() -> void:
	DirAccess.remove_absolute("user://closedproperly")
	get_tree().quit()

#region Project setup
## Set up a project using the provided [param jsonString]
func setup_project(jsonString : Dictionary) -> void:
	# Setup metadata, audio and all the notes
	var metadata : Dictionary = jsonString["metaData"][0]
	song_name = metadata["songName"]
	artist_name = metadata["artistName"]
	difficulty = metadata["difficulty"]
	map = metadata["map"]
	Global.file_manager.song_file = metadata["songFile"]
	Global.file_manager.preview_file = metadata["previewFile"]
	Global.file_manager.folder_name = metadata["folderName"]
	NoteManager.clear_all_notes()
	NoteManager.initialise_marker(jsonString["marker"])
	NoteManager.initialise_notes(jsonString["notes"])
	current_pos = 0


## Set up the [AudioStreamPlayer] using the provided path
func setup_audio(audio_file : String) -> void:
	# Remove the audio if the song file is blank
	if audio_file == "":
		audio_player.stream = null
	else:
		audio_player.stream = AudioStreamOggVorbis.load_from_file(audio_file)
		current_pos = 0


## Reset the entire project and set all the values to default
func clean_project() -> void:
	setup_audio("")
	NoteManager.clear_all_notes()
	song_name = ""
	artist_name = ""
	difficulty = 0
	map = 0
	Global.file_manager.song_file = ""
	Global.file_manager.preview_file = ""
	Global.file_manager.project_file = ""
	Global.file_manager.folder_name = ""
	bpm = 60.0
	
	current_pos = 0
	NoteManager.add_new_note(0,7)
	undo_actions.clear()
	redo_actions.clear()
	project_changed = false
	Global.notification_popup.play_notification(tr("NOTIFICATION_PROJECT_RESET"), 0.5)
#endregion


#region Music time related functions
## Get the location of the note using [param time]
func music_time_to_screen_time(time : float) -> float:
	var percentage_elapsed : float = 0.0
	if time > 0:
		percentage_elapsed = time * scroll_speed / 100

	return percentage_elapsed * DisplayServer.window_get_size().x


## Convert the location on screen to a time in the song
func screen_time_to_music_time(location : float) -> float:
	# Like previous function but in reverse
	return (location / DisplayServer.window_get_size().x) / scroll_speed * 100


## Get the closest snapped value using [param time]
func get_closest_snap_value(time : float) -> float:
	var start_time : float = 0
	var snap_bpm : float = 60
	var snap_snapping_frequency : int = 4

	if(NoteManager.marker_nodes.size() != 0):
		for marker : Marker in NoteManager.marker_nodes:
				if(marker.time <= time):
					start_time = marker.time
					snap_bpm = marker.bpm
					snap_snapping_frequency = marker.snapping
					
	var beat_duration : float = 60 / snap_bpm / snap_snapping_frequency
	var relative_pos : float = time - start_time
	var closest_beat : int = round(relative_pos / beat_duration)
	var before_snap : float = start_time + closest_beat * beat_duration
	return before_snap
#endregion


#region undo/redo functions
## Add an undo action to the array and clear the redo array
func add_undo_action(action : Action) -> void:
	undo_actions.append(action)
	redo_actions.clear()


## Add a redo action to the array
func add_redo_action(action : Action) -> void:
	redo_actions.append(action)


## Run an undo/redo [Action]
func run_action(action : Action, add_to_undo_redo : bool = true) -> Action:
	var new_action : Action
	match action.action_name:
		# The action was an add so remove the note
		Action.ActionName.NOTEADD:
			# Get the old note
			var old_note : InternalNote = NoteManager.get_note_at_time(action.time, action.color)
			
			# Make new action for undo/redo
			new_action = NoteAction.new(Action.ActionName.NOTEREMOVE)
			new_action.time = old_note.time
			new_action.color = old_note.color
			
			if(old_note is Note):
				new_action.interval = action.interval
				new_action.double_time = action.double_time
			if(old_note is Marker):
				new_action.bpm = old_note.bpm
				new_action.snapping = old_note.snapping
			
			# Run reverse of action
			NoteManager.remove_note_at_time(old_note)
			Global.notification_popup.play_notification(tr("NOTIFICATION_{ACTION}_NOTE_AT_{TIME}","Use {ACTION} for undo/redo and {TIME} for time")
			.format({ACTION = tr(str(Action.ActionType.keys()[action.action_type])),TIME = str(snapped(action.time,0.01))}), 1)
			
		# The action was a remove so add the note
		Action.ActionName.NOTEREMOVE:
			# Run reverse of action and return note
			var new_note : InternalNote = NoteManager.add_new_note(action.time, action.color)
			#Set the old values back
			if(new_note is Note):
				new_note.interval = action.interval
				new_note.double_time = action.double_time
			if(new_note is Marker):
				new_note.bpm = action.bpm
				new_note.snapping = action.snapping
			
			# Make new action for undo/redo
			new_action = NoteAction.new(Action.ActionName.NOTEADD)
			new_action.time = action.time
			new_action.color = action.color
			
			Global.notification_popup.play_notification(tr("NOTIFICATION_{ACTION}_NOTE_AT_{TIME}","Use {ACTION} for undo/redo and {TIME} for time")
			.format({ACTION = tr(str(Action.ActionType.keys()[action.action_type])),TIME = str(snapped(action.time,0.01))}), 1)
			
		# The action was a value changed
		Action.ActionName.VALUECHANGED:
			# Create new action
			new_action = ValueAction.new(Action.ActionName.VALUECHANGED)
			new_action.time = action.time
			new_action.color = action.color
			var note : InternalNote = NoteManager.get_note_at_time(action.time,action.color)
			
			match action.value_type:
				ValueAction.ValueType.INTERVAL:
					new_action.old_value = note.interval
					new_action.value_type = ValueAction.ValueType.INTERVAL
					
					note.interval = int(action.old_value)
					
				ValueAction.ValueType.BPM:
					new_action.old_value = note.bpm
					new_action.value_type = ValueAction.ValueType.BPM
					
					note.bpm = float(action.old_value)
					
				ValueAction.ValueType.SNAPPING:
					new_action.old_value = note.snapping
					
					note.snapping = int(action.old_value)
					new_action.value_type = ValueAction.ValueType.SNAPPING
					
				ValueAction.ValueType.DOUBLETIME:
					new_action.old_value = note.double_time
					
					note.double_time = action.old_value
					new_action.value_type = ValueAction.ValueType.DOUBLETIME
				
			Global.game_scene_node.queue_redraw()
			
			Global.notification_popup.play_notification(
				tr("NOTIFICATION_{ACTION}_NOTE_VALUECHANGED_AT_{TIME}_TO_{VALUE}",
				"{ACTION} is undo/redo, {TIME} is song time and {VALUE} is the value it has changed to")
			.format	(
				{
					ACTION = tr(str(Action.ActionType.keys()[action.action_type])),
					TIME = str(snapped(action.time,0.01)),
					VALUE = str(action.old_value)
				}), 1)
			
		
		Action.ActionName.MULTIACTION:
			new_action = MultiAction.new(Action.ActionName.MULTIACTION)
			for multi_action : Action in action.actions:
				new_action.actions.append(run_action(multi_action, false))
			Global.notification_popup.play_notification(tr("NOTIFICATION_{ACTION}_MULTIPLE_NOTES", "{ACTION} is undo/redo").format({ACTION = tr(str(Action.ActionType.keys()[action.action_type]))}), 1)
				
	match action.action_type:
			action.ActionType.UNDO:
				new_action.action_type = Action.ActionType.REDO
				if(add_to_undo_redo):
					redo_actions.append(new_action)
			action.ActionType.REDO:
				new_action.action_type = Action.ActionType.UNDO
				if(add_to_undo_redo):
					undo_actions.append(new_action)
	return new_action

## Easier way to make a new [Action] using [InternalNote]
func make_note_actions(action_name : Action.ActionName, note : InternalNote) -> Action:
	var new_action : NoteAction = NoteAction.new(action_name)
	new_action.time = note.time
	new_action.color = note.color
	if(note is Note):
		new_action.interval = note.interval
		new_action.double_time = note.double_time
	if(note is Marker):
		new_action.bpm = note.bpm
		new_action.snapping = note.snapping
	return new_action
#endregion

## Add note to the [member current_selected_notes] array and emit [signal note_selected]
func select_note(note : InternalNote) -> void:
	current_selected_notes.append(note)
	note.select_note()
	note_selected.emit(current_selected_notes)


## Duplicates [param notes], sets it as the [member current_selected_notes] and emit [signal note_selected]
func select_multiple_notes(notes : Array[InternalNote]) -> void:
	if(!Input.is_key_pressed(KEY_SHIFT)):
		current_selected_notes.clear()
	for note : InternalNote in notes:
		note.select_note()
		current_selected_notes.append(note)
	note_selected.emit(current_selected_notes)


## Deselects a note
func deselect_note(note : InternalNote) -> void:
	note.deselect_note()
	current_selected_notes.erase(note)
	if(current_selected_notes.size() <= 0):
		note_deselected.emit()
	else:
		note_selected.emit(current_selected_notes)


## clears [member current_selected_notes] and emit [signal note_deselected]
func deselect_all_notes() -> void:
	for note : InternalNote in current_selected_notes:
		note.deselect_note()
	current_selected_notes.clear()
	note_deselected.emit()


## Play the music
func _play_music() -> void:
	audio_player.play(current_pos)
	Global.notification_popup.play_notification(tr("NOTIFICATION_MUSIC_PLAYING"), 0.5)


## Stop the music
func _stop_music() -> void:
	current_pos = audio_player.get_playback_position()
	audio_player.stop()
	current_pos = current_pos
	Global.notification_popup.play_notification(tr("NOTIFICATION_MUSIC_STOPPED"), 0.5)


## Get the snapped value of the screen and time position based on screen position
func _get_snapped_screen_and_time_pos(pos : Vector2) -> Dictionary:
	# Get the right music time and position based on screen position
	var offset_pos : float = pos.x - NoteManager.offset
	var music_time : float = get_closest_snap_value(screen_time_to_music_time(offset_pos) + current_pos)
	var snapped_pos : float = music_time_to_screen_time(music_time - current_pos) + NoteManager.offset
	return {"screen_pos": snapped_pos,"time_pos":music_time}
