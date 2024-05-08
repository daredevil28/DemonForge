extends Node

var note_nodes : Array = []
@onready var manager : Node = %GameManager

@export var yellow : Color = Color.YELLOW
@export var red : Color = Color.RED
@export var orange : Color = Color.ORANGE
@export var purple : Color = Color.PURPLE
@export var blue : Color = Color.BLUE
@export var green : Color = Color.GREEN

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
	play_notes(0)

func reset_note_location() -> void:
	for i : Node2D in note_nodes:
		reset_note_y(i, i.color)
	play_notes(%GameManager.current_pos)
	#Redraw the judgement line in drawer.gd
	get_tree().root.get_child(0).queue_redraw()

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
	for i : Node2D in note_nodes:
		#Check if note still has to come up, else make it invisible
		if i.time >= new_time:
			i.visible = true
			#(-TimePassed + NoteTimestamp) * scroll_speed + offset
			i.position.x = (-manager.music_time_to_screen_time(new_time) + manager.music_time_to_screen_time(i.time)) * manager.scroll_speed + offset
		else:
			if i.visible:
				if manager.audio_player.playing:
					get_tree().get_nodes_in_group("Instruments")[i.color - 1].play()
			i.visible = false

func clear_all_notes() -> void:
	print("clearing all nodes")
	for i in note_nodes:
		i.free()
	note_nodes.clear()
		
