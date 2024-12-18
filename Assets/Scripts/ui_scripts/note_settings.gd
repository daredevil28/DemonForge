extends Control

@onready var _note_settings : Array[Node] = get_tree().get_nodes_in_group("NoteSettings")

var _selected_notes : Array[InternalNote]


func _ready() -> void:
	GameManager.note_selected.connect(_on_note_selected)
	GameManager.note_deselected.connect(_on_note_deselected)


## If mouse has entered the note settings box.
func _on_note_settings_mouse_entered() -> void:
	Global.ui_controller._note_settings_focused = true


## If mouse has left the note settings box
func _on_note_settings_mouse_exited() -> void:
	Global.ui_controller._note_settings_focused = false


## Called whenever a spin box value changed in the note settings
func _on_spin_box_value_changed(value: float, box : String) -> void:
	print("Changing note value: " + box + " to " + str(value))
	# Change the specific box
	GameManager.project_changed = true
	
	# Make sure selected array is not empty
	if(!_selected_notes.is_empty()):
		# Check to make sure we are not opening the note settings in this frame
		# To prevent accidental note value changes
		# Make a new multi action action even if the _selected_note array is bigger than 1
		var new_multi_action : MultiAction = MultiAction.new(Action.ActionName.MULTIACTION)
		
		for array_note : InternalNote in _selected_notes:
				
			if(array_note is Marker && box == "interval"):
				continue
			if(array_note is Note && (box == "bpm" || box == "snapping")):
				continue
				
			var new_action : ValueAction = ValueAction.new(Action.ActionName.VALUECHANGED)
			new_action.time = array_note.time
			new_action.color = array_note.color
				
			match box:
					
				"interval":
						
					new_action.value_type = ValueAction.ValueType.INTERVAL
					new_action.old_value = array_note.interval
					array_note.interval = value
						
				"bpm":
					new_action.value_type = ValueAction.ValueType.BPM
					new_action.old_value = array_note.bpm
					array_note.bpm = value
					Global.game_scene_node.queue_redraw()
					GameManager.current_pos = GameManager.current_pos
						
				"snapping":
					new_action.value_type = ValueAction.ValueType.SNAPPING
					new_action.old_value = array_note.snapping
					array_note.snapping = value
					Global.game_scene_node.queue_redraw()
					GameManager.current_pos = GameManager.current_pos
						
			# If the array is bigger than 1 then add it to new_multi_action	
			if(_selected_notes.size() > 1):
				new_multi_action.actions.append(new_action)
			else:
				GameManager.add_undo_action(new_action)
			
		# Add mutli action to the undo array
		if(_selected_notes.size() > 1):
			GameManager.add_undo_action(new_multi_action)


func _on_check_box_toggled(toggled_on: bool) -> void:
	GameManager.project_changed = true
	
	var new_multi_action : MultiAction = MultiAction.new(Action.ActionName.MULTIACTION)
	
	for array_note : InternalNote in _selected_notes:
		if(array_note is Note):
			
			var new_action : ValueAction = ValueAction.new(Action.ActionName.VALUECHANGED)
			new_action.time = array_note.time
			new_action.color = array_note.color
			new_action.value_type = ValueAction.ValueType.DOUBLETIME
			new_action.old_value = array_note.double_time
			
			if(_selected_notes.size() > 1):
				new_multi_action.actions.append(new_action)
			else:
				GameManager.add_undo_action(new_action)
			
			array_note.double_time = toggled_on
			
	if(_selected_notes.size() > 1):
		GameManager.add_undo_action(new_multi_action)


## Called on GameManager.note_selected
func _on_note_selected(notes : Array[InternalNote]) -> void:# < GameManager.note_selected
	_selected_notes = notes.duplicate()
	var first_note : InternalNote = _selected_notes[0]
	# Always prioritise normal notes over markers
	for array_note : InternalNote in _selected_notes:
		if(array_note is Note):
			first_note = array_note
			break
	
	var bpm_the_same : bool = true
	var snapping_the_same : bool = true
	var interval_the_same : bool = true
	
	# Check if any of the notes in the _selected_notes array have the exact same variable
	for array_note : InternalNote in _selected_notes:
		if(array_note is Marker):
			if(first_note is Note):
				break
			else:
				if(array_note.bpm != first_note.bpm):
					bpm_the_same = false
					_note_settings[2].get_line_edit().text = "-"
					
				if(array_note.snapping != first_note.snapping):
					snapping_the_same = false
					_note_settings[3].get_line_edit().text = "-"
				
		if(array_note is Note):
			
			if(array_note.interval != first_note.interval):
				interval_the_same = false
				_note_settings[0].get_line_edit().text = "-"
				
		if(!bpm_the_same && !snapping_the_same && !interval_the_same):
			break
			
	# Makes the note settings panel visible
	# If note is a marker then show the marker panel, else show the note panel
	if(first_note is Marker):
		if(bpm_the_same):
			_note_settings[2].set_value_no_signal(first_note.bpm)
			
		if(snapping_the_same):
			_note_settings[3].set_value_no_signal(first_note.snapping)
			
		get_child(0).visible = false
		get_child(1).visible = true
		
	if(first_note is Note):
		if(interval_the_same):
			_note_settings[0].set_value_no_signal(first_note.interval)
			
		_note_settings[1].button_pressed = first_note.double_time
		get_child(0).visible = true
		get_child(1).visible = false
		
	visible = true


## Called on GameManager.note_deselected
func _on_note_deselected() -> void:
	visible = false
	_selected_notes.clear()
