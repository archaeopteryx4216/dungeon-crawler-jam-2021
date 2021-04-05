extends Spatial

signal attacked(enemy_position, attack_strength)

# Possible directions to face
enum {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

# Possible AI/Animation states
enum {
	CHASE,
	ATTACK,
	SCATTER,
	FRIGHTENED,
	DYING,
	DEAD
}

# Exported global vars
export var attack_strength = 5
export var health = 100

# Global Vars
var player_position
var home_position
var facing
var target_position = Vector3(0,0,0)
var mode

# Initialize the enemy
func _ready():
	facing = SOUTH
	mode = CHASE
	home_position = Vector3(0,0,0)
	target_position = home_position

# Update the target position each frame
func _process(_delta):
	# Get the position of the player and set it as the target
	if mode == CHASE or mode == ATTACK:
		target_position = player_position
	elif mode == SCATTER:
		target_position = home_position

# Notify the enemy of the player's position
func set_player_position(pos):
	player_position = pos

# Set the home point for the enemy (for use in scatter mode)
func set_home_position(pos):
	home_position = pos

# Update all collision detection rays
func force_update_all_raycast():
	$"./front_ray".force_raycast_update()
	$"./left_ray".force_raycast_update()
	$"./right_ray".force_raycast_update()
	$"./back_ray".force_raycast_update()

func gather_turn_options():
	var turn_options = []
	if !$"./front_ray".is_colliding():
		turn_options.append("no_turn")
	if !$"./left_ray".is_colliding():
		turn_options.append("left")
	if !$"./right_ray".is_colliding():
		turn_options.append("right")
	if !$"./back_ray".is_colliding():
		turn_options.append("reverse")
	return turn_options

# AI movement for the chase mode
func chase():
	# Step 0) Verify that the target is not null
	if target_position == null:
		return
	# Step 1) Take a step forward
	var position = get_translation()
	position = take_step(position, facing)
	# Step 1.5) If we are right in front of the player, stop!
	if position == target_position:
		return
	set_translation(position)
	force_update_all_raycast()
	# Step 2) Check forward, left, and right to see options for movement
	# Note: Also checking reverse (Different from pacman AI!) to avoid
	# being stuck going one way down a long coridor. Downside is that the alien
	# can now get trapped if the player is in a separate parallel coridor.
	var turn_options = gather_turn_options()
	if len(turn_options) == 0:
		# Step 3) Reverse direction as we are in a dead end
		turn("reverse")
	else:
		# Step 4) Check each option to find the one closest to the target
		var smallest_distance = 100000000
		var chosen_direction = ""
		for possible_turn in turn_options:
			var new_cardinal_facing = turn_updated_facing(possible_turn)
			var distance_to_target = target_position.distance_to(take_step(get_translation(), new_cardinal_facing))
			if distance_to_target < smallest_distance:
				smallest_distance = distance_to_target
				chosen_direction = possible_turn
		# At this point chosen_direction is where we should turn
		turn(chosen_direction)

# AI Actions for the attack mode
func attack():
	emit_signal("attacked", get_translation(), attack_strength)

# AI Actions for the scatter mode
func scatter():
	pass

# AI Actions for the frightened mode
func flee():
	# Step 0) Verify that the target is not null
	if target_position == null:
		return
	# Step 1) Take a step forward
	var position = get_translation()
	position = take_step(position, facing)
	# Step 1.5) If we are right in front of the player, stop!
	if position == target_position:
		return
	set_translation(position)
	force_update_all_raycast()
	# Step 2) Check forward, left, and right to see options for movement
	# Note: Also checking reverse (Different from pacman AI!) to avoid
	# being stuck going one way down a long coridor. Downside is that the alien
	# can now get trapped if the player is in a separate parallel coridor.
	var turn_options = gather_turn_options()
	if len(turn_options) == 0:
		turn("reverse")
	else:
		# Step 4) Pick a random option since we are fleeing
		turn_options.shuffle()
		turn(turn_options[0])

# Take an AI action each time the timer expires
func _on_action_timer_timeout():
	if mode == CHASE:
		$"./walking".visible = true
		$"./attacking".visible = false
		chase()
		if target_position != null and get_translation().distance_to(target_position) < 3:
			mode = ATTACK
	elif mode == ATTACK:
		$"./walking".visible = false
		$"./attacking".visible = true
		attack()
		if target_position != null and get_translation().distance_to(target_position) >= 3:
			mode = CHASE
	elif mode == SCATTER:
		$"./walking".visible = true
		$"./attacking".visible = false
		scatter()
	elif mode == FRIGHTENED:
		$"./walking".visible = true
		$"./attacking".visible = false
		flee()

# Given the current facing (stored in a global) and the turn direction,
# what is the new facing?
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

# Given a position and a cardinal direction, returns a position after a step is
# taken in that direction
func take_step(position, direction):
	if direction == NORTH:
		return position + Vector3(0,0,-2)
	elif direction == EAST:
		return position + Vector3(2,0,0)
	elif direction == WEST:
		return position + Vector3(-2,0,0)
	else: # direction == SOUTH
		return position + Vector3(0,0,2)
		

# Update the current facing and rotate the enemy sprites.
func turn(direction):
	facing = turn_updated_facing(direction)
	if direction == "left":
		set_rotation(get_rotation() + Vector3(0,PI/2,0))
	elif direction == "right":
		set_rotation(get_rotation() + Vector3(0,-PI/2,0))
	elif direction == "reverse":
		set_rotation(get_rotation() + Vector3(0,PI,0))

func _on_flamethrower(positions):
	for pos in positions:
		if get_translation().distance_to(pos) < 1:
			health -= 1
			break
