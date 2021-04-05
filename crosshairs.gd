extends Sprite

const sub_window_size = Vector2(512, 512)
const sub_window_offset = Vector2(30, 30)

#func _input(event):
#	if event is InputEventMouseMotion:
#		var inside_bounds = true
#		# Set the crosshairs position to the mouse position
#		position = event.position - sub_window_offset
#		# Check x-bounds for crosshairs
#		if position.x < 0:
#			position.x = 0
#			inside_bounds = false
#		elif position.x > sub_window_size.x:
#			position.x = sub_window_size.x
#			inside_bounds = false
#		# Check y-bounds for crosshairs
#		if position.y < 0:
#			position.y = 0
#			inside_bounds = false
#		elif position.y > sub_window_size.y:
#			position.y = sub_window_size.y
#			inside_bounds = false
#		# Hide the mouse if we are inside bounds
#		if inside_bounds:
#			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
#			visible = true
#		else:
#			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#			visible = false
