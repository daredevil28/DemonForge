#Singleton for managing anything related to notes
extends Node

var note_nodes : Array[Note] = []
var marker_nodes : Array[Marker] = []
var yellow : Color = Color.YELLOW
var red : Color = Color.RED
var orange : Color = Color.ORANGE
var purple : Color = Color.PURPLE
var blue : Color = Color.BLUE
var green : Color = Color.GREEN
var white : Color = Color.WHITE

@onready var note_lanes : Array = get_tree().get_nodes_in_group("NodeLanes")
var note_scene : Resource = load("res://Assets/Scenes/note.tscn")
var marker_scene : Resource = load("res://Assets/Scenes/bpm_marker.tscn")

var offset : int = 200 :
	set(value):
		offset = value
		GameManager.redraw_scene()

func _ready() -> void:
	#Reset the notes whenever the window is resized
	get_viewport().size_changed.connect(reset_note_location)
	#Reset width of colliders
	for i : Node in note_lanes:
		reset_collision_location(i, i.note_color)
	
#region Note manipulation
#Instantiate all the notes
func initialise_notes(json_notes : Array) -> void:
	
	for i : int in json_notes.size():
		var note : Dictionary = json_notes[i]
		var instance : Note = note_scene.instantiate()
		add_child(instance)
		
		instance.time = note["time"]
		instance.color = note["color"]
		instance.interval = note["interval"]
		instance.position.y = reset_note_y(instance, note["color"])
		instance.visible = false
		note_nodes.append(instance)
	GameManager.current_pos = 0
	if(!note_nodes.is_empty()):
		GameManager.audio_length = note_nodes.back().time

func initialise_bpm_marker(json_markers : Array) -> void:
	for i in json_markers.size():
		var marker : Dictionary = json_markers[i]
		var instance : Marker = marker_scene.instantiate()
		add_child(instance)
		
		instance.time = marker["time"]
		instance.bpm = marker["bpm"]
		instance.snapping = marker["snapping"]
		instance.position.y = get_note_lane_y(7)
		marker_nodes.append(instance)

func reset_note_location() -> void:
	for note : Note in note_nodes:
		note.position.y = reset_note_y(note, note.color)
	for marker : Marker in marker_nodes:
		marker.position.y = reset_note_y(marker, 7)
	for i : Node in note_lanes:
		reset_collision_location(i, i.note_color)
	GameManager.current_pos = GameManager.current_pos
	#Redraw the lines in drawer.gd
	GameManager.redraw_scene()

func reset_note_y(instance : Node2D, color : int) -> float:
	var position : float
	position = get_note_lane_y(color)
	match color:
			1:
				instance.canvas_color = yellow
			2:
				instance.canvas_color = red
			3:
				instance.canvas_color = orange
			4:
				instance.canvas_color = purple
			5:
				instance.canvas_color = blue
			6:
				instance.canvas_color = green
			7:
				instance.canvas_color = white
			_:
				push_warning("No color found")
	return position

func reset_collision_location(instance : Node2D, color : int) -> void:
	instance.position = DisplayServer.window_get_size() / 2
	@warning_ignore("integer_division")
	instance.scale.x = DisplayServer.window_get_size().x / 2 / 10
	instance.scale.y = 0.0048 * DisplayServer.window_get_size().y
	instance.position.y = get_note_lane_y(color)

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

func add_new_note(time : float, color : int) -> void:
	GameManager.project_changed = true
	var instance : Note
	if(color == 7):
		instance = marker_scene.instantiate()
		instance.bpm = 100
		instance.snapping = 4
		marker_nodes.append(instance)
		marker_nodes.sort_custom(sort_ascending_time)
	else:
		instance = note_scene.instantiate()
		instance.color = color
		note_nodes.append(instance)
	
	add_child(instance)
	
	instance.time = time
	instance.position.y = reset_note_y(instance, color)
	GameManager.current_pos = GameManager.current_pos

func remove_note_at_time(time : float, color : int) -> void:
	GameManager.project_changed = true
	var array : Array
	if(color == 7):
		array = marker_nodes
	else:
		array = note_nodes
	
	for i : int in array.size():
		if(array[i].time == time && array[i].color == color):
			print("Deleting note at: " + str(time) + " color: " + str(color))
			array[i].queue_free()
			array.remove_at(i)
			GameManager.redraw_scene()
			break;

func check_if_note_exists_at_mouse_location(time : float, color : int) -> bool:
	if(color == 7):
		for i : int in marker_nodes.size():
			if(marker_nodes[i].time == time && marker_nodes[i].color == color):
				return true
		return false
	for i : int in note_nodes.size():
		if(note_nodes[i].time == time && note_nodes[i].color == color):
			return true
	return false
	
func check_if_double_note_exists_at_time(time : float) -> bool:
	var note_count : int = 0
	for note : Note in note_nodes:
		if(note.time == time):
				note_count += 1
		if(note_count >= 2):
			return true
	return false

func sort_all_notes() -> void:
	note_nodes.sort_custom(sort_ascending_time)
	pass

func sort_ascending_time(a : Note, b : Note) -> bool:
	if(a["time"] < b["time"]):
		return true
	return false
	
func clear_all_notes() -> void:
	print("clearing all notes")
	for i : Note in note_nodes:
		i.free()
	for i : Note in marker_nodes:
		i.free()
	note_nodes.clear()
	marker_nodes.clear()
#endregion
	
func play_notes(object : Node2D, new_time : float) -> void:
	GameManager.redraw_scene()
	#(NoteTimestamp - TimePassed ) * scroll_speed + offset
	var new_pos : float = (GameManager.music_time_to_screen_time(object.time) - GameManager.music_time_to_screen_time(new_time)) + offset
	#Check if the note is outside the frame, hide and skip the iteration if we do
	if(new_pos > DisplayServer.window_get_size().x + 20 || new_pos < -20):
		object.visible = false
		object.disable_collision()
		return
	if(GameManager.audio_player.playing):
		if (object.time >= new_time):
			if(!object.visible):
				object.visible = true
				object.enable_collision()
			object.position.x = new_pos
		else:
			if(object.visible && object.color != 7):
				#Make sure the note is actually close enough to the bar before playing the sound
				if(object.time >= GameManager.current_pos - 0.02 || new_pos < offset):
					object.disable_collision()
					get_tree().get_nodes_in_group("Instruments")[object.color - 1].play()
					object.visible = false
	else:
		object.position.x = new_pos
		if(!object.visible):
			object.enable_collision()
			object.visible = true
