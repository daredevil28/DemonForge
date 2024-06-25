class_name Action
extends Object
## Action [Object].
##
## Contains what action has been performed.

## The possible actions.
enum ActionName {
	NOTEADD,
	NOTEREMOVE,
	VALUECHANGED,
	MULTIACTION,
}
## If it is an undo or a redo.
enum ActionType {
	UNDO,
	REDO,
}
## The [enum ActionName] of the Action.
var action_name : ActionName
## The [enum ActionType] of the Action.
var action_type : ActionType = ActionType.UNDO

func _init(name : ActionName) -> void:
	action_name = name
	
