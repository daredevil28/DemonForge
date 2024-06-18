class_name InstrumentPlayer
extends AudioStreamPlayer
## Class that controls an instrument


func play_instrument(roll_count : int, time_between_roll : float):
	var current_count : int = 1
	if(time_between_roll == 0):
		play()
		return
	while current_count <= roll_count:
		play()
		await get_tree().create_timer(time_between_roll).timeout
		current_count += 1
