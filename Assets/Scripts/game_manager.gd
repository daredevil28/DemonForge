#Singleton for managing everything related to the game
extends Node

#Audio player gets automatically set as soon as the audioplayer enters the scene tree
var audio_player : AudioStreamPlayer

#Audio file properties
var song_name : String = ""
var artist_name : String = ""
var difficulty : int = 0
var map : int = 0
var bpm : float = 60.0
var snapping_frequency : int = 4
var audio_offset : float = 0

var is_another_window_focused : bool = false #ui_controller.gd -> check_for_window_focused()

#If any change has been made to the project then give warnings if it hasn't been saved yet
var project_changed : bool

var current_hovered_note : InternalNote
var current_selected_note : InternalNote
var current_lane : int

var current_bpm_marker : Marker

var cursor_note : Sprite2D #<- cursor_note.gd _ready()
var note_sprite : Resource = load("res://Assets/Sprites/Notes.png")
var marker_sprite : Resource = load("res://Assets/Sprites/BPMMarker.png")

var undo_actions : Array[Action] = []
var redo_actions : Array[Action] = []

signal errors_found(errors : String)
signal note_selected(note : InternalNote)
signal note_deselected(note : InternalNote)

#region Getter/Setters
var seconds_per_measure : float :
	get:
		return 60 / (bpm / snapping_frequency)

var seconds_per_beat : float :
	get:
		return seconds_per_measure / snapping_frequency
		
var current_beat : int :
	get:
		return (current_pos - current_bpm_marker.time) / seconds_per_beat

var current_measure : int :
	get:
		return current_beat / snapping_frequency

var scroll_speed : int = 50 :
	set(value):
		scroll_speed = value
		redraw_scene()
		current_pos = current_pos

var audio_length : float = 60 :
	#Return length of audio, if audio empty return default value
	get:
		if(audio_player.stream != null):
			return audio_player.stream.get_length()
		else:
			return audio_length

var current_pos : float = 0 :
	#Automatically move the notes whenever we play the position
	set(value):
		current_pos = value
		for marker : Marker in NoteManager.marker_nodes:
			if(marker.time <= value):
				current_bpm_marker = marker
				bpm = marker.bpm
				snapping_frequency = marker.snapping
			NoteManager.play_notes(marker, current_pos)
		for note : Note in NoteManager.note_nodes:
			NoteManager.play_notes(note, current_pos)
#endregion

#region Project setup
func setup_project(jsonString : Dictionary) -> void:
	#Setup metadata, audio and all the notes
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

func setup_audio(audio_file : String) -> void:
	#Remove the audio if the song file is blank
	if audio_file == "":
		audio_player.stream = null
	else:
		audio_player.stream = AudioStreamOggVorbis.load_from_file(Global.file_manager.song_file)
		current_pos = 0

func clean_project() -> void:
	setup_audio("")
	NoteManager.clear_all_notes()
	song_name = ""
	artist_name = ""
	difficulty = 0
	map = 0
	Global.file_manager.song_file = ""
	Global.file_manager.preview_file = ""
	bpm = 60.0

	current_pos = 0
	NoteManager.add_new_note(0,7)
	undo_actions.clear()
	redo_actions.clear()
	Global.notification_popup.play_notification("Project has been reset!", 0.5)
#endregion

func play_music() -> void:
	audio_player.play(current_pos)
	Global.notification_popup.play_notification("Music playing", 0.5)

func stop_music() -> void:
	current_pos = audio_player.get_playback_position()
	audio_player.stop()
	Global.notification_popup.play_notification("Music stopped", 0.5)

func redraw_scene() -> void:
	Global.game_scene_node.queue_redraw()
	
#region Music time related functions
func music_time_to_screen_time(time : float) -> float:
	#Get the location of the note based on how long the song is and the width of the window
	var percentage_elapsed : float = 0.0
	if time > 0:
		percentage_elapsed = time / audio_length

	return percentage_elapsed * DisplayServer.window_get_size().x * scroll_speed

func screen_time_to_music_time(location : float) -> float:
	#Like previous function but in reverse
	return location / DisplayServer.window_get_size().x * audio_length / scroll_speed

func get_closest_snap_value(music_pos : float) -> float:
	var start_time : float = 0
	if(NoteManager.marker_nodes.size() != 0):
		var bpm : int
		var snapping_frequency : int
		for marker : Marker in NoteManager.marker_nodes:
				if(marker.time <= music_pos):
					start_time = marker.time
					bpm = marker.bpm
					snapping_frequency = marker.snapping
					
	var beat_duration : float = 60 / bpm / snapping_frequency
	var relative_pos : float = music_pos - start_time
	var closest_beat : int = round(relative_pos / beat_duration)
	var before_snap : float = start_time + closest_beat * beat_duration
	return before_snap

