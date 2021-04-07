extends Control



func _on_begin_button_pressed():
	get_tree().change_scene("res://main.tscn")

func _process(_delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
