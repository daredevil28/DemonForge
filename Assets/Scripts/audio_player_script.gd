extends AudioStreamPlayer
## Script on the audio player.
##
## Script to manage anything related to the audio player.
## Currently only set itself in the GameManager.


func _init() -> void:
	GameManager.audio_player = self
