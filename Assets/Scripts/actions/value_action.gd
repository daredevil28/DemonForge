class_name ValueAction
extends NoteAction
## Aditional information for [Action],

## The posible types of the value,
enum ValueType {
	INTERVAL,
	BPM,
	SNAPPING,
	DOUBLETIME,
}
## The [enum ValueType] of the [ValueAction],
var value_type : ValueType
## The old value.
var old_value
