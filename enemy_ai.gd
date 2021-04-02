extends Sprite3D

enum {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

enum {
	CHASE,
	SCATTER,
	FRIGHTENED
}
var player_position
var home_position
var facing
var target_position
var mode

func _ready():
	facing = NORTH
	mode = CHASE
	home_position = Vector3(0,0,0)
	target_position = home_position

func _process(_delta):
	if mode == CHASE:
		# Get the position of the player and set it as the target
		target_position = player_position

func set_player_position(pos):
	player_position = pos

func set_home_position(pos):
	home_position = pos

func _on_action_timer_timeout():
	var next_position = get_translation()
	var turn_candidates = []
	if not target_position:
		return
	# Take a step forward
	if not $"./front_ray".is_colliding():
		# Not colliding, so can move
		if facing == NORTH:
			next_position += Vector3(0, 0, 2)
		elif facing == WEST:
			next_position += Vector3(2, 0, 0)
		elif facing == SOUTH:
			next_position += Vector3(0, 0, -2)
		elif facing == EAST:
			next_position += Vector3(-2, 0, 0)
	set_translation(next_position)
	prints("Moved to:", next_position)
	# Check neighbor tiles for collisions. If no collisions, we could move there next turn
	if not $"./front_ray".is_colliding():
		turn_candidates.append("no_turn")
	if not $"./left_ray".is_colliding():
		turn_candidates.append("left")
	if not $"./right_ray".is_colliding():
		turn_candidates.append("right")
	# If there are no options for movement, then reverse
	if len(turn_candidates) == 0:
		turn("reverse")
	else:
		# If there are candidates, check each one to see which brings us closest to our target
		var selected_turn = turn_candidates[0]
		var shortest_distance = 10000000000
		for turn in turn_candidates:
			var new_facing = turn_updated_facing(turn)
			if new_facing == NORTH:
				if target_position.distance_to(next_position + Vector3(0, 0, 2)) < shortest_distance:
					selected_turn = turn
					shortest_distance = target_position.distance_to(next_position + Vector3(0, 0, 2))
			elif new_facing == EAST:
				if target_position.distance_to(next_position + Vector3(-2, 0, 0)) < shortest_distance:
					selected_turn = turn
					shortest_distance = target_position.distance_to(next_position + Vector3(-2, 0, 0))
			elif new_facing == WEST:
				if target_position.distance_to(next_position + Vector3(2, 0, 0)) < shortest_distance:
					selected_turn = turn
					shortest_distance = target_position.distance_to(next_position + Vector3(2, 0, 0))
			elif new_facing == SOUTH:
				if target_position.distance_to(next_position + Vector3(0, 0, -2)) < shortest_distance:
					selected_turn = turn
					shortest_distance = target_position.distance_to(next_position + Vector3(0, 0, -2))
		turn(selected_turn)

func turn_updated_facing(direction):
	if direction == "left":
		if facing == NORTH:
			return WEST
		elif facing == WEST:
			return SOUTH
		elif facing == SOUTH:
			return EAST
		elif facing == EAST:
			return NORTH
	elif direction == "right":
		if facing == NORTH:
			return EAST
		elif facing == EAST:
			return SOUTH
		elif facing == SOUTH:
			return WEST
		elif facing == WEST:
			return NORTH
	elif direction == "reverse":
		if facing == NORTH:
			return SOUTH
		elif facing == SOUTH:
			return NORTH
		elif facing == WEST:
			return EAST
		elif facing == EAST:
			return WEST
	return facing

func turn(direction):
	prints("Now turning", direction)
	facing = turn_updated_facing(direction)
	if direction == "left":
		set_rotation(get_rotation() + Vector3(0,PI/2,0))
	elif direction == "right":
		set_rotation(get_rotation() + Vector3(0,-PI/2,0))
	elif direction == "reverse":
		set_rotation(get_rotation() + Vector3(0,PI,0))
