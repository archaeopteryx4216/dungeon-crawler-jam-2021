extends Control

func _on_yes_button_pressed():
	get_tree().change_scene("res://game_start.tscn")


func _on_no_button_pressed():
	get_tree().quit()
