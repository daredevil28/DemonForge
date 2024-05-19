class_name NotificationManager extends PanelContainer

var notification_opacity : float
var notification_timer : float

@onready var label : Label = $NotificationLabel

func _ready() -> void:
	Global.notification_popup = self

func play_notification(text : String, timer : float) -> void:
	notification_opacity = 1
	notification_timer = timer
	label.text = text
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	modulate = Color(1, 1, 1, lerp(0, 1, notification_opacity))
	if(notification_opacity > 0):
		if(notification_timer > 0):
			notification_timer -= delta
		else:
			notification_opacity -= delta
