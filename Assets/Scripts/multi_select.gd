class_name MultiSelect
extends Node2D
## Class for managing the box select

var starting_dragging : bool = false
var currently_dragging : bool = false
var first_pos : Vector2
var end_pos : Vector2
var select_rectangle : RectangleShape2D = RectangleShape2D.new()


func _init() -> void:
	Global.multi_select = self


func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("LeftClick")):
		starting_dragging = true
		first_pos = event.position
		
	if(starting_dragging):
		if(event is InputEventMouseMotion):
			currently_dragging = true
		
	if(event.is_action_released("LeftClick")):
		if(currently_dragging):
			currently_dragging = false
			starting_dragging = false
			end_pos = event.position
			queue_redraw()
			
			select_rectangle.extents = abs(end_pos - first_pos) / 2
			var space = get_world_2d().direct_space_state
			var query = PhysicsShapeQueryParameters2D.new()
			query.shape = select_rectangle
			query.collide_with_areas = true
			query.collision_mask = 2
			query.transform = Transform2D(0, (end_pos + first_pos) / 2)
			var shape_query : Array = space.intersect_shape(query)
			if(!shape_query.is_empty()):
				_send_query_to_note_select(shape_query)
		else:
			starting_dragging = false
		
	if(event is InputEventMouseMotion && currently_dragging):
			queue_redraw()


func _send_query_to_note_select(shape_query : Array[Dictionary]) -> void:
	var new_array : Array[InternalNote]
	
	for shapes in shape_query:
		new_array.append(shapes["collider"].get_parent())
	GameManager.select_multiple_notes(new_array)
	

func _draw() -> void:
	if(currently_dragging):
		draw_rect(Rect2(first_pos, get_global_mouse_position() - first_pos),Color.YELLOW, false, 2)
