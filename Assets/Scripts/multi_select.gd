class_name MultiSelect
extends Node2D
## Class for managing the box select

## If we have pressed left click
var starting_dragging : bool = false
## If we have moved our mouse after holding left click
var currently_dragging : bool = false
## First position where we holding the mouse
var first_pos : Vector2
## Last position after we release the mouse
var end_pos : Vector2
## Amount of frames where we have moved the mouse (to make setting notes easier)
var multi_select_frames : int
var select_rectangle : RectangleShape2D = RectangleShape2D.new()


func _init() -> void:
	Global.multi_select = self


func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("LeftClick") && !Global.progress_bar.holding_ball):
		starting_dragging = true
		first_pos = event.position
		
	if(starting_dragging):
		if(event is InputEventMouseMotion):
			multi_select_frames += 1
			if(multi_select_frames > 20):
				currently_dragging = true
				
		if(event.is_action_pressed("ScrollUp")):
			if(GameManager.current_pos != GameManager.audio_length):
				first_pos.x -= GameManager.music_time_to_screen_time(GameManager.seconds_per_tick)
				queue_redraw()
		if(event.is_action_pressed("ScrollDown")):
			if(GameManager.current_pos != 0):
				first_pos.x += GameManager.music_time_to_screen_time(GameManager.seconds_per_tick)
				queue_redraw()
			
	if(event.is_action_released("LeftClick")):
		multi_select_frames = 0
		if(currently_dragging):
			currently_dragging = false
			starting_dragging = false
			end_pos = event.position
			queue_redraw()
			#TODO Instead of doing using physics, it's probably better to use _screen_time_to_music_time
			# to select all the notes instead of possibly expensive physics queries
			select_rectangle.extents = abs(end_pos - first_pos) / 2
			var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
			var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
			query.shape = select_rectangle
			query.collide_with_areas = true
			query.collision_mask = 2
			query.transform = Transform2D(0, (end_pos + first_pos) / 2)
			var shape_query : Array = space.intersect_shape(query,NoteManager.note_nodes.size())
			if(!shape_query.is_empty()):
				_send_query_to_note_select(shape_query)
		else:
			starting_dragging = false
		
	if(event is InputEventMouseMotion && currently_dragging):
			queue_redraw()


func _send_query_to_note_select(shape_query : Array[Dictionary]) -> void:
	var new_array : Array[InternalNote]
	
	for shapes : Dictionary in shape_query:
		new_array.append(shapes["collider"].get_parent())
	GameManager.select_multiple_notes(new_array)
	

func _draw() -> void:
	if(currently_dragging):
		draw_rect(Rect2(first_pos, get_global_mouse_position() - first_pos),Color.YELLOW, false, 2)
