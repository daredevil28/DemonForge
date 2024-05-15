class_name Note extends Node2D

var time : float = 0
var color : int = 0
var canvas_color : Color = Color.WHITE : 
	set(value):
		canvas_color = value
		modulate = canvas_color
@onready var collider : CollisionShape2D = get_node("Area2D/CollisionShape2D")

var interval : int :
	get:
		return interval
	set(value):
		interval = value
		$Label.text = str(value)

func enable_collision() -> void:
	collider.disabled = false
	
func disable_collision() -> void:
	collider.disabled = true
	
func _on_mouse_shape_entered(id : int):
	if(GameManager.current_hovered_note == null):
		modulate = Color(1,1,1)
		GameManager.current_hovered_note = self

func _on_mouse_shape_exited(id : int):
	if(GameManager.current_hovered_note == self):
		GameManager.current_hovered_note = null
	modulate = canvas_color
