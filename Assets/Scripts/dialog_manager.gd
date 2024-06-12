class_name DialogManager
extends ConfirmationDialog
## Controls the dialog
##
## This script controls the dialog popup for whenever we want to perform an action that is possibly destructive.
## Actions include stuff like exiting without saving

## The function that will be called after pressing OK
var current_callable : Callable


func _init() -> void:
	Global.popup_dialog = self


## Displays the dialog
func play_dialog(new_title : String, new_text : String, function : Callable) -> void:
	dialog_text = new_text
	title = new_title
	current_callable = function
	popup()

## Call the function if we press OK
func _on_confirmed() -> void:
	current_callable.call() 
	current_callable = Callable()
	visible = false

## Cancel the function
func _on_canceled() -> void:
	current_callable = Callable()
	visible = false
