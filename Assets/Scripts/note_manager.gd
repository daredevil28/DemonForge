extends Node
## Singleton for managing everything related to notes.
##
## Does everything related to finding notes and moving the notes.

## Array containing all the different notes.
var note_nodes : Array[Note] = []
## Array containing all the different markers.
var marker_nodes : Array[Marker] = []
## The specific note scene that is used for instantiating notes.
var note_scene : Resource = preload("res://Assets/Scenes/note.tscn")
## The specific marker scene that is used for instantiating markers.
var marker_scene : Resource = preload("res://Assets/Scenes/bpm_marker.tscn")
## The offset used for the judgement line and the notes.
var offset : int = 200 :
	#Whenever offset changes, redraw the scene
	set(value):
		offset = value
		Global.game_scene_node.queue_redraw()
## Gets the note lane group as an array. For resetting size whenever window is resized.
@onready var note_lanes : Array = get_tree().get_nodes_in_group("NodeLanes")


func _ready() -> void:
	# Reset the notes whenever the window is resized
	get_viewport().size_changed.connect(reset_note_location)
	# Reset width of colliders
	for i : Node in note_lanes:
		reset_collision_location(i, i.note_color)


## Moves the notes on the screen according to time.[br]
## Takes [InternalNote] and [param time] as argument.
func play_notes(object : InternalNote, new_time : float) -> void:
	# (NoteTimestamp - TimePassed ) + offset
	var new_pos : float = (GameManager.music_time_to_screen_time(object.time) - GameManager.music_time_to_screen_time(new_time)) + offset
	
	# Check if the note is outside the frame, hide and skip if it is
	if(new_pos > DisplayServer.window_get_size().x + 20 || new_pos < -20):
		object.visible = false
		object.disable_collision()
		return
		
	if(GameManager.audio_player.playing):
		
		# If the note is ahead of the judgement line
		if(object.time >= new_time):
			
			# If it's not visible then make it visible
			if(!object.visible):
				object.visible = true
				
			# Update position of the note
			object.position.x = new_pos
			
		else:
			# Note is on or has passed the judgement line
			if(object.visible):
				
				# Make sure the note is actually close enough to the bar before playing the sound
				if(object.time >= GameManager.current_pos - 0.02 || new_pos < offset):
					object.disable_collision()
					if(object.color != 7):
						var seconds_per_tick : float = GameManager.seconds_per_tick
						if(object.double_time == true):
							seconds_per_tick = seconds_per_tick / 2
						get_tree().get_nodes_in_group("Instruments")[object.color - 1].play_instrument(object.interval, seconds_per_tick)
					object.visible = false
	else:
		# No audio is playing so make every note behind the judgement line visible
		object.position.x = new_pos
		object.enable_collision()
		if(!object.visible):
			object.visible = true


#region Note manipulation
## Set up all the notes using array.[br]
## Expects an [Array] with [param time], [param color] and [param interval].
func initialise_notes(json_notes : Array) -> void:
	# Instantiate all the notes
	for i : int in json_notes.size():
		# Make a new note dictionary, instantiate it and add it to NoteManager as a child
		var note : Dictionary = json_notes[i]
		var instance : Note = note_scene.instantiate()
		add_child(instance)
		
		#Set up the properties
		instance.time = note["time"]
		instance.color = note["color"]
		instance.interval = note["interval"]
		if(note.has("double_time")):
			instance.double_time = note["double_time"]
		instance.position.y = reset_note_y(instance, note["color"])
		note_nodes.append(instance)
		
	GameManager.current_pos = 0
	
	# If the array is not empty then use the last note as the audio length temporarily
	if(!note_nodes.is_empty()):
		GameManager.audio_length = note_nodes.back().time


## Sets up all the markers using the array.[br]
## Expects an [Array] with [param time], [param bpm] and [param snapping].
func initialise_marker(json_markers : Array) -> void:
	# Instantiate all the markers (Similar to initialise_notes but for markers)
	for i : int in json_markers.size():
		var marker : Dictionary = json_markers[i]
		var instance : Marker = marker_scene.instantiate()
		add_child(instance)
		
		instance.time = marker["time"]
		instance.bpm = marker["bpm"]
		instance.snapping = marker["snapping"]
		instance.position.y = get_note_lane_y(7)
		marker_nodes.append(instance)


## Uses [param note_nodes], [param marker_nodes] and [param note_lanes] and resets their locations.
func reset_note_location() -> void:
	# Reset all the positions for the notes for whenever the screen resizes
	for note : Note in note_nodes:
		note.position.y = reset_note_y(note, note.color)
		
	for marker : Marker in marker_nodes:
		marker.position.y = reset_note_y(marker, 7)
		
	for i : Node in note_lanes:
		reset_collision_location(i, i.note_color)
	
	# Reset the X pos of the note
	GameManager.current_pos = GameManager.current_pos
	
	# Redraw the lines in drawer.gd
	Global.game_scene_node.queue_redraw()


