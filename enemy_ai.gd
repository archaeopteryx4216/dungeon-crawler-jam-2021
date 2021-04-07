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
export var health = 200
export var courage = 10000

# Global Vars
var player_position
var home_position
var facing
var target_position = Vector3(0,0,0)
var mode
var passable
var frightened_damage = 0

func overlapping_another_enemy(position):
	for enemy in get_parent().get_children():
		if position.distance_to(enemy.get_translation()) < 1 and not enemy.is_passable() and get_instance_id() != enemy.get_instance_id():
			return true
	return false

func get_point_ahead(distance_multiplier):
	if facing == NORTH:
		return get_translation() +  Vector3(0,0,-2)*distance_multiplier
	elif facing == SOUTH:
		return get_translation() + Vector3(0,0,2)*distance_multiplier
	elif facing == EAST:
		return get_translation() + Vector3(2,0,0)*distance_multiplier
	else: # facing == WEST
		return get_translation() + Vector3(-2,0,0)*distance_multiplier

func another_enemy_in_front():
	return overlapping_another_enemy(get_point_ahead(1))

# Functions for switching the AI mode
func set_mode_chase():
	if mode != DYING and mode != DEAD:
		mode = CHASE
		passable = false
		$walking.visible = true
		$attacking.visible = false
		$fleeing.visible = false
		$dying.visible = false
		$dead.visible = false
		$chase_timer.start()

func set_mode_scatter():
	if mode != DYING and mode != DEAD:
		mode = SCATTER
		passable = true
		$walking.visible = false
		$attacking.visible = false
		$fleeing.visible = false
		$dying.visible = false
		$dead.visible = false
		$scatter_timer.start()

func set_mode_frightened():
	if mode != DYING and mode != DEAD:
		sudden_turn()
		mode = FRIGHTENED
		passable = false
		frightened_damage = 0
		$walking.visible = false
		$attacking.visible = false
		$fleeing.visible = true
		$dying.visible = false
		$dead.visible = false
		$frightened_timer.start()

func set_mode_attacking():
	if mode != DYING and mode != DEAD:
		mode = ATTACK
		passable = false
		$walking.visible = false
		$attacking.visible = true
		$fleeing.visible = false
		$dying.visible = false
		$dead.visible = false
		# No timer for this mode

func set_mode_dying():
	mode = DYING
	passable = false
	$walking.visible = false
	$attacking.visible = false
	$fleeing.visible = false
	$dying.visible = true
	$dead.visible = false
	$death_timer.start()

func set_mode_dead():
	mode = DEAD
	passable = true
	$walking.visible = false
	$attacking.visible = false
	$fleeing.visible = false
	$dying.visible = false
	$dead.visible = true
	$removal_timer.start()

# Initialize the enemy
func _ready():
	facing = NORTH
	set_mode_chase()
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

# Force a sudden turn:
func sudden_turn():
	force_update_all_raycast()
	var turn_options = gather_turn_options(true)
	if len(turn_options) > 0:
		turn_options.shuffle()
		turn(turn_options[0])

# Update all collision detection rays
func force_update_all_raycast():
	$"./front_ray".force_raycast_update()
	$"./left_ray".force_raycast_update()
	$"./right_ray".force_raycast_update()
	$"./back_ray".force_raycast_update()

func gather_turn_options(can_reverse):
	var turn_options = []
	if !$"./front_ray".is_colliding():
		turn_options.append("no_turn")
	if !$"./left_ray".is_colliding():
		turn_options.append("left")
	if !$"./right_ray".is_colliding():
		turn_options.append("right")
	if can_reverse:
		if !$"./back_ray".is_colliding():
			turn_options.append("reverse")
	return turn_options

# AI movement for the chase mode
func chase():
	# Step 0) Verify that the target is not null
	if target_position == null:
		return
	# Step 0.5) If we are facing a wall somehow, turn away from it!
	if $"./front_ray".is_colliding():
		sudden_turn()
	# Step 1) Take a step forward
	var position = get_translation()
	if not another_enemy_in_front():
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
	var turn_options = gather_turn_options(true)
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
	# Step 0.5) If we are facing a wall somehow, turn away from it!
	if $"./front_ray".is_colliding():
		sudden_turn()
	# Step 1) Take a step forward
	var position = get_translation()
	if not another_enemy_in_front():
		position = take_step(position, facing)
	set_translation(position)
	force_update_all_raycast()
	# Step 2) Check forward, left, and right to see options for movement
	# Note: Also checking reverse (Different from pacman AI!) to avoid
	# being stuck going one way down a long coridor. Downside is that the alien
	# can now get trapped if the player is in a separate parallel coridor.
	var turn_options = gather_turn_options(false)
	if len(turn_options) == 0:
		turn("reverse")
	else:
		# Step 4) Choose a random direction
		turn_options.shuffle()
		var chosen_direction = turn_options[0]
		# At this point chosen_direction is where we should turn
		turn(chosen_direction)

# AI Actions for the frightened mode
func flee():
	# Step 0) Verify that the target is not null
	if target_position == null:
		return
	# Step 0.5) If we are facing a wall somehow, turn away from it!
	if $"./front_ray".is_colliding():
		sudden_turn()
	# Step 1) Take a step forward
	var position = get_translation()
	if not another_enemy_in_front():
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
	var turn_options = gather_turn_options(true)
	if len(turn_options) == 0:
		turn("reverse")
	else:
		# Step 4) Check each option to find the one farthest from the target
		var largest_distance = 0
		var chosen_direction = ""
		for possible_turn in turn_options:
			var new_cardinal_facing = turn_updated_facing(possible_turn)
			var distance_to_target = target_position.distance_to(take_step(get_translation(), new_cardinal_facing))
			if distance_to_target > largest_distance:
				largest_distance = distance_to_target
				chosen_direction = possible_turn
		# At this point chosen_direction is where we should turn
		turn(chosen_direction)

# Take an AI action each time the timer expires
func _on_action_timer_timeout():
	if mode == CHASE:
		chase()
		if target_position != null and get_translation().distance_to(target_position) < 2.5:
			set_mode_attacking()
	elif mode == ATTACK:
		attack()
		if target_position != null and get_translation().distance_to(target_position) >= 2.5:
			set_mode_chase()
	elif mode == SCATTER:
		scatter()
	elif mode == FRIGHTENED:
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

func is_passable():
	return passable

func _on_flamethrower(positions):
	if mode != SCATTER and mode != DYING and mode != DEAD:
		for pos in positions:
			if get_translation().distance_to(pos) < 1:
				health -= 1
				frightened_damage += 1
				if frightened_damage > (randi()%courage + 1):
					set_mode_frightened()
				break
		if mode != DEAD and mode != DYING and health <= 0:
			if !$snarl2.is_playing():
				$snarl2.play()
			set_mode_dying()


func _on_death_timer_timeout():
	set_mode_dead()


func _on_removal_timer_timeout():
	queue_free()


func _on_frightened_timer_timeout():
	if !$snarl.is_playing():
		$snarl.play()
	sudden_turn()
	set_mode_chase()


func _on_scatter_timer_timeout():
	if !$snarl.is_playing():
		$snarl.play()
	set_mode_chase()


func _on_chase_timer_timeout():
	set_mode_scatter()
