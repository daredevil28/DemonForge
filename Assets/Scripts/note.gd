class_name Note extends InternalNote

var interval : int :
	# If we change the interval also change the label text
	set(value):
		interval = value
		$Label.text = str(value)

var double_time : bool


func _ready() -> void:
	# Run the overriden _ready function from internal_note
	super._ready()
	
	# For custom asset support
	var sprite : Sprite2D = $Sprite2D
	sprite.texture = GameManager.note_sprite
