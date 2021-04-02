extends Control

enum {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

var colision_count = 0

export var player_facing = NORTH

func _ready():
	$"side_view/player_sprite".position = Vector2(128,128)

func _input(event):
	#if event && !event.echo && event.pressed:
	if event.is_action_pressed("move_up"):
		update_cameras(move("move_up"), Vector3(0,0,0))
	elif event.is_action_pressed("move_down"):
		update_cameras(move("move_down"), Vector3(0,0,0))
	elif event.is_action_pressed("move_left"):
		update_cameras(move("move_left"), Vector3(0,0,0))
	elif event.is_action_pressed("move_right"):
		update_cameras(move("move_right"), Vector3(0,0,0))
	elif event.is_action_pressed("turn_left"):
		turn("turn_left")
		update_cameras(Vector3(0,0,0), Vector3(0, PI/2, 0))
	elif event.is_action_pressed("turn_right"):
		turn("turn_right")
		update_cameras(Vector3(0,0,0), Vector3(0, -PI/2, 0))

func update_cameras(pos_change, turn_rads):
	# Move first person camera
	$"main_view/firstperson_viewport/firstperson_pos".set_translation($"main_view/firstperson_viewport/firstperson_pos".get_translation() + pos_change)
	# Move overhead camera
	$"side_view/overhead_viewport/overhead_pos".set_translation($"side_view/overhead_viewport/overhead_pos".get_translation() + pos_change)
	# Set first person camera rotation
	$"main_view/firstperson_viewport/firstperson_pos".set_rotation($"main_view/firstperson_viewport/firstperson_pos".get_rotation() + turn_rads)
	# Rotate player sprite in side view
	$"side_view/player_sprite".position = Vector2(0,0)
	$"side_view/player_sprite".set_rotation($"side_view/player_sprite".get_rotation() - turn_rads.y)
	$"side_view/player_sprite".position = Vector2(128,128)

func move(player_dir):
	var pos_change = Vector3(0, 0, 0)
	if player_dir == "move_up" and !$main_view/firstperson_viewport/firstperson_pos/front_ray.is_colliding():
		if player_facing == NORTH:
			pos_change = Vector3(0,0,-2)
		elif player_facing == SOUTH:
			pos_change = Vector3(0,0,2)
		elif player_facing == EAST:
			pos_change = Vector3(2,0,0)
		else:
			pos_change = Vector3(-2,0,0)
	elif player_dir == "move_down" and !$main_view/firstperson_viewport/firstperson_pos/back_ray.is_colliding():
		if player_facing == NORTH:
			pos_change = Vector3(0,0,2)
		elif player_facing == SOUTH:
			pos_change = Vector3(0,0,-2)
		elif player_facing == EAST:
			pos_change = Vector3(-2,0,0)
		else:
			pos_change = Vector3(2,0,0)
	elif player_dir == "move_left" and !$main_view/firstperson_viewport/firstperson_pos/left_ray.is_colliding():
		if player_facing == NORTH:
			pos_change = Vector3(-2,0,0)
		elif player_facing == SOUTH:
			pos_change = Vector3(2,0,0)
		elif player_facing == EAST:
			pos_change = Vector3(0,0,-2)
		else:
			pos_change = Vector3(0,0,2)
	elif player_dir == "move_right" and !$main_view/firstperson_viewport/firstperson_pos/right_ray.is_colliding():
		if player_facing == NORTH:
			pos_change = Vector3(2,0,0)
		elif player_facing == SOUTH:
			pos_change = Vector3(-2,0,0)
		elif player_facing == EAST:
			pos_change = Vector3(0,0,2)
		else:
			pos_change = Vector3(0,0,-2)
	return pos_change

func turn(dir):
	if dir == "turn_left":
		if player_facing == NORTH:
			player_facing = WEST
		elif player_facing == WEST:
			player_facing = SOUTH
		elif player_facing == SOUTH:
			player_facing = EAST
		elif player_facing == EAST:
			player_facing = NORTH
	elif dir == "turn_right":
		if player_facing == NORTH:
			player_facing = EAST
		elif player_facing == EAST:
			player_facing = SOUTH
		elif player_facing == SOUTH:
			player_facing = WEST
		elif player_facing == WEST:
			player_facing = NORTH


func _on_turn_left_pressed():
	turn("turn_left")
	update_cameras(Vector3(0,0,0), Vector3(0, PI/2, 0))


func _on_move_up_pressed():
	update_cameras(move("move_up"), Vector3(0, 0, 0))


func _on_turn_right_pressed():
	turn("turn_right")
	update_cameras(Vector3(0,0,0), Vector3(0, -PI/2, 0))


func _on_move_left_pressed():
	update_cameras(move("move_left"), Vector3(0, 0, 0))


func _on_move_back_pressed():
	update_cameras(move("move_down"), Vector3(0, 0, 0))


func _on_move_right_pressed():
	update_cameras(move("move_right"), Vector3(0, 0, 0))
