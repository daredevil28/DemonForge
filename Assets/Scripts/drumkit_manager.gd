extends Node

var snare_sound : AudioStream :
	set(value):
		$Snare.stream = value

var kick_sound : AudioStream :
	set(value):
		$Kick.stream = value

var tom_high : AudioStream :
	set(value):
		$TomHigh.stream = value
		
var tom_low : AudioStream :
	set(value):
		$TomLow.stream = value

var crash : AudioStream :
	set(value):
		$Crash.stream = value
		
var ride : AudioStream :
	set(value):
		$Ride.stream = value
