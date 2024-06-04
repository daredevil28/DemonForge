class_name Action extends Object

enum ActionName {
	NOTEADD,
	NOTEREMOVE,
	VALUECHANGED,
}

enum ActionType {
	UNDO,
	REDO,
}

var action_name : ActionName
var action_type : ActionType = ActionType.UNDO

func _init(name : ActionName) -> void:
	action_name = name
	
