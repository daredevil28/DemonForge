extends Node

var note_nodes : Array = []

var yellow : Color = Color.YELLOW
var red : Color = Color.RED
var orange : Color = Color.ORANGE
var purple : Color = Color.PURPLE
var blue : Color = Color.BLUE
var green : Color = Color.GREEN

var offset : float = 200

func _ready() -> void:
	#Reset the notes whenever the window is resized
	print(get_viewport().size_changed.connect(reset_note_location))
	
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
		reset_note_y(instance, note["color"])
		note_nodes.append(instance)
	GameManager.current_pos = 0
	GameManager.audio_length = note_nodes.back().time

func reset_note_location() -> void:
	for i : Node2D in note_nodes:
		reset_note_y(i, i.color)
	play_notes(GameManager.current_pos)
	#Redraw the lines in drawer.gd
	GameManager.redraw_scene()

func reset_note_y(instance : Node2D, color : int) -> void:
	match color:
			1:
				instance.modulate = yellow
				instance.position.y = DisplayServer.window_get_size().y / 1.8
			2:
				instance.modulate = red
				instance.position.y = DisplayServer.window_get_size().y / 2.2
			3:
				instance.modulate = orange
				instance.position.y = DisplayServer.window_get_size().y / 1.4
			4:
				instance.modulate = purple
				instance.position.y = DisplayServer.window_get_size().y / 2.6
			5:
				instance.modulate = blue
				instance.position.y = DisplayServer.window_get_size().y / 1.6
			6:
				instance.modulate = green
				instance.position.y = DisplayServer.window_get_size().y / 2.4
			_:
				push_warning("No color found")

func play_notes(new_time : float) -> void:
	GameManager.redraw_scene()
	for i : Node2D in note_nodes:
		#(-TimePassed + NoteTimestamp) * scroll_speed + offset
		i.position.x = (-GameManager.music_time_to_screen_time(new_time) + GameManager.music_time_to_screen_time(i.time)) * GameManager.scroll_speed + offset
		#Check if note still has to come up, else make it invisible
		if i.time >= new_time:
			i.visible = true
		else:
			if i.visible && GameManager.audio_player.playing:
				#Make sure the note is actually close enough to the bar before playing the sound
				if GameManager.audio_player.playing && i.time > GameManager.current_pos - 0.01:
					get_tree().get_nodes_in_group("Instruments")[i.color - 1].play()
				i.visible = false

func clear_all_notes() -> void:
	print("clearing all notes")
	for i in note_nodes:
		i.free()
	note_nodes.clear()
