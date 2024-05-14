extends Node2D

@export var note_color : int

func _on_mouse_shape_entered(_id : int) -> void:
	GameManager.current_lane = note_color

func _on_mouse_shape_exited(_id : int) -> void:
	GameManager.current_lane = 0
