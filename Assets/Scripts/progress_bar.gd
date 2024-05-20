extends ProgressBar

@onready var progress_ball : Sprite2D = $ProgressBall
var mouse_in_ball : bool
var holding_ball : bool

func _on_area_2d_mouse_entered() -> void:
	mouse_in_ball = true

func _on_area_2d_mouse_exited() -> void:
	mouse_in_ball = false

func _process(_delta : float) -> void:
	var percentage_passed : float = GameManager.current_pos / GameManager.audio_length
	value = percentage_passed * 100
	progress_ball.position.x = percentage_passed * DisplayServer.window_get_size().x
	
	if(holding_ball):
		GameManager.current_pos = clamp(get_viewport().get_mouse_position().x / DisplayServer.window_get_size().x * GameManager.audio_length,0,GameManager.audio_length)
	
func _input(event: InputEvent) -> void:
	if(!GameManager.audio_player.playing):
		if(mouse_in_ball):
			if(event.is_action_pressed("LeftClick")):
				holding_ball = true
		if(event.is_action_released("LeftClick")):
			holding_ball = false
	else:
		holding_ball = false
