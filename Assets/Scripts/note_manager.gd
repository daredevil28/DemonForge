#Singleton for managing anything related to notes
extends Node

var note_nodes : Array[Note] = []

var yellow : Color = Color.YELLOW
var red : Color = Color.RED
var orange : Color = Color.ORANGE
var purple : Color = Color.PURPLE
var blue : Color = Color.BLUE
var green : Color = Color.GREEN

@onready var note_lanes : Array = get_tree().get_nodes_in_group("NodeLanes")
var note_scene : Resource = load("res://Assets/Scenes/note.tscn")

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
	clear_all_notes()
	
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

func reset_note_location() -> void:
	for i : Note in note_nodes:
		i.position.y = reset_note_y(i, i.color)
	for i : Node in note_lanes:
		reset_collision_location(i, i.note_color)
	play_notes(GameManager.current_pos)
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
		_:
			return 0

func add_new_note(time : float, color : int) -> void:
	GameManager.project_changed = true
	var instance : Note = note_scene.instantiate()
	
	add_child(instance)
	
	instance.time = time
	instance.color = color
	instance.position.y = reset_note_y(instance, color)
	note_nodes.append(instance)
	GameManager.current_pos = GameManager.current_pos

func remove_note_at_time(time : float, color : int) -> void:
	GameManager.project_changed = true
	for i : int in note_nodes.size():
		if(note_nodes[i].time == time && note_nodes[i].color == color):
			print("Deleting note at: " + str(time) + " color: " + str(color))
			note_nodes[i].queue_free()
			note_nodes.remove_at(i)
			break;

func check_if_note_exists_at_mouse_location(time : float, color : int) -> bool:
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
	note_nodes.clear()
#endregion
	
func play_notes(new_time : float) -> void:
	GameManager.redraw_scene()
	for i : Note in note_nodes:
		#(NoteTimestamp - TimePassed ) * scroll_speed + offset
		var new_pos : float = (GameManager.music_time_to_screen_time(i.time) - GameManager.music_time_to_screen_time(new_time)) + offset
		#Check if the note is outside the frame, hide and skip the iteration if we do
		if(new_pos > DisplayServer.window_get_size().x + 20 || new_pos < -20):
			i.visible = false
			i.disable_collision()
			continue
		if(GameManager.audio_player.playing):
			if (i.time >= new_time):
				if(!i.visible):
					i.visible = true
					i.enable_collision()
				i.position.x = new_pos
			else:
				if(i.visible):
					#Make sure the note is actually close enough to the bar before playing the sound
					if(i.time >= GameManager.current_pos - 0.02 || new_pos < offset):
						i.disable_collision()
						get_tree().get_nodes_in_group("Instruments")[i.color - 1].play()
						i.visible = false
		else:
			i.position.x = new_pos
			if(!i.visible):
				i.enable_collision()
				i.visible = true
