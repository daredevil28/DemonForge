class_name NotificationManager
extends PanelContainer
## The notificationamnager class
##
## This class controls the notification system in the top right

var _notification_opacity : float
## Timer used for keeping the notification on screen
var _notification_timer : float

@onready var label : Label = $NotificationLabel


func _init() -> void:
	Global.notification_popup = self


## Pops up the notification
func play_notification(text : String, timer : float) -> void:
	# Reset the notification and make it visible
	_notification_opacity = 1
	_notification_timer = timer
	label.text = text


func _process(delta: float) -> void:
	# Modulate the notification opacity
	modulate = Color(1, 1, 1, lerp(0, 1, _notification_opacity))
	# Check if opacity is not 0 yet
	if(_notification_opacity > 0):
		# Check if timer hasn't passed yet
		if(_notification_timer > 0):
			_notification_timer -= delta
		else:
			_notification_opacity -= delta
