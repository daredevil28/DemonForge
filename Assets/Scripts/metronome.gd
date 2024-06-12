extends Node
## The metronome class
##
## Controls the metronome

## The last beat that occured
var _last_beat : int
## If the metronome is enabled or disabled
var _metronome_enabled : bool = true

@onready var _metronome_high : AudioStreamPlayer = $MetronomeLow
@onready var _metronome_low : AudioStreamPlayer = $MetronomeHigh

func _init() -> void:
	Global.metronome = self
	
func _process(_delta: float) -> void:
	if(GameManager.audio_player.playing && _metronome_enabled):
		# Make sure we play the metronome only once
		if(GameManager.current_beat != _last_beat):
			_last_beat = GameManager.current_beat
			# Use the snapping frequency to determine when to play a high metronome note
			if(GameManager.current_beat % GameManager.snapping_frequency == 0):
				_metronome_low.play(0)
			else:
				_metronome_high.play(0)

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("ToggleMetronome")):
		if(_metronome_enabled == true):
			Global.notification_popup.play_notification("Metronome is now disabled.", 0.5)
		if(_metronome_enabled == false):
			Global.notification_popup.play_notification("Metronome is now enabled.", 0.5)
		_metronome_enabled = !_metronome_enabled