func mouse_snapped_screen_pos(pos : Vector2) -> Dictionary:
	#Get the right music time and position based on screen position
	var offset_pos : float = pos.x - NoteManager.offset
	var music_time : float = get_closest_snap_value(screen_time_to_music_time(offset_pos) + current_pos)
	var snapped_pos : float = music_time_to_screen_time(music_time - current_pos) + NoteManager.offset
	return {"screen_pos": snapped_pos,"time_pos":music_time}
#endregion

#region undo/redo functions
func add_undo_action(action : Action) -> void:
	undo_actions.append(action)
	redo_actions.clear()
	
func add_redo_action(action : Action) -> void:
	redo_actions.append(action)
	
func run_action(action : Action) -> void:
	var new_action : Action
	match action.action_name:
		# The action was an add so remove the note
		Action.ActionName.NOTEADD:
			#Get the old note
			var old_note : InternalNote = NoteManager.get_note_at_time(action.time, action.color)
			
			#Make new action for undo/redo
			new_action = NoteAction.new(Action.ActionName.NOTEREMOVE)
			new_action.time = old_note.time
			new_action.color = old_note.color
			if(old_note is Note):
				new_action.interval = action.interval
			if(old_note is Marker):
				new_action.bpm = old_note.bpm
				new_action.snapping = old_note.snapping
			
			#Run reverse of action
			NoteManager.remove_note_at_time(action.time, action.color)
			
			Global.notification_popup.play_notification(str(Action.ActionType.keys()[action.action_type]) + " note at " + str(snapped(action.time,0.01)), 1)
			
		# The action was a remove so add the note
		Action.ActionName.NOTEREMOVE:
			#Run reverse of action and return note
			var new_note : InternalNote = NoteManager.add_new_note(action.time, action.color)
			#Set the old values back
			if(new_note is Note):
				new_note.interval = action.interval
			if(new_note is Marker):
				new_note.bpm = action.bpm
				new_note.snapping = action.snapping
			
			#Make new action for undo/redo
			new_action = NoteAction.new(Action.ActionName.NOTEADD)
			new_action.time = action.time
			new_action.color = action.color
			
			Global.notification_popup.play_notification(str(Action.ActionType.keys()[action.action_type]) + " note at " + str(snapped(action.time,0.01)), 1)
			
		# The action was a value changed
		Action.ActionName.VALUECHANGED:
			#Create new action
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
				
			GameManager.redraw_scene()
			Global.notification_popup.play_notification(str(Action.ActionType.keys()[action.action_type]) +
			" " + str(ValueAction.ValueType.keys()[new_action.value_type]) +
			" to " + str(action.old_value) +
			" at " + str(snapped(action.time,0.01)), 1)
		
	if(action.action_type == action.ActionType.UNDO):
		new_action.action_type = Action.ActionType.REDO
		redo_actions.append(new_action)
		
	elif(action.action_type == action.ActionType.REDO):
		undo_actions.append(new_action)
#endregion

func check_for_errors() -> String:
	#Check for errors before exporting the project
	var errors : String = ""
	if(GameManager.song_name == ""):
		errors += "No song name set\n"
	if(GameManager.artist_name == ""):
		errors += "Artist name not set\n"
	if(Global.file_manager.song_file == ""):
		errors += "No song file specified\n"
	if(Global.file_manager.preview_file == ""):
		errors += "No preview file specified\n"
	if(Global.file_manager.folder_name == ""):
		errors += "Folder name not specified\n"
	if(Global.file_manager.custom_songs_folder == ""):
		errors += "Custom songs folder not set\n"
	return errors
	
func _process(_delta : float) -> void:
	if(audio_player.playing):
		current_pos = (audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()) + audio_offset / 100
	
	if current_lane == 0 || is_another_window_focused || current_hovered_note != null:
		cursor_note.visible = false
	else:
		cursor_note.position.y = NoteManager.reset_note_y(cursor_note, current_lane)
		
		if(current_lane == 7):
			cursor_note.texture = marker_sprite
		else:
			cursor_note.texture = note_sprite
			
		#Get the proper position of the cursor note
		var note_pos : Dictionary = mouse_snapped_screen_pos(get_viewport().get_mouse_position())
		#If a double note does not exist at position or we are on the marker lane
		if(current_lane == 7 || !NoteManager.check_if_double_note_exists_at_time(note_pos["time_pos"])):
			cursor_note.visible = true
			cursor_note.position.x = note_pos["screen_pos"]

