extends Node

var note_nodes : Array = []

var yellow : Color = Color.YELLOW
var red : Color = Color.RED
var orange : Color = Color.ORANGE
var purple : Color = Color.PURPLE
var blue : Color = Color.BLUE
var green : Color = Color.GREEN

var current_lane : int
var cursor_note : Node2D

@onready var note_colliders : Array = get_tree().get_nodes_in_group("NoteColliders")

var offset : float = 200 :
	set(value):
		offset = value
		GameManager.redraw_scene()

func _ready() -> void:
	#Reset the notes whenever the window is resized
	get_viewport().size_changed.connect(reset_note_location)
	#Reset width
	for i in note_colliders:
		reset_collision_location(i, i.note_color)
	
#region Note manipulation
#Instantiate all the notes
func initialise_notes(json_notes : Array) -> void:
	clear_all_notes()
	var note_scene : Resource = load("res://Assets/Scenes/note.tscn")
	
	for i : int in json_notes.size():
		var note : Dictionary = json_notes[i]
		var instance : Node = note_scene.instantiate()
		add_child(instance)
		
		instance.time = note["time"]
		instance.color = note["color"]
		instance.interval = note["interval"]
		instance.position.y = reset_note_y(instance, note["color"])
		note_nodes.append(instance)
	GameManager.current_pos = 0
	GameManager.audio_length = note_nodes.back().time

func reset_note_location() -> void:
	for i : Node2D in note_nodes:
		i.position.y = reset_note_y(i, i.color)
	for i in note_colliders:
		reset_collision_location(i, i.note_color)
	play_notes(GameManager.current_pos)
	#Redraw the lines in drawer.gd
	GameManager.redraw_scene()

func reset_note_y(instance : Node2D, color : int) -> float:
	var position : float
	match color:
			1:
				instance.modulate = yellow
				position = 0.55 * DisplayServer.window_get_size().y
			2:
				instance.modulate = red
				position = 0.45 * DisplayServer.window_get_size().y
			3:
				instance.modulate = orange
				position = 0.75 * DisplayServer.window_get_size().y
			4:
				instance.modulate = purple
				position = 0.25 * DisplayServer.window_get_size().y
			5:
				instance.modulate = blue
				position = 0.65 * DisplayServer.window_get_size().y
			6:
				instance.modulate = green
				position = 0.35 * DisplayServer.window_get_size().y
			_:
				push_warning("No color found")
	return position

func reset_collision_location(instance : Node2D, color : int) -> void:
	instance.position = DisplayServer.window_get_size() / 2
	instance.scale.x = DisplayServer.window_get_size().x / 2 / 10
	instance.scale.y = 0.004 * DisplayServer.window_get_size().y
	match color:
		1:
			instance.position.y = 0.55 * DisplayServer.window_get_size().y
		2:
			instance.position.y = 0.45 * DisplayServer.window_get_size().y
		3:
			instance.position.y = 0.75 * DisplayServer.window_get_size().y
		4:
			instance.position.y = 0.25 * DisplayServer.window_get_size().y
		5:
			instance.position.y = 0.65 * DisplayServer.window_get_size().y
		6:
			instance.position.y = 0.35 * DisplayServer.window_get_size().y
		_:
			push_warning("No color found")

func clear_all_notes() -> void:
	print("clearing all notes")
	for i : Object in note_nodes:
		i.free()
	note_nodes.clear()
#endregion
	
func play_notes(new_time : float) -> void:
	GameManager.redraw_scene()
	for i : Node2D in note_nodes:
		#(NoteTimestamp - TimePassed ) * scroll_speed + offset
		i.position.x = (GameManager.music_time_to_screen_time(i.time) - GameManager.music_time_to_screen_time(new_time)) + offset
		#Check if note still has to come up, else make it invisible
		if i.time >= new_time:
			i.visible = true
		else:
			if i.visible && GameManager.audio_player.playing:
				#Make sure the note is actually close enough to the bar before playing the sound
				if GameManager.audio_player.playing && i.time > GameManager.current_pos - 0.02:
					get_tree().get_nodes_in_group("Instruments")[i.color - 1].play()
				i.visible = false

func _process(_delta : float) -> void:
	if current_lane == 0:
		cursor_note.visible = false
	else:
		cursor_note.visible = true
		cursor_note.position.y = reset_note_y(cursor_note, current_lane)
		var mouse_screen_x : float = get_viewport().get_mouse_position().x - offset
		var music_time : float = GameManager.get_closest_snap_value(GameManager.screen_time_to_music_time(mouse_screen_x) + GameManager.current_pos)
		cursor_note.position.x = (GameManager.music_time_to_screen_time(music_time - GameManager.current_pos)) + offset
