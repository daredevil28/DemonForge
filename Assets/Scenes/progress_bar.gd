extends ProgressBar

@onready var manager : Node = get_tree().root.get_child(0).get_node("%GameManager")

func _process(delta):
	value = manager.current_pos / manager.audio_length * 100
