extends Control

enum {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

# Global vars
export var player_health = 100
export var fuel = 0
export var flamethrower_range = 5

var game_over = false
var player_facing = NORTH
var firing_flamethrower = true

func _ready():
	$"enemies/enemy".connect("attacked", self, "_on_attacked")
	$"side_view/player_sprite".position = Vector2(128,128)
	$"enemies/enemy".set_home_position(Vector3(12,8,0))
	# Setup gascan signals
	$fuel_cans/gas_can1.connect("get_fuel", self, "_on_get_fuel")
	$fuel_cans/gas_can2.connect("get_fuel", self, "_on_get_fuel")

func pickup_gas_can():
	for gas_can in $"fuel_cans".get_children():
		if $main_view/firstperson_viewport/firstperson_pos.get_translation().distance_to(gas_can.get_translation()) < 1:
			gas_can.pickup()

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

func update_cameras(pos_change, turn_rads):
	# Check if we will intersect the enemy, if so, skip the movement
	var next_position = $"main_view/firstperson_viewport/firstperson_pos".get_translation() + pos_change
	if next_position.distance_to($enemies/enemy.get_translation()) > 1:
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
	$"enemies/enemy".set_player_position($"main_view/firstperson_viewport/firstperson_pos".get_translation())

func force_update_all_raycast():
	$main_view/firstperson_viewport/firstperson_pos/back_ray.force_raycast_update()
	$main_view/firstperson_viewport/firstperson_pos/front_ray.force_raycast_update()
	$main_view/firstperson_viewport/firstperson_pos/left_ray.force_raycast_update()
	$main_view/firstperson_viewport/firstperson_pos/right_ray.force_raycast_update()

func move(player_dir):
	force_update_all_raycast()
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

func _on_retry_button_pressed():
	get_tree().change_scene("res://main.tscn")
	
func _process(_delta):
	$player_stat_display/armor_stat.text = "Armor: {str}%".format({"str":player_health})
	$player_stat_display/fuel_stat.text = "Fuel: {str}ml".format({"str":fuel})
	pickup_gas_can()

func _on_get_fuel(ammount):
	fuel += ammount
