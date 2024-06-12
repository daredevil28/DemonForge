extends Sprite2D
## The note cursor of the player.
##
## This script manages the cursor that displays where a note will be placed.

## Sets the color of the cursor
var canvas_color : Color :
	set(value):
		canvas_color = value
		modulate = value


func _ready() -> void:
	GameManager.cursor_note = self
