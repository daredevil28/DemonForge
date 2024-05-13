extends Node2D

@export var note_color : int

func _on_mouse_shape_entered(id):
	NoteManager.current_lane = note_color

func _on_mouse_shape_exited(shape_idx):
	NoteManager.current_lane = 0
