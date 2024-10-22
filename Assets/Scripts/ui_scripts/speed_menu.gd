extends Window

var _last_speed_slider_value : float
var _speed_slider_affect_instruments : bool
var _speed_text : RichTextLabel


func _ready() -> void:
	_speed_text = find_child("SpeedText")


func _on_speed_menu_close_requested() -> void:
	visible = false


func _on_speed_slider_value_changed(value: float) -> void:
	_last_speed_slider_value = value
	GameManager.audio_player.pitch_scale = value
	if(_speed_slider_affect_instruments):
		for instrument in Global.instruments:
			instrument.pitch_scale = value
	_speed_text.text = "x" + str(value)


func _on_speed_menu_instruments_toggled(toggled_on: bool) -> void:
	_speed_slider_affect_instruments = toggled_on
	if(toggled_on):
		for instrument in Global.instruments:
			instrument.pitch_scale = _last_speed_slider_value
	else:
		for instrument in Global.instruments:
			instrument.pitch_scale = 1
