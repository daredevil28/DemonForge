extends Node

var last_beat : int
var metronome_enabled : bool = true
@onready var metronome_high : AudioStreamPlayer = $MetronomeLow
@onready var metronome_low : AudioStreamPlayer = $MetronomeHigh

func _process(_delta: float) -> void:
	if(GameManager.audio_player.playing && metronome_enabled):
		#Make sure we play the metronome only once
		if(GameManager.current_beat != last_beat):
			last_beat = GameManager.current_beat
			#Use the snapping frequency to determine when to play a high metronome note
			if(GameManager.current_beat % 4):
				metronome_high.play(0)
			else:
				metronome_low.play(0)

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("ToggleMetronome")):
		if(metronome_enabled == true):
			Global.notification_popup.play_notification("Metronome is now disabled.", 0.5)
		if(metronome_enabled == false):
			Global.notification_popup.play_notification("Metronome is now enabled.", 0.5)
		metronome_enabled = !metronome_enabled