func _input(event : InputEvent) -> void:
	if(event is InputEventMouseButton):
		#TODO replace with the proper seconds_per_beat
		var seconds_per_beat : float = 60 / bpm
		
		#If we are in any of the note lanes
		if(current_lane != 0):
			
			#Get snapped pos and time
			var new_pos : Dictionary = mouse_snapped_screen_pos(get_viewport().get_mouse_position())
			
			#Check if note or marker already exists
			var note_exists: bool = NoteManager.check_if_note_exists_at_mouse_location(new_pos["time_pos"], current_lane)
			if(!is_another_window_focused):
				if(event.is_action_pressed("LeftClick")):
					
					#Check if note exists
					if(!note_exists && current_hovered_note == null):
						
						#Check if double note exists
						if(!NoteManager.check_if_double_note_exists_at_time(new_pos["time_pos"]) || current_lane == 7):
							NoteManager.add_new_note(new_pos["time_pos"], current_lane)
							
							#Add action to the undo array
							var new_action : NoteAction = NoteAction.new(Action.ActionName.NOTEADD)
							new_action.time = new_pos["time_pos"]
							new_action.color = current_lane
							add_undo_action(new_action)
								
					#If we are hovering over a note then set the note as the selected note
					if(current_hovered_note != null):
						current_selected_note = current_hovered_note
						note_selected.emit(current_selected_note)
						
				if(event.is_action_pressed("RightClick")):
					
					#Unselect the selected note if we right click anywhere else in the scene
					if(current_selected_note != null):
						note_deselected.emit(current_selected_note)
						current_selected_note = null
						
					#Remove the note if we are hovering over a note
					if(current_hovered_note != null):
						
						#Add action to the undo array
						var new_action : NoteAction = NoteAction.new(Action.ActionName.NOTEREMOVE)
						new_action.time = current_hovered_note.time
						new_action.color = current_hovered_note.color
						if(current_hovered_note is Note):
							new_action.interval = current_hovered_note.interval
						if(current_hovered_note is Marker):
							new_action.bpm = current_hovered_note.bpm
							new_action.snapping = current_hovered_note.snapping
						add_undo_action(new_action)
						
						NoteManager.remove_note_at_time(current_hovered_note.time, current_hovered_note.color)
						current_hovered_note = null
					
		#Scroll up 1 tick
		if(event.is_action_pressed("ScrollUp") && !audio_player.playing && !is_another_window_focused):
			current_pos += seconds_per_beat / snapping_frequency
			current_pos = get_closest_snap_value(current_pos)
			if current_pos > audio_length:
				current_pos = audio_length
				
		#Scroll down 1 tick
		if(event.is_action_pressed("ScrollDown") && !audio_player.playing && !is_another_window_focused):
			
			#Check if we are on a marker, use the previous marker for the seconds_per_beat if we are
			for i : int in range(0,NoteManager.marker_nodes.size()):
				if(NoteManager.marker_nodes[i].time == current_pos):
					seconds_per_beat = 60 / NoteManager.marker_nodes[i-1].bpm
					break
			
			current_pos -= seconds_per_beat / snapping_frequency
			current_pos = get_closest_snap_value(current_pos)
			if(current_pos < 0):
				current_pos = 0

	if(event.is_action_pressed("TogglePlay") && is_another_window_focused == false):
		
		#If we are playing, then stop the music and snap to the nearest beat
		if(audio_player.playing):
			stop_music()
			current_pos = get_closest_snap_value(current_pos)
		else:
			#Hide all the notes that are behind the judgement line if we are going to play
			if(audio_player.stream != null):
				
				for i : Note in NoteManager.note_nodes:
					if(i.time < current_pos):
						i.disable_collision()
						i.visible = false
					else:
						continue
				play_music()

func _shortcut_input(event: InputEvent) -> void:
	#Ctrl + Y
	if(event.is_action_pressed("Redo")):
		if(redo_actions.size() != 0):
			run_action(redo_actions.pop_back())
		return
	#Ctrl + Z
	if(event.is_action_pressed("Undo")):
		if(undo_actions.size() != 0):
			run_action(undo_actions.pop_back())
		return

func _notification(what: int) -> void:
	#Warn before exiting the program if we have not saved
	if(what == NOTIFICATION_WM_CLOSE_REQUEST):
		Global.file_manager.save_settings()
		if(project_changed):
			Global.popup_dialog.play_dialog("Project not saved!","The current project has not been saved, are you sure you want to exit?",get_tree().quit)
		else:
			get_tree().quit()