## Returns the y position depending on [param color] and sets the color of the note.
func reset_note_y(instance : Node2D, color : int) -> float:
	# Reset the y pos of the note and adjust the color of the note
	var position : float
	position = get_note_lane_y(color)
	match color:
			1:
				instance.canvas_color = Color.YELLOW
			2:
				instance.canvas_color = Color.RED
			3:
				instance.canvas_color = Color.ORANGE
			4:
				instance.canvas_color = Color.PURPLE
			5:
				instance.canvas_color = Color.BLUE
			6:
				instance.canvas_color = Color.GREEN
			7:
				instance.canvas_color = Color.WHITE
			_:
				push_warning("No color found")
	return position


## Resets the position and size of a note_lane.
func reset_collision_location(instance : Node2D, color : int) -> void:
	# Reset the position and size of the note lanes to span across the screen size
	instance.position = DisplayServer.window_get_size() / 2
	instance.scale.x = DisplayServer.window_get_size().x / 2 / 10
	instance.scale.y = 0.0048 * DisplayServer.window_get_size().y
	instance.position.y = get_note_lane_y(color)


## Returns the proper y position based on the lane.
func get_note_lane_y(lane : int) -> float:
	match lane:
		1:
			return 0.55 * DisplayServer.window_get_size().y
		2:
			return 0.45 * DisplayServer.window_get_size().y
		3:
			return 0.75 * DisplayServer.window_get_size().y
		4:
			return 0.25 * DisplayServer.window_get_size().y
		5:
			return 0.65 * DisplayServer.window_get_size().y
		6:
			return 0.35 * DisplayServer.window_get_size().y
		7:
			return 0.15 * DisplayServer.window_get_size().y
		_:
			return 0


## Adds a new note. Returns [InternalNote].
func add_new_note(time : float, color : int) -> InternalNote:
	# Add a new note to the chart
	GameManager.project_changed = true
	var instance : InternalNote
	# If it is a marker
	if(color == 7):
		instance = marker_scene.instantiate()
		# Default values for markers
		instance.bpm = 100
		instance.snapping = 4
		instance.time = time
		marker_nodes.append(instance)
		# Some logic (snapping) depend on the order of the markers in the array
		marker_nodes.sort_custom(sort_ascending_time)
	else:
		instance = note_scene.instantiate()
		instance.color = color
		instance.time = time
		note_nodes.append(instance)
	
	add_child(instance)
	
	instance.position.y = reset_note_y(instance, color)
	# Reset the X pos of the note
	GameManager.current_pos = GameManager.current_pos
	
	return instance


## Removes the note using the [param time] and [param color].
func remove_note_at_time(time : float, color : int) -> void:
	# Remove a note from the chart at the specified time
	GameManager.project_changed = true
	var array : Array
	# If it's a marker then use the marker_nodes array, else the note_nodes array will be used
	if(color == 7):
		array = marker_nodes
	else:
		array = note_nodes
	
	for i : int in array.size():
		# If we find an exact time and color match then remove the note
		if(array[i].time == time && array[i].color == color):
			print("Deleting note at: " + str(time) + " color: " + str(color))
			array[i].queue_free()
			array.remove_at(i)
			# Redraw the scene for if we deleted a marker note
			Global.game_scene_node.queue_redraw()
			break;


## Gets the specific note at [param time] and [param color].
func get_note_at_time(time : float, color : int) -> Note:
	var array : Array
	
	if(color == 7):
		array = marker_nodes
	else:
		array = note_nodes
	
	for i : InternalNote in array:
		# If we find an exact time and color match then return the note
		if(i.time == time && i.color == color):
			return i
	return null


## Tool to snap all the note_nodes to the closest snapping value.
func snap_all_notes_to_nearest() -> void:
	for i : Note in note_nodes:
		i.time = GameManager.get_closest_snap_value(i.time)
	GameManager.current_pos = GameManager.current_pos


## Returns a [bool] if an [InternalNote] exists at [param time] and [param color].
func check_if_note_exists(time : float, color : int) -> bool:
	# If the note is a marker
	if(color == 7):
		for i : int in marker_nodes.size():
			if(marker_nodes[i].time == time && marker_nodes[i].color == color):
				return true
		return false
	# The note is a note
	for i : int in note_nodes.size():
		if(note_nodes[i].time == time && note_nodes[i].color == color):
			return true
	return false


## Returns a [bool] if 2 [Note] exists at [param time].
func check_if_double_note_exists_at_time(time : float) -> bool:
	# Drums Rock only supports 2 notes at the same time
	var note_count : int = 0
	# Go through the note array and add to note_count if we encounter the same note
	for note : Note in note_nodes:
		if(note.time == time):
				note_count += 1
		# If we counted 2 or more then there is a double note at the location
		if(note_count >= 2):
			return true
	return false


## Sorts all notes by [param time].
func sort_all_notes() -> void:
	note_nodes.sort_custom(sort_ascending_time)


func sort_ascending_time(a : InternalNote, b : InternalNote) -> bool:
	return(a.time < b.time)


func get_lowest_note_time_in_array(note_array : Array) -> InternalNote:
	var lowest_note : InternalNote = note_array[0]
	for note : InternalNote in note_array:
		if(note.time < lowest_note.time):
			lowest_note = note
	return lowest_note
	

## Removes all the [param note_nodes] and [param marker_nodes].
func clear_all_notes() -> void:
	print("clearing all notes")
	for i : Note in note_nodes:
		i.free()
	for i : Marker in marker_nodes:
		i.free()
	note_nodes.clear()
	marker_nodes.clear()
#endregion
