extends Node2D

var time : float = 0
var color : int = 0

var interval : int :
	get:
		return interval
	set(value):
		interval = value
		$Label.text = str(value)
