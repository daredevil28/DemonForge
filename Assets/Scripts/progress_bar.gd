extends ProgressBar
## Progressbar class
##
## This class controls the progressbar at the bottom of the screen

@onready var _progress_ball : Sprite2D = $ProgressBall
var _mouse_in_ball : bool
var holding_ball : bool


func _init() -> void:
	Global.progress_bar = self
	

func _on_area_2d_mouse_entered() -> void:
	_mouse_in_ball = true

func _on_area_2d_mouse_exited() -> void:
	_mouse_in_ball = false

func _process(_delta : float) -> void:
	# Get percentage of time passed and use that to get a percentage of screen width
	var percentage_passed : float = GameManager.current_pos / GameManager.audio_length
	value = percentage_passed * 100
	_progress_ball.position.x = percentage_passed * DisplayServer.window_get_size().x
	
	# If we are holding the progess bar ball then move current pos
	if(holding_ball):
		GameManager.current_pos = clamp(get_viewport().get_mouse_position().x / DisplayServer.window_get_size().x * GameManager.audio_length,0,GameManager.audio_length)
	
func _input(event: InputEvent) -> void:
	# Don't move the ball if we are playing the song
	if(!GameManager.audio_player.playing):
		# If the mouse is inside the ball collider
		if(_mouse_in_ball):
			if(event.is_action_pressed("LeftClick")):
				holding_ball = true
		# Only release the ball if we release the button
		if(event.is_action_released("LeftClick")):
			holding_ball = false
	else:
		holding_ball = false
