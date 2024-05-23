extends Sprite2D

var canvas_color : Color :
	set(value):
		canvas_color = value
		modulate = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.cursor_note = self
	
