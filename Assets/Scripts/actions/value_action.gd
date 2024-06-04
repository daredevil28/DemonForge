class_name ValueAction extends NoteAction

enum ValueType {
	INTERVAL,
	BPM,
	SNAPPING,
}

var value_type : ValueType
var old_value
