class_name Marker
extends InternalNote
## Markers to change how the song flows
##
## Currently only supports changing the BPM and snapping of a song

var bpm : float
var snapping : int


func _init() -> void:
	# Automatically set the color to 7
	color = 7


func _ready() -> void:
	# Run the overriden _ready function from internal_note
	super._ready()
	
	# For custom asset support
	var sprite : Sprite2D = $Sprite2D
	sprite.texture = GameManager.marker_sprite
