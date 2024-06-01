class_name Action extends Object

enum ActionName {
	NOTEADD,
	NOTEREMOVE,
}

enum ActionType {
	UNDO,
	REDO,
}

var current_action : ActionType = ActionType.UNDO
var action_name : ActionName
