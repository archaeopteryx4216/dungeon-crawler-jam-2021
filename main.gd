extends Control

enum {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

signal flamethrower_on(positions)

# Global vars
export var player_health = 100
export var fuel = 0
export var flamethrower_range = 5

var game_over = false
var player_facing = NORTH
var flamethrower_on = false
var flames_visible = false

const gas_can = preload("res://gas_can.tscn")
const enemy = preload("res://enemy.tscn")

func _ready():
	# Set player stuff
	$"side_view/player_sprite".position = Vector2(128,128)
	$main_view/firstperson_viewport/firstperson_pos/flame.turn_off()
	
		

func pickup_gas_can():
	for existing_gas_can in $"fuel/fuel_cans".get_children():
		if $main_view/firstperson_viewport/firstperson_pos.get_translation().distance_to(existing_gas_can.get_translation()) < 1:
			existing_gas_can.pickup()

func _input(event):
	# Always check for the escape key to quit
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	# If the game is over, skip processing the below keys
	if game_over:
		return
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
	elif event.is_action_pressed("fire"):
		if fuel > 0:
			flamethrower_on = true
	elif event.is_action_released("fire"):
		flamethrower_on = false

func overlapping_an_enemy(position):
	for enemy in $enemy/enemies.get_children():
		if position.distance_to(enemy.get_translation()) < 1 and not enemy.is_passable():
			return true
	return false

func notify_all_enemies_of_player_position(position):
	for enemy in $enemy/enemies.get_children():
		enemy.set_player_position(position)

func update_cameras(pos_change, turn_rads):
	# Check if we will intersect the enemy, if so, skip the movement
	var next_position = $"main_view/firstperson_viewport/firstperson_pos".get_translation() + pos_change
	if not overlapping_an_enemy(next_position):
		# Move first person camera
		$"main_view/firstperson_viewport/firstperson_pos".set_translation(next_position)
		# Move overhead camera
		$"side_view/overhead_viewport/overhead_pos".set_translation($"side_view/overhead_viewport/overhead_pos".get_translation() + pos_change)
	# Set first person camera rotation
	$"main_view/firstperson_viewport/firstperson_pos".set_rotation($"main_view/firstperson_viewport/firstperson_pos".get_rotation() + turn_rads)
	# Rotate player sprite in side view
	$"side_view/player_sprite".position = Vector2(0,0)
	$"side_view/player_sprite".set_rotation($"side_view/player_sprite".get_rotation() - turn_rads.y)
	$"side_view/player_sprite".position = Vector2(128,128)
	# Notify the enemy of the player's position
	notify_all_enemies_of_player_position($"main_view/firstperson_viewport/firstperson_pos".get_translation())

func force_update_all_raycast():
	$main_view/firstperson_viewport/firstperson_pos/back_ray.force_raycast_update()
	$main_view/firstperson_viewport/firstperson_pos/front_ray.force_raycast_update()
	$main_view/firstperson_viewport/firstperson_pos/left_ray.force_raycast_update()
	$main_view/firstperson_viewport/firstperson_pos/right_ray.force_raycast_update()

func move(player_dir):
	force_update_all_raycast()
	var pos_change = Vector3(0, 0, 0)
	if player_dir == "move_up" and !$main_view/firstperson_viewport/firstperson_pos/front_ray.is_colliding():
		if !$button_container/footsteps.is_playing():
			$button_container/footsteps.play()
		if player_facing == NORTH:
			pos_change = Vector3(0,0,-2)
		elif player_facing == SOUTH:
			pos_change = Vector3(0,0,2)
		elif player_facing == EAST:
			pos_change = Vector3(2,0,0)
		else:
			pos_change = Vector3(-2,0,0)
	elif player_dir == "move_down" and !$main_view/firstperson_viewport/firstperson_pos/back_ray.is_colliding():
		if !$button_container/footsteps.is_playing():
			$button_container/footsteps.play()
		if player_facing == NORTH:
			pos_change = Vector3(0,0,2)
		elif player_facing == SOUTH:
			pos_change = Vector3(0,0,-2)
		elif player_facing == EAST:
			pos_change = Vector3(-2,0,0)
		else:
			pos_change = Vector3(2,0,0)
	elif player_dir == "move_left" and !$main_view/firstperson_viewport/firstperson_pos/left_ray.is_colliding():
		if !$button_container/footsteps.is_playing():
			$button_container/footsteps.play()
		if player_facing == NORTH:
			pos_change = Vector3(-2,0,0)
		elif player_facing == SOUTH:
			pos_change = Vector3(2,0,0)
		elif player_facing == EAST:
			pos_change = Vector3(0,0,-2)
		else:
			pos_change = Vector3(0,0,2)
	elif player_dir == "move_right" and !$main_view/firstperson_viewport/firstperson_pos/right_ray.is_colliding():
		if !$button_container/footsteps.is_playing():
			$button_container/footsteps.play()
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
	if not game_over:
		turn("turn_left")
		update_cameras(Vector3(0,0,0), Vector3(0, PI/2, 0))


func _on_move_up_pressed():
	if not game_over:
		update_cameras(move("move_up"), Vector3(0, 0, 0))

func _on_turn_right_pressed():
	if not game_over:
		turn("turn_right")
		update_cameras(Vector3(0,0,0), Vector3(0, -PI/2, 0))

func _on_move_left_pressed():
	if not game_over:
		update_cameras(move("move_left"), Vector3(0, 0, 0))

func _on_move_back_pressed():
	if not game_over:
		update_cameras(move("move_down"), Vector3(0, 0, 0))

func _on_move_right_pressed():
	if not game_over:
		update_cameras(move("move_right"), Vector3(0, 0, 0))

func _on_attacked(enemy_position, attack_strength):
	if $main_view/firstperson_viewport/firstperson_pos.get_translation().distance_to(enemy_position) < 3:
		player_health -= attack_strength
		if player_health < 0:
			player_health = 0
		if player_health <= 0:
			game_over = true
			$game_over_message.visible = true
			flamethrower_on = false

func _on_retry_button_pressed():
	get_tree().change_scene("res://main.tscn")

# Distance multiplier should be a positive integer
# This function returns the point <distance_multiplier> grid squares ahead of the player
func get_point_ahead_of_player(distance_multiplier):
	if player_facing == NORTH:
		return $main_view/firstperson_viewport/firstperson_pos.get_translation() +  Vector3(0,0,-2)*distance_multiplier
	elif player_facing == SOUTH:
		return $main_view/firstperson_viewport/firstperson_pos.get_translation() + Vector3(0,0,2)*distance_multiplier
	elif player_facing == EAST:
		return $main_view/firstperson_viewport/firstperson_pos.get_translation() + Vector3(2,0,0)*distance_multiplier
	else: # player_facing == WEST
		return $main_view/firstperson_viewport/firstperson_pos.get_translation() + Vector3(-2,0,0)*distance_multiplier

func _process(_delta):
	$player_stat_display/armor_stat.text = "Armor: {str}%".format({"str":player_health})
	$player_stat_display/fuel_stat.text = "Fuel: {str}ml".format({"str":fuel})
	pickup_gas_can()
	if fuel > 0 and flamethrower_on:
		if !$main_view/firstperson_viewport/firstperson_pos/flamesfx.is_playing():
			$main_view/firstperson_viewport/firstperson_pos/flamesfx.play()
		fuel -= 0.1
		emit_signal("flamethrower_on", [get_point_ahead_of_player(1), get_point_ahead_of_player(2)])
		if not flames_visible:
			$main_view/firstperson_viewport/firstperson_pos/flame.turn_on()
			flames_visible = true
	else:
		if $main_view/firstperson_viewport/firstperson_pos/flamesfx.is_playing():
			$main_view/firstperson_viewport/firstperson_pos/flamesfx.stop()
		if fuel <= 0:
			fuel = 0
		if flames_visible:
			flames_visible = false
			$main_view/firstperson_viewport/firstperson_pos/flame.turn_off()

func _on_get_fuel(ammount):
	fuel += ammount

func spawn_fuel_can(pos):
	var new_gas_can = gas_can.instance()
	new_gas_can.set_translation(pos)
	new_gas_can.connect("get_fuel", self, "_on_get_fuel")
	$fuel/fuel_cans.add_child(new_gas_can)

func _on_fuel_spawn_timer_timeout():
	# Get a list of all fuel spawn points
	var fuel_spawn_points = $fuel/fuel_spawn_points.get_children()
	# Pick a random element of the list
	fuel_spawn_points.shuffle()
	var selected_point = fuel_spawn_points[0]
	# If the spawn point is not empty, add a new fuel can here
	var occupied = false
	for existing_gas_can in $"fuel/fuel_cans".get_children():
		if selected_point.get_translation().distance_to(existing_gas_can.get_translation()) < 1:
			occupied = true
			break
	if not occupied:
		spawn_fuel_can(selected_point.get_translation())

func spawn_enemy(pos):
	# Set stuff for the enemies
	var new_enemy = enemy.instance()
	new_enemy.connect("attacked", self, "_on_attacked")
	self.connect("flamethrower_on", new_enemy, "_on_flamethrower")
	#new_enemy.set_home_position(Vector3(12,8,0))
	# Set position of the enemy
	new_enemy.set_translation(pos)
	# Add enemy to the scene
	$enemy/enemies.add_child(new_enemy)

func _on_enemy_spawn_timer_timeout():
	# Get a list of all enemy spawn points
	var enemy_spawn_points = $enemy/enemy_spawn_points.get_children()
	# Pick a random element of the list
	enemy_spawn_points.shuffle()
	var selected_point = enemy_spawn_points[0]
	# If the spawn point is not empty, enemy here
	var occupied = false
	for existing_enemy in $"enemy/enemies".get_children():
		if selected_point.get_translation().distance_to(existing_enemy.get_translation()) < 1:
			occupied = true
			break
	if not occupied:
		spawn_enemy(selected_point.get_translation())
