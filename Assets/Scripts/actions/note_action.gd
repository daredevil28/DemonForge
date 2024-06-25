class_name NoteAction
extends Action
## Additional information for [Action],

## Time position of the [NoteAction],
var time : float
## Color of the [NoteAction] (if the [param color] is [code]7[/code] then it is a marker),
var color : int
## The interval of the [NoteAction],
var interval : int = 0
## If it's a marker then the BPM of the [NoteAction],
var bpm : float
## If it's a marker then the snapping of the [NoteAction],
var snapping : int
