class_name InternalNote extends Node2D

var time : float = 0
var color : int = 0
var canvas_color : Color = Color.WHITE : 
	set(value):
		canvas_color = value
		modulate = canvas_color

@onready var collider : CollisionShape2D = get_node("Area2D/CollisionShape2D")

func _ready() -> void:
	#Connect the signal to the parent of the collider which is the Area2D
	collider.get_parent().mouse_shape_entered.connect(_on_mouse_shape_entered)
	collider.get_parent().mouse_shape_exited.connect(_on_mouse_shape_exited)
	
#Enable/Disable the collider if the note is outside the screen size
func enable_collision() -> void:
	collider.disabled = false
	
func disable_collision() -> void:
	collider.disabled = true
	
func _on_mouse_shape_entered(_id : int) -> void:
	#Make the note dark grey whenever we hover the mouse over it
	if(GameManager.current_hovered_note == null):
		modulate = Color(0.5,0.5,0.5)
		GameManager.current_hovered_note = self

func _on_mouse_shape_exited(_id : int) -> void:
	#Reset the note color whenever the mouse leaves the note
	if(GameManager.current_hovered_note == self):
		GameManager.current_hovered_note = null
	modulate = canvas_color
