class_name DialogManager extends ConfirmationDialog

var current_callable : Callable

func _init() -> void:
	Global.popup_dialog = self

func play_dialog(new_title : String, new_text : String, function : Callable) -> void:
	dialog_text = new_text
	title = new_title
	current_callable = function
	popup()

func _on_confirmed() -> void:
	current_callable.call()
	current_callable = Callable()
	visible = false

func _on_canceled() -> void:
	current_callable = Callable()
	visible = false
